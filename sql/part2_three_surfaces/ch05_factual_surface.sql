-- ============================================================
-- Chapter 5: The Factual Surface
-- Schema + confidence decay query
-- Data Architecture for AI — Miguel Brito
-- ============================================================

CREATE TABLE fact_customer_core (
  canonical_id            UUID          NOT NULL,
  source_system           VARCHAR(20)   NOT NULL,
  source_record_id        VARCHAR(50)   NOT NULL,
  legal_name              VARCHAR(200)  NOT NULL,
  registration_no         VARCHAR(50)   NULL,
  incorporation_country   CHAR(2)       NOT NULL,
  employee_count          INTEGER       NULL,
  annual_revenue_usd      DECIMAL(15,2) NULL,
  valid_from              TIMESTAMP     NOT NULL,
  valid_to                TIMESTAMP     NULL,
  as_of_date              DATE          NULL,
  asserted_by             VARCHAR(50)   NOT NULL,
  asserted_at             TIMESTAMP     NOT NULL,
  confidence              DECIMAL(3,2)  NULL,
  record_confidence       DECIMAL(3,2)  NULL,
  rate_of_change_class    VARCHAR(10)   NOT NULL DEFAULT 'slow',
  -- Values: fast | medium | slow | stable
  created_at              TIMESTAMP     NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMP     NOT NULL DEFAULT NOW(),
  PRIMARY KEY (canonical_id, valid_from)
);

-- ── Effective confidence at retrieval time ───────────────────
-- Combines source quality with recency decay by rate_of_change_class.
-- effective_confidence >= 0.80 → assertive presentation
-- effective_confidence 0.50-0.79 → hedged with source attribution
-- effective_confidence < 0.50  → explicit uncertainty flagging

SELECT
  f.canonical_id,
  f.legal_name,
  f.employee_count,
  f.asserted_at,
  f.confidence                                             AS base_confidence,
  ROUND(
    f.confidence *
    CASE f.rate_of_change_class
      WHEN 'fast'   THEN GREATEST(0.1, 1.0 - (EXTRACT(DAY FROM NOW() - f.asserted_at) / 30.0))
      WHEN 'medium' THEN GREATEST(0.3, 1.0 - (EXTRACT(DAY FROM NOW() - f.asserted_at) / 365.0))
      WHEN 'slow'   THEN GREATEST(0.6, 1.0 - (EXTRACT(DAY FROM NOW() - f.asserted_at) / 1825.0))
      ELSE 0.95
    END
  , 2)                                                     AS effective_confidence
FROM fact_customer_core f
WHERE f.canonical_id = %(entity_id)s
  AND f.valid_to IS NULL;
