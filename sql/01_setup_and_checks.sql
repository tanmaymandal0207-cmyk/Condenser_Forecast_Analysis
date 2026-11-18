-- 01. Post-load checks and challan condenser view
-- Load first (BigQuery console > dataset > Create table > Upload, CSV, header row skipped):
--   fact_sales_monthly_2019_2026.csv -> fact_sales_monthly_raw   (expected 38,114 rows)
--   part_alias.csv                   -> part_alias
--   dim_part_condenser_draft.csv     -> dim_part_condenser
--   dim_period.csv                   -> dim_period

-- 1a. Loaded total per file must equal the "Totals" row of that Excel file
SELECT source_file, ROUND(SUM(qty), 2) AS loaded_total, COUNT(*) AS rows_loaded
FROM `your_project.your_dataset.fact_sales_monthly_raw`
GROUP BY 1 ORDER BY 1;

-- 1b. Every condenser row has a part code that exists in the part list
SELECT COUNTIF(f.part_code IS NULL) AS no_code,
       COUNTIF(p.part_code IS NULL) AS not_in_dim_part
FROM `your_project.your_dataset.fact_sales_monthly_raw` f
LEFT JOIN `your_project.your_dataset.dim_part_condenser` p USING (part_code)
WHERE f.is_condenser;

-- 1c. Condenser lines from the challan register, up to the cut-over month
--     (Apr 2019 onwards comes from the Excel files)
CREATE OR REPLACE VIEW `your_project.your_dataset.v_challan_condenser_monthly` AS
SELECT DATE_TRUNC(Date, MONTH)                                  AS month_start,
       UPPER(REGEXP_REPLACE(TRIM(Part_Number), r'\s+', ''))     AS part_code_raw,
       SUM(Quantity)                                            AS qty
FROM `your_project.your_dataset.challan_master`
WHERE Status = 'Active'
  AND Line_Type = 'Item'
  AND UoM = 'PCS'
  AND Date < '2019-04-01'
  AND REGEXP_CONTAINS(UPPER(IFNULL(Part_Number, '')), r'^PCP?-?C?86\d{3}')  -- anonymised prefix
GROUP BY 1, 2;
