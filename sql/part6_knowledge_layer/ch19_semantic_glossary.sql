-- ============================================================
-- Chapter 19: Building the Semantic Layer
-- Business glossary schema
-- Data Architecture for AI — Miguel Brito
-- ============================================================

CREATE TABLE semantic_glossary (
  term_id           UUID         NOT NULL DEFAULT gen_random_uuid(),
  canonical_term    VARCHAR(100) NOT NULL UNIQUE,
  domain            VARCHAR(50)  NOT NULL,
  term_type         VARCHAR(30)  NOT NULL,
  -- Values: concept | metric | process | business_rule | role
  definition        TEXT         NOT NULL,
  business_context  TEXT         NULL,
  calculation       TEXT         NULL,   -- for metrics: the formula
  source_fields     TEXT[]       NULL,
  synonyms          TEXT[]       NULL,
  related_terms     TEXT[]       NULL,
  antonyms          TEXT[]       NULL,
  is_a              TEXT[]       NULL,   -- concept hierarchy
  has_parts         TEXT[]       NULL,
  excludes          TEXT[]       NULL,   -- explicitly excluded concepts
  steward_role      VARCHAR(100) NOT NULL,
  reviewed_at       TIMESTAMP    NOT NULL,
  review_due        DATE         NULL,
  status            VARCHAR(20)  NOT NULL DEFAULT 'active',
  -- Values: active | deprecated | under_review
  created_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
  PRIMARY KEY (term_id)
);

CREATE INDEX idx_glossary_term   ON semantic_glossary (canonical_term);
CREATE INDEX idx_glossary_domain ON semantic_glossary (domain, term_type);

-- ── Example entry: Monthly Recurring Revenue ─────────────────
INSERT INTO semantic_glossary (
  canonical_term, domain, term_type,
  definition, calculation, source_fields,
  synonyms, excludes, steward_role
) VALUES (
  'Monthly Recurring Revenue',
  'finance', 'metric',
  'The sum of all active subscription amounts billed on a monthly basis. '
  'Excludes one-time fees, professional services, and usage-based charges.',
  'SUM(subscriptions.monthly_amount) WHERE status=active AND type=recurring',
  ARRAY['subscriptions.monthly_amount', 'account_mrr_view.mrr'],
  ARRAY['MRR', 'monthly revenue', 'recurring revenue'],
  ARRAY['total revenue', 'gross revenue', 'ARR'],
  'finance_domain_steward'
);
