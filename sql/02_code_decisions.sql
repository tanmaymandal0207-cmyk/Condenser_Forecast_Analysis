-- 02. Client decisions on old challan codes
-- Old codes that did not match the master list were sent to the client to confirm.
-- Each decision is stored once, so the mapping is auditable and can be re-run.
--   Auto       same code as the master, different spelling
--   Accept     move to the suggested current code
--   New part   keep the old code as its own part
--   Ignore     leave out of the sales series
-- Sample rows shown; the full list (47 codes) is kept with the client data.

CREATE OR REPLACE TABLE `your_project.your_dataset.code_map_challan` AS
SELECT * FROM UNNEST([
  STRUCT('PC-86581AQ5' AS old_code, 'PC-86581-Q5'  AS master_code, 'Accept'    AS decision),
  STRUCT('PC-86270R12' AS old_code, 'PC-86270-R12' AS master_code, 'Accept'    AS decision),
  STRUCT('PC-86808Q5'  AS old_code, 'PC-86808-Q5'  AS master_code, 'Auto'      AS decision),
  STRUCT('PC-86036'    AS old_code, 'PC-86036'     AS master_code, 'New part'  AS decision),
  STRUCT('PC-86394'    AS old_code, CAST(NULL AS STRING) AS master_code, 'Ignore' AS decision)
  -- ... remaining rows
]);

-- Master codes not sold since 2019, plus old codes kept as their own parts
CREATE OR REPLACE TABLE `your_project.your_dataset.dim_part_condenser_extra` AS
SELECT * FROM UNNEST([
  STRUCT('PC-86581-Q5' AS part_code, 'BRIO-Q5'                   AS model, 'Q5'       AS grade, 'approved (client master)'    AS status),
  STRUCT('PC-86036'    AS part_code, 'INDICA 134A (old code)'    AS model, 'Standard' AS grade, 'approved (client, old code)' AS status)
  -- ... remaining rows
]);

-- Full part list
CREATE OR REPLACE VIEW `your_project.your_dataset.v_dim_part_condenser` AS
SELECT part_code, model, grade, status FROM `your_project.your_dataset.dim_part_condenser`
UNION ALL
SELECT part_code, model, grade, status FROM `your_project.your_dataset.dim_part_condenser_extra`;
