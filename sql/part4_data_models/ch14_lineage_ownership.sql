-- ============================================================
-- Chapter 14: Lineage, Ownership, and the Responsibility Model
-- Column lineage, ownership, AI manifest, impact assessment
-- Data Architecture for AI — Miguel Brito
-- ============================================================

CREATE TABLE column_lineage (
  target_table       VARCHAR(100) NOT NULL,
  target_column      VARCHAR(100) NOT NULL,
  source_table       VARCHAR(100) NOT NULL,
  source_column      VARCHAR(100) NOT NULL,
  source_system      VARCHAR(50)  NULL,
  transform_type     VARCHAR(50)  NOT NULL,
  -- Values: direct_copy|join_resolution|code_expansion|
  --   semantic_enrichment|aggregation|ml_inference
  transform_logic    TEXT         NULL,
  transform_pipeline VARCHAR(100) NOT NULL,
  pipeline_version   VARCHAR(20)  NOT NULL,
  expected_source_type VARCHAR(50) NULL,
  expected_null_rate   DECIMAL(5,4) NULL,
  expected_update_freq VARCHAR(50)  NULL,
  registered_by      VARCHAR(100) NOT NULL,
  registered_at      TIMESTAMP    NOT NULL,
  last_verified_at   TIMESTAMP    NULL,
  PRIMARY KEY (target_table, target_column, source_table, source_column)
);

CREATE TABLE column_ownership (
  table_name          VARCHAR(100) NOT NULL,
  column_name         VARCHAR(100) NOT NULL,
  steward_name        VARCHAR(100) NOT NULL,
  steward_email       VARCHAR(200) NOT NULL,
  steward_role        VARCHAR(100) NOT NULL,
  producer_team       VARCHAR(100) NOT NULL,
  producer_system     VARCHAR(100) NULL,
  producer_contact    VARCHAR(200) NULL,
  accuracy_sla        VARCHAR(100) NULL,
  freshness_sla       VARCHAR(100) NULL,
  review_frequency    VARCHAR(50)  NOT NULL,
  next_review_date    DATE         NULL,
  escalation_contact  VARCHAR(200) NOT NULL,
  escalation_sla_hours INTEGER     NOT NULL DEFAULT 48,
  successor_role      VARCHAR(100) NULL,
  successor_name      VARCHAR(100) NULL,
  successor_email     VARCHAR(200) NULL,
  succession_reviewed_at DATE      NULL,
  registered_at       TIMESTAMP    NOT NULL,
  last_confirmed_at   TIMESTAMP    NULL,
  PRIMARY KEY (table_name, column_name)
);

CREATE TABLE ai_system_data_manifest (
  manifest_id                    UUID         NOT NULL DEFAULT gen_random_uuid(),
  system_name                    VARCHAR(100) NOT NULL,
  system_version                 VARCHAR(20)  NOT NULL,
  environment                    VARCHAR(20)  NOT NULL,
  table_name                     VARCHAR(100) NOT NULL,
  columns_accessed               TEXT[]       NOT NULL,
  permission_tier                VARCHAR(20)  NOT NULL,
  access_pattern                 VARCHAR(50)  NOT NULL,
  max_acceptable_staleness_hours INTEGER      NULL,
  min_confidence_threshold       DECIMAL(3,2) NULL,
  system_owner_team              VARCHAR(100) NOT NULL,
  registered_by                  VARCHAR(100) NOT NULL,
  registered_at                  TIMESTAMP    NOT NULL,
  approved_by                    VARCHAR(100) NULL,
  approved_at                    TIMESTAMP    NULL,
  PRIMARY KEY (manifest_id)
);

-- ── Impact assessment before a schema change ─────────────────
SELECT DISTINCT system_name, system_version, system_owner_team, escalation_contact
FROM ai_system_data_manifest m
JOIN column_ownership co ON co.table_name = m.table_name
WHERE m.table_name = 'account_ai_surface'
  AND 'credit_limit_usd' = ANY(m.columns_accessed)
  AND m.environment = 'prod'
ORDER BY system_name;

-- ── Succession health check ───────────────────────────────────
SELECT
  co.table_name, co.column_name, co.steward_role, co.steward_name,
  co.successor_role,
  CASE
    WHEN co.successor_role IS NULL                                    THEN 'NO_SUCCESSION_PLAN'
    WHEN co.succession_reviewed_at < CURRENT_DATE - INTERVAL '6 months' THEN 'SUCCESSION_PLAN_STALE'
    ELSE 'OK'
  END AS succession_status
FROM column_ownership co
WHERE co.table_name IN (
  SELECT DISTINCT table_name FROM ai_system_data_manifest WHERE environment = 'prod'
)
ORDER BY succession_status DESC, co.table_name;
