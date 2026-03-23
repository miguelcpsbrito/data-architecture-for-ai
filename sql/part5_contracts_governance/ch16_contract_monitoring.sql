-- ============================================================
-- Chapter 16: When Contracts Break
-- Schema validation, semantic drift, freshness monitoring
-- Data Architecture for AI — Miguel Brito
-- ============================================================

-- ── Schema validation (run before vector index refresh) ──────
SELECT
  'account_type'                                             AS column_name,
  COUNT(*) FILTER (WHERE account_type IS NULL)               AS null_count,
  COUNT(*) FILTER (
    WHERE account_type NOT IN ('Enterprise','Commercial','SMB')
      AND account_type IS NOT NULL
  )                                                          AS invalid_value_count,
  COUNT(*)                                                   AS total_rows,
  ROUND(100.0 * COUNT(*) FILTER (WHERE account_type IS NULL) / COUNT(*), 2)
                                                             AS null_rate_pct
FROM account_ai_surface WHERE valid_to IS NULL;

-- ── Semantic drift detection (run daily) ─────────────────────
WITH baseline AS (
  SELECT account_type,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_30d
  FROM account_ai_surface_history
  WHERE snapshot_date BETWEEN CURRENT_DATE - 30 AND CURRENT_DATE - 1
    AND valid_to IS NULL
  GROUP BY account_type
),
current_dist AS (
  SELECT account_type,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_today
  FROM account_ai_surface WHERE valid_to IS NULL
  GROUP BY account_type
)
SELECT
  COALESCE(b.account_type, c.account_type)               AS account_type,
  b.pct_30d, c.pct_today,
  ABS(COALESCE(c.pct_today,0) - COALESCE(b.pct_30d,0))  AS drift_pct,
  CASE
    WHEN ABS(COALESCE(c.pct_today,0) - COALESCE(b.pct_30d,0)) > 5 THEN 'ALERT: SIGNIFICANT_DRIFT'
    WHEN ABS(COALESCE(c.pct_today,0) - COALESCE(b.pct_30d,0)) > 2 THEN 'WARN: MODERATE_DRIFT'
    ELSE 'OK'
  END AS drift_status
FROM baseline b FULL OUTER JOIN current_dist c USING (account_type)
ORDER BY drift_pct DESC;

-- ── Freshness monitoring ─────────────────────────────────────
SELECT
  'account_ai_surface'                                       AS table_name,
  MAX(updated_at)                                            AS last_updated,
  EXTRACT(HOUR FROM NOW() - MAX(updated_at))                 AS hours_since_update,
  30                                                         AS freshness_sla_hours,
  CASE
    WHEN EXTRACT(HOUR FROM NOW() - MAX(updated_at)) > 30 THEN 'VIOLATION: EXCEEDS_SLA'
    WHEN EXTRACT(HOUR FROM NOW() - MAX(updated_at)) > 24 THEN 'WARNING: APPROACHING_SLA'
    ELSE 'OK'
  END                                                        AS freshness_status
FROM account_ai_surface WHERE valid_to IS NULL;
