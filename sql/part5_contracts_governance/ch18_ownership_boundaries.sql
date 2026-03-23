-- ============================================================
-- Chapter 18: Ownership Boundaries as Architecture
-- Boundary analysis + succession planning
-- Data Architecture for AI — Miguel Brito
-- ============================================================

-- ── Ownership boundary fingerprint analysis ──────────────────
-- Columns with the same fingerprint share an ownership domain.
-- Distinct fingerprints = distinct governance requirements.

SELECT
  co.table_name, co.column_name,
  co.producer_team, co.steward_role,
  cs.classification    AS sensitivity,
  cs.pii_category,
  co.review_frequency,
  MD5(CONCAT(
    co.producer_team, '|', co.steward_role, '|',
    cs.classification, '|', co.review_frequency
  ))                   AS ownership_domain_fingerprint
FROM column_ownership co
JOIN column_sensitivity cs
  ON cs.table_name  = co.table_name
  AND cs.column_name = co.column_name
WHERE co.table_name = 'account_ai_surface'
ORDER BY ownership_domain_fingerprint, co.column_name;
