-- ============================================================
-- Chapter 10: Uncertainty, Confidence, and Provenance
-- Provenance chain schema + confidence retrieval
-- Data Architecture for AI — Miguel Brito
-- ============================================================

CREATE TABLE fact_provenance (
  provenance_id     UUID         NOT NULL DEFAULT gen_random_uuid(),
  fact_id           UUID         NOT NULL,
  fact_table        VARCHAR(100) NOT NULL,
  source_type       VARCHAR(50)  NOT NULL,  -- source_system | transformation | inference
  source_system     VARCHAR(50)  NULL,
  source_record_id  VARCHAR(100) NULL,
  source_document   VARCHAR(500) NULL,
  source_field      VARCHAR(100) NULL,
  transform_name    VARCHAR(100) NULL,
  transform_version VARCHAR(20)  NULL,
  input_fact_ids    UUID[]       NULL,
  occurred_at       TIMESTAMP    NOT NULL,
  derivation_depth  SMALLINT     NOT NULL DEFAULT 0,
  executed_by       VARCHAR(100) NOT NULL,
  PRIMARY KEY (provenance_id)
);

CREATE TABLE fact_confidence_exceptions (
  fact_table        VARCHAR(100) NOT NULL,
  fact_id           UUID         NOT NULL,
  field_name        VARCHAR(100) NOT NULL,
  field_confidence  DECIMAL(3,2) NOT NULL,
  reason            TEXT         NULL,
  PRIMARY KEY (fact_table, fact_id, field_name)
);

-- ── Effective confidence per field at retrieval ──────────────
SELECT
  f.canonical_id, f.legal_name,
  COALESCE(ex_name.field_confidence, f.record_confidence) AS name_confidence,
  f.employee_count,
  COALESCE(ex_emp.field_confidence,  f.record_confidence) AS emp_confidence,
  f.annual_revenue_usd,
  COALESCE(ex_rev.field_confidence,  f.record_confidence) AS rev_confidence
FROM fact_customer_core f
LEFT JOIN fact_confidence_exceptions ex_name
  ON ex_name.fact_id = f.canonical_id AND ex_name.field_name = 'legal_name'
LEFT JOIN fact_confidence_exceptions ex_emp
  ON ex_emp.fact_id  = f.canonical_id AND ex_emp.field_name  = 'employee_count'
LEFT JOIN fact_confidence_exceptions ex_rev
  ON ex_rev.fact_id  = f.canonical_id AND ex_rev.field_name  = 'annual_revenue_usd'
WHERE f.canonical_id = %(entity_id)s AND f.valid_to IS NULL;
