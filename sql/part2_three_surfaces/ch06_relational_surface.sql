-- ============================================================
-- Chapter 6: The Relational Surface
-- Relationship schema + orphan detection
-- Data Architecture for AI — Miguel Brito
-- ============================================================

CREATE TABLE entity_relationships (
  relationship_id   UUID         NOT NULL DEFAULT gen_random_uuid(),
  subject_id        UUID         NOT NULL,
  subject_type      VARCHAR(50)  NOT NULL,
  predicate         VARCHAR(100) NOT NULL,
  -- Common predicates: owned_by | managed_by | uses_product |
  --   covered_by | depends_on | supersedes | causes | classifies
  object_id         UUID         NOT NULL,
  object_type       VARCHAR(50)  NOT NULL,
  is_bidirectional  BOOLEAN      NOT NULL DEFAULT FALSE,
  valid_from        TIMESTAMP    NOT NULL,
  valid_to          TIMESTAMP    NULL,
  confidence        DECIMAL(3,2) NULL,
  source_system     VARCHAR(20)  NOT NULL,
  source_record_id  VARCHAR(50)  NULL,
  asserted_by       VARCHAR(100) NOT NULL,
  asserted_at       TIMESTAMP    NOT NULL,
  weight            DECIMAL(5,2) NULL,
  created_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
  PRIMARY KEY (relationship_id)
);

CREATE INDEX idx_rel_subject   ON entity_relationships (subject_id, predicate, valid_to);
CREATE INDEX idx_rel_object    ON entity_relationships (object_id,  predicate, valid_to);
CREATE INDEX idx_rel_predicate ON entity_relationships (predicate, valid_from, valid_to);

-- ── Orphan detection ─────────────────────────────────────────
-- Run daily; relationships pointing to inactive entities.

SELECT COUNT(*) AS orphan_count, er.predicate, 'subject' AS orphan_side
FROM entity_relationships er
LEFT JOIN fact_customer_core fc
  ON fc.canonical_id = er.subject_id AND fc.valid_to IS NULL
WHERE er.valid_to IS NULL AND fc.canonical_id IS NULL
GROUP BY er.predicate
UNION ALL
SELECT COUNT(*), er.predicate, 'object'
FROM entity_relationships er
LEFT JOIN fact_customer_core fc
  ON fc.canonical_id = er.object_id AND fc.valid_to IS NULL
WHERE er.valid_to IS NULL AND fc.canonical_id IS NULL
GROUP BY er.predicate
ORDER BY orphan_count DESC;
