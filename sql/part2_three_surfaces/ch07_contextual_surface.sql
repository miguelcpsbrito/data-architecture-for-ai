-- ============================================================
-- Chapter 7: The Contextual Surface
-- Schema + overdue review query
-- Data Architecture for AI — Miguel Brito
-- ============================================================

CREATE TABLE entity_context (
  context_id        UUID         NOT NULL DEFAULT gen_random_uuid(),
  entity_id         UUID         NOT NULL,
  entity_type       VARCHAR(50)  NOT NULL,
  context_type      VARCHAR(100) NOT NULL,
  -- Common types: sensitivity | strategic_tier | renewal_risk |
  --   regulatory_flag | access_restriction | industry_classification
  context_value     VARCHAR(500) NOT NULL,
  context_rationale TEXT         NULL,
  audience_scope    VARCHAR(100) NULL,
  assessed_by       VARCHAR(100) NOT NULL,
  assessed_at       TIMESTAMP    NOT NULL,
  assessment_method VARCHAR(50)  NOT NULL,  -- human | ml_model | rule_engine
  criteria_version  VARCHAR(20)  NULL,
  valid_from        TIMESTAMP    NOT NULL,
  valid_to          TIMESTAMP    NULL,
  review_due        DATE         NULL,
  confidence        DECIMAL(3,2) NULL,
  superseded_by     UUID         NULL,
  created_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
  PRIMARY KEY (context_id)
);

CREATE INDEX idx_ctx_entity ON entity_context (entity_id, context_type, valid_to);
CREATE INDEX idx_ctx_review ON entity_context (review_due, context_type);

-- ── Overdue context reviews ──────────────────────────────────
-- Daily steward work queue: contextual records past review_due.

SELECT
  ec.entity_id, ec.entity_type, ec.context_type, ec.context_value,
  ec.assessed_by, ec.assessed_at, ec.review_due,
  CURRENT_DATE - ec.review_due   AS days_overdue,
  co.steward_email
FROM entity_context ec
LEFT JOIN column_ownership co
  ON co.table_name  = 'entity_context'
  AND co.column_name = ec.context_type
WHERE ec.valid_to   IS NULL
  AND ec.review_due IS NOT NULL
  AND ec.review_due <  CURRENT_DATE
ORDER BY days_overdue DESC, ec.context_type;
