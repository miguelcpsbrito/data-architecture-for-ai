-- ============================================================
-- Chapter 24: Migration Patterns
-- Schema divergence detection + completeness gate
-- Data Architecture for AI — Miguel Brito
-- ============================================================

-- ── Schema divergence detection ──────────────────────────────
-- Run before any legacy schema change.
-- Prerequisites: expected_source_type must be populated in column_lineage.
--   ALTER TABLE column_lineage ADD COLUMN expected_source_type VARCHAR(50) NULL;

SELECT
  cl.source_table, cl.source_column,
  CASE
    WHEN ic.column_name IS NULL
      THEN 'MISSING: column no longer exists in legacy schema'
    WHEN ic.data_type != cl.expected_source_type
      THEN 'TYPE_MISMATCH: expected ' || cl.expected_source_type ||
           ', found ' || ic.data_type
    ELSE 'OK'
  END                   AS divergence_status,
  cl.target_table, cl.target_column, cl.transform_pipeline
FROM column_lineage cl
LEFT JOIN information_schema.columns ic
  ON ic.table_schema = 'operational_db'
  AND ic.table_name  = cl.source_table
  AND ic.column_name = cl.source_column
WHERE cl.target_table IN (
  SELECT DISTINCT table_name FROM ai_system_data_manifest WHERE environment = 'prod'
)
  AND (ic.column_name IS NULL OR ic.data_type != cl.expected_source_type)
ORDER BY divergence_status, cl.source_table;


-- ── Migration completeness gate ───────────────────────────────
-- Exit criteria: coverage_pct >= 99.5%
-- PASS ≥ 99.5% | WARN 95.0–99.4% | FAIL < 95.0%

SELECT
  'account_ai_surface'                                       AS surface_table,
  legacy.total_legacy                                        AS legacy_entity_count,
  surface.total_surface                                      AS surface_entity_count,
  ROUND(100.0 * surface.total_surface / legacy.total_legacy, 2) AS coverage_pct,
  legacy.total_legacy - surface.total_surface                AS missing_entity_count,
  CASE
    WHEN ROUND(100.0 * surface.total_surface / legacy.total_legacy, 2) >= 99.5
      THEN 'PASS'
    WHEN ROUND(100.0 * surface.total_surface / legacy.total_legacy, 2) >= 95.0
      THEN 'WARN: investigate missing entities before go-live'
    ELSE 'FAIL: migration incomplete; do not go live'
  END AS completeness_gate
FROM (SELECT COUNT(*) AS total_legacy FROM operational_db.accounts WHERE status != 'deleted') legacy,
     (SELECT COUNT(*) AS total_surface FROM account_ai_surface WHERE valid_to IS NULL) surface;
