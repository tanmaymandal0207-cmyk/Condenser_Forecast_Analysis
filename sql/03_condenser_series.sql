-- 03. One condenser series, Apr 2009 to the latest month
-- Challan register up to Mar 2019, Excel files from Apr 2019 (one source per month).

CREATE OR REPLACE VIEW `your_project.your_dataset.v_condenser_sales_monthly` AS
WITH dp AS (       -- one row per normalised code, so a join can never duplicate pieces
  SELECT REGEXP_REPLACE(UPPER(part_code), r'[^A-Z0-9]', '') AS k, MIN(part_code) AS part_code
  FROM `your_project.your_dataset.v_dim_part_condenser`
  GROUP BY 1
),
cmap AS (          -- exact spelling: the client decided per spelling, and some
                   -- spellings that look alike after normalising got different decisions
  SELECT UPPER(REGEXP_REPLACE(old_code, r'\s+', '')) AS k, master_code, decision
  FROM `your_project.your_dataset.code_map_challan`
),
c AS (
  SELECT v.month_start,
         COALESCE(m.master_code, dp.part_code, v.part_code_raw) AS part_code,
         v.qty,
         'challan_master' AS source
  FROM `your_project.your_dataset.v_challan_condenser_monthly` v
  LEFT JOIN cmap m ON m.k = v.part_code_raw
  LEFT JOIN dp     ON dp.k = REGEXP_REPLACE(v.part_code_raw, r'[^A-Z0-9]', '')
  WHERE IFNULL(m.decision, '') <> 'Ignore'
),
x AS (
  SELECT DATE(month_start) AS month_start, part_code, qty, CONCAT('excel_', source_file) AS source
  FROM `your_project.your_dataset.fact_sales_monthly_raw`
  WHERE is_condenser AND DATE(month_start) >= '2019-04-01'
)
SELECT u.month_start, d.fy_label, d.fy_quarter, u.part_code, p.model, p.grade,
       p.status AS master_status,
       SUM(u.qty) AS qty,
       STRING_AGG(DISTINCT u.source) AS source
FROM (SELECT * FROM c UNION ALL SELECT * FROM x) u
LEFT JOIN `your_project.your_dataset.dim_period` d           ON DATE(d.month_start) = u.month_start
LEFT JOIN `your_project.your_dataset.v_dim_part_condenser` p ON p.part_code = u.part_code
GROUP BY 1, 2, 3, 4, 5, 6, 7;

-- Quarterly view: input to the forecast (FY quarters, Q1 = Apr-Jun)
CREATE OR REPLACE VIEW `your_project.your_dataset.v_condenser_sales_quarterly` AS
SELECT fy_label, fy_quarter, part_code,
       ANY_VALUE(model) AS model, ANY_VALUE(grade) AS grade,
       SUM(qty) AS qty, MIN(month_start) AS quarter_start
FROM `your_project.your_dataset.v_condenser_sales_monthly`
GROUP BY 1, 2, 3;
