-- ============================================================
-- Chapter 23: Observability for the Data Layer
-- Freshness monitoring + lineage trace
-- Data Architecture for AI — Miguel Brito
-- ============================================================

-- ── Pipeline-level freshness monitoring ──────────────────────
-- Publish pct_beyond_sla to CloudWatch custom metrics.
-- Alert: pct_beyond_sla > 5%  → P2 Warning
--        pct_beyond_sla > 20% → P1 Violation (triggers circuit breaker)

SELECT
  'account_ai_surface'                                          AS surface_table,
  COUNT(*)                                                      AS total_entities,
  AVG(EXTRACT(MINUTE FROM NOW() - s.updated_at))                AS mean_lag_minutes,
  MAX(EXTRACT(MINUTE FROM NOW() - s.updated_at))                AS max_lag_minutes,
  30 * 60                                                       AS sla_minutes,
  COUNT(*) FILTER (WHERE EXTRACT(MINUTE FROM NOW() - s.updated_at) > 30 * 60)
                                                                AS entities_beyond_sla,
  ROUND(100.0 * COUNT(*) FILTER (
    WHERE EXTRACT(MINUTE FROM NOW() - s.updated_at) > 30 * 60
  ) / NULLIF(COUNT(*),0), 2)                                   AS pct_beyond_sla
FROM account_ai_surface s WHERE s.valid_to IS NULL;


-- ── Recursive lineage trace ───────────────────────────────────
-- When a quality alert fires: trace from the alerted column to origin.
-- Interpretation:
--   depth=1: check this pipeline first
--   source_system IS NOT NULL at any depth: root operational source
--   pipeline_version mismatch: undocumented change → contact producer

WITH RECURSIVE lineage_trace AS (
  SELECT
    cl.target_table, cl.target_column,
    cl.source_table, cl.source_column,
    cl.transform_type, cl.transform_pipeline,
    cl.pipeline_version AS documented_version,
    cl.source_system,
    1 AS depth
  FROM column_lineage cl
  WHERE cl.target_table  = %(alerted_table)s
    AND cl.target_column = %(alerted_column)s

  UNION ALL

  SELECT
    cl.target_table, cl.target_column,
    cl.source_table, cl.source_column,
    cl.transform_type, cl.transform_pipeline,
    cl.pipeline_version, cl.source_system,
    lt.depth + 1
  FROM column_lineage cl
  JOIN lineage_trace lt
    ON lt.source_table  = cl.target_table
   AND lt.source_column = cl.target_column
  WHERE lt.depth < 10
)
SELECT
  depth,
  source_table || '.' || source_column AS source_field,
  transform_type, transform_pipeline,
  documented_version, source_system,
  CASE WHEN source_system IS NOT NULL THEN 'OPERATIONAL SOURCE'
       ELSE 'PIPELINE TRANSFORMATION' END AS node_type
FROM lineage_trace
ORDER BY depth;
