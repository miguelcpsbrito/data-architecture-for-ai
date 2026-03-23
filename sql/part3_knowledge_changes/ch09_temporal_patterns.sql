-- ============================================================
-- Chapter 9: Modelling Change, Not Snapshots
-- SCD Type 2, event store, bi-temporal schema and queries
-- Data Architecture for AI — Miguel Brito
-- ============================================================

-- ── SCD Type 2 update (close + create, never UPDATE) ────────
UPDATE fact_customer_core
   SET valid_to = %(change_timestamp)s, updated_at = NOW()
 WHERE canonical_id = %(entity_id)s AND valid_to IS NULL;

INSERT INTO fact_customer_core (
  canonical_id, source_system, source_record_id,
  legal_name, registration_no, incorporation_country,
  employee_count, annual_revenue_usd,
  valid_from, valid_to, asserted_by, asserted_at,
  confidence, rate_of_change_class
) VALUES (
  %(entity_id)s, %(source_system)s, %(source_record_id)s,
  %(new_legal_name)s, %(registration_no)s, %(country)s,
  %(employee_count)s, %(annual_revenue)s,
  %(change_timestamp)s, NULL,
  %(asserting_system)s, NOW(), %(confidence)s, 'slow'
);

-- ── Point-in-time query ──────────────────────────────────────
SELECT * FROM fact_customer_core
 WHERE canonical_id = %(entity_id)s
   AND valid_from  <= %(query_date)s
   AND (valid_to   IS NULL OR valid_to > %(query_date)s);

-- ── Event store schema ───────────────────────────────────────
CREATE TABLE entity_events (
  event_id        UUID         NOT NULL DEFAULT gen_random_uuid(),
  stream_id       UUID         NOT NULL,
  entity_type     VARCHAR(50)  NOT NULL,
  sequence_no     BIGINT       NOT NULL,
  event_type      VARCHAR(100) NOT NULL,
  event_data      JSONB        NOT NULL,
  occurred_at     TIMESTAMP    NOT NULL,
  recorded_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
  initiated_by    VARCHAR(100) NOT NULL,
  causation_id    UUID         NULL,
  correlation_id  UUID         NULL,
  PRIMARY KEY (event_id),
  UNIQUE (stream_id, sequence_no)
);

-- ── Bi-temporal schema ───────────────────────────────────────
CREATE TABLE fact_contract_bitemporal (
  canonical_id        UUID          NOT NULL,
  version_id          UUID          NOT NULL DEFAULT gen_random_uuid(),
  annual_value_usd    DECIMAL(15,2) NOT NULL,
  payment_terms       VARCHAR(20)   NOT NULL,
  sla_tier            VARCHAR(10)   NOT NULL,
  valid_from          TIMESTAMP     NOT NULL,  -- real-world validity
  valid_to            TIMESTAMP     NULL,
  recorded_from       TIMESTAMP     NOT NULL DEFAULT NOW(), -- system belief
  recorded_to         TIMESTAMP     NULL,
  asserted_by         VARCHAR(100)  NOT NULL,
  correction_reason   TEXT          NULL,
  PRIMARY KEY (version_id)
);

-- ── Bi-temporal queries ──────────────────────────────────────
-- 1. Current value
SELECT * FROM fact_contract_bitemporal
 WHERE canonical_id = %(id)s AND valid_to IS NULL AND recorded_to IS NULL;

-- 2. Historical point-in-time
SELECT * FROM fact_contract_bitemporal
 WHERE canonical_id  = %(id)s
   AND valid_from   <= %(query_date)s
   AND (valid_to    IS NULL OR valid_to > %(query_date)s)
   AND recorded_to  IS NULL;

-- 3. Audit: what did the system believe on a past date?
SELECT * FROM fact_contract_bitemporal
 WHERE canonical_id   = %(id)s
   AND valid_from    <= '2024-03-15'
   AND (valid_to     IS NULL OR valid_to > '2024-03-15')
   AND recorded_from <= '2024-04-01'
   AND (recorded_to  IS NULL OR recorded_to > '2024-04-01');
