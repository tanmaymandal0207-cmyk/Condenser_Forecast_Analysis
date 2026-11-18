"""Load the yearly sales Excel files into a monthly long table for BigQuery.

Each file has one row per item (Name, Details, Unit, Jan..Dec, Total) and a
"Totals" row at the bottom. The script:
  1. reads every file and checks it against its own Totals row,
  2. finds condenser codes in Details (or Name) and matches them to the master list,
  3. unpivots to one row per item per month, with financial year and FY quarter,
  4. writes the CSVs loaded by sql/01_setup_and_checks.sql.

Usage:
  python excel_to_long.py --input data/yearly --master data/master.tsv --out out/
  (input files are named like "<anything>2019.xlsx"; master is "model<TAB>code")

Client files are never stored in this repository (see .gitignore).
"""
import argparse, glob, os, re
import numpy as np
import pandas as pd

MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
# Condenser series pattern. The real brand prefix is anonymised to PC- in this repo;
# override with the CODE_PATTERN environment variable when running on client data.
CODE = os.environ.get('CODE_PATTERN', r'PCP?\s*-?\s*C?\s*86\d{3}')


def norm(s):
    """Upper case, letters and digits only: 'PC-86539 Q5' -> 'PC86539Q5'."""
    return re.sub(r'[^A-Z0-9]', '', str(s).upper())


def read_file(path):
    year = int(re.search(r'(20\d\d)\.xlsx$', path).group(1))
    raw = pd.read_excel(path, header=None)
    hdr = raw.index[raw[0].astype(str).str.strip().eq('Name')][0]
    tot = raw.index[raw[2].astype(str).str.strip().eq('Totals')][0]
    body = raw.iloc[hdr + 1:tot].copy()
    body.columns = ['name', 'details', 'unit'] + MONTHS + ['total']
    body = body[body['name'].notna() | body['details'].notna()]
    for c in MONTHS + ['total']:
        body[c] = pd.to_numeric(body[c], errors='coerce').fillna(0)
    for c in ('name', 'details'):
        body[c] = body[c].astype(str).str.strip()
    totals_row = pd.to_numeric(raw.iloc[tot, 3:16], errors='coerce').values
    check = dict(
        file=os.path.basename(path), year=year, items=len(body),
        row_total_mismatches=int(((body[MONTHS].sum(axis=1) - body['total']).abs() >= 0.01).sum()),
        file_total=totals_row[-1], loaded_total=round(body['total'].sum(), 2),
        months_match=all(abs(body[m].sum() - totals_row[i]) < 0.05 for i, m in enumerate(MONTHS)),
        negative_cells=int((body[MONTHS] < 0).sum().sum()),
        duplicate_items=int(body.duplicated(['name', 'details']).sum()),
    )
    body['year'], body['source_file'] = year, os.path.basename(path)
    return body, check


def load_master(path):
    m = pd.read_csv(path, sep='\t', header=None, names=['model', 'code'], dtype=str).dropna()
    m['code'] = m['code'].str.strip()
    m = m[~m['code'].str.upper().str.contains('COMING SOON')]
    keys = {}
    for code in m['code']:
        keys[norm(re.sub(r'\(.*?\)', '', code))] = code       # 'PC-86457 (86843)' -> PC86457
        for inner in re.findall(r'\((\d{5})\)', code):          # and the code in brackets
            keys[norm(code.split('-')[0] + '-' + inner)] = code
    return keys, dict(zip(m['code'], m['model']))


def classify(details, name, keys, models):
    src = details if re.search(CODE, details.upper()) else name if re.search(CODE, name.upper()) else None
    if src is None:
        return dict(part_code=None, master_code=None, model=None, grade=None,
                    is_condenser=False, map_status='not_condenser_series')
    parts = [p.strip() for p in re.split(r'//|/', re.sub(r'\(.*?\)', '', src)) if p.strip()]
    whole = norm(re.sub(r'\(.*?\)', '', src))
    hits = list(dict.fromkeys(keys[norm(p)] for p in parts if norm(p) in keys))
    if whole in keys:
        master, status = keys[whole], 'master_exact'
    elif len(hits) == 1:
        master, status = hits[0], 'master_via_combined_code'
    elif hits:
        master, status = hits[0], 'master_ambiguous'
    else:
        master, status = None, 'not_in_master'
    return dict(part_code=(master or re.sub(r'\s+', '', parts[0].upper())), master_code=master,
                model=models.get(master, name), grade='Q5' if 'Q5' in norm(src) else 'Standard',
                is_condenser=True, map_status=status)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--input', required=True)
    ap.add_argument('--master', required=True)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    loaded = [read_file(p) for p in sorted(glob.glob(os.path.join(a.input, '*.xlsx')))]
    wide = pd.concat([b for b, _ in loaded], ignore_index=True)
    checks = pd.DataFrame([c for _, c in loaded])
    print(checks.to_string(index=False))
    if (checks.row_total_mismatches.sum() or not checks.months_match.all()
            or (checks.file_total - checks.loaded_total).abs().max() > 0.05):
        raise SystemExit('A file does not reconcile to its Totals row; fix before loading.')

    keys, models = load_master(a.master)
    alias = wide[['details', 'name']].drop_duplicates().reset_index(drop=True)
    alias = pd.concat([alias, alias.apply(lambda r: pd.Series(classify(r.details, r['name'], keys, models)), axis=1)], axis=1)
    wide = wide.merge(alias, on=['details', 'name'], how='left')

    ids = ['year', 'source_file', 'name', 'details', 'unit', 'part_code', 'master_code',
           'model', 'grade', 'is_condenser', 'map_status']
    long = wide.melt(id_vars=ids, value_vars=MONTHS, var_name='mon', value_name='qty')
    long = long[long.qty != 0].copy()
    month_no = long.mon.map({m: i + 1 for i, m in enumerate(MONTHS)})
    long['month_start'] = pd.to_datetime(dict(year=long.year, month=month_no, day=1))
    fy = np.where(month_no >= 4, long.year, long.year - 1)
    long['fy_label'] = [f'FY{y % 100:02d}-{(y + 1) % 100:02d}' for y in fy]
    long['fy_quarter'] = ((month_no - 4) % 12) // 3 + 1          # Q1 = Apr-Jun
    long['is_return'] = long.qty < 0

    fact = long[['month_start', 'fy_label', 'fy_quarter', 'part_code', 'master_code', 'details', 'name',
                 'unit', 'qty', 'is_return', 'is_condenser', 'map_status', 'source_file']]
    fact = fact.rename(columns={'details': 'raw_item_details', 'name': 'raw_item_name'})
    fact.to_csv(os.path.join(a.out, 'fact_sales_monthly_2019_2026.csv'), index=False)
    alias.rename(columns={'details': 'raw_item_details', 'name': 'raw_item_name'}).to_csv(
        os.path.join(a.out, 'part_alias.csv'), index=False)

    cond = fact[fact.is_condenser]
    parts = (alias[alias.is_condenser].groupby('part_code')
             .agg(model=('model', 'first'), grade=('grade', 'first'),
                  in_master=('master_code', lambda x: x.notna().any()), raw_variants=('details', 'nunique'))
             .join(cond.groupby('part_code').agg(pcs_2019_2026=('qty', 'sum'),
                   first_month=('month_start', 'min'), last_month=('month_start', 'max')))
             .reset_index().sort_values('pcs_2019_2026', ascending=False))
    parts['status'] = np.where(parts.in_master, 'approved (client master)', 'NEW - needs client confirmation')
    parts.to_csv(os.path.join(a.out, 'dim_part_condenser_draft.csv'), index=False)

    period = pd.DataFrame({'month_start': pd.date_range('2009-04-01', '2027-03-01', freq='MS')})
    fy = np.where(period.month_start.dt.month >= 4, period.month_start.dt.year, period.month_start.dt.year - 1)
    period['fy_label'] = [f'FY{y % 100:02d}-{(y + 1) % 100:02d}' for y in fy]
    period['fy_quarter'] = ((period.month_start.dt.month - 4) % 12) // 3 + 1
    period.to_csv(os.path.join(a.out, 'dim_period.csv'), index=False)

    print(f'rows {len(fact):,} | condenser rows {len(cond):,} | condenser pcs {cond.qty.sum():,.0f}')
    print(f'condenser codes {len(parts)} | in master {int(parts.in_master.sum())} | new {int((~parts.in_master).sum())}')


if __name__ == '__main__':
    main()
