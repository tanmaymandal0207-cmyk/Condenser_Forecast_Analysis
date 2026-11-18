-- 04. One-row validation summary after every rebuild
-- Results on 18 Nov 2026: unmapped_rows=0, nofy=0, dup_parts=0,
-- challan_raw=171,210.5, ignored=2,742, challan_in_view=168,468.5, excel=169,628, total=338,096.5

WITH m   AS (SELECT * FROM `your_project.your_dataset.v_condenser_sales_monthly`),
raw AS (SELECT SUM(qty) AS q FROM `your_project.your_dataset.v_challan_condenser_monthly`),
ign AS (
  SELECT SUM(v.qty) AS q
  FROM `your_project.your_dataset.v_challan_condenser_monthly` v
  JOIN `your_project.your_dataset.code_map_challan` c
    ON UPPER(REGEXP_REPLACE(c.old_code, r'\s+', '')) = v.part_code_raw
  WHERE c.decision = 'Ignore'
),
dup AS (
  SELECT COUNT(*) AS n
  FROM (SELECT part_code FROM `your_project.your_dataset.v_dim_part_condenser` GROUP BY 1 HAVING COUNT(*) > 1)
)
SELECT
  COUNTIF(master_status IS NULL)                         AS unmapped_rows,    -- expect 0
  COUNTIF(fy_label IS NULL)                              AS nofy,             -- expect 0
  (SELECT n FROM dup)                                    AS dup_parts,        -- expect 0
  (SELECT q FROM raw)                                    AS challan_raw,
  (SELECT q FROM ign)                                    AS ignored,
  SUM(IF(source = 'challan_master', qty, 0))             AS challan_in_view,  -- = challan_raw - ignored
  SUM(IF(source LIKE 'excel%', qty, 0))                  AS excel,
  SUM(qty)                                               AS total
FROM m;

-- Pieces by financial year
SELECT fy_label, SUM(qty) AS pcs
FROM `your_project.your_dataset.v_condenser_sales_monthly`
GROUP BY 1 ORDER BY 1;
