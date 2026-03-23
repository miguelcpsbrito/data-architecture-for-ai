-- ============================================================
-- Chapter 3: The Technical Debt Nobody Sees
-- AI Readiness Audit Queries
-- Data Architecture for AI — Miguel Brito
-- ============================================================

-- ── Audit 1: Semantic transparency ──────────────────────────
-- Find columns with missing or thin catalog descriptions.
-- Run against your AWS Glue Data Catalog via Athena.

SELECT
  table_name,
  column_name,
  data_type,
  comment                                                  AS catalog_description,
  CASE
    WHEN comment IS NULL OR comment = ''  THEN 'MISSING'
    WHEN LENGTH(comment) < 20             THEN 'TOO_SHORT'
    ELSE                                       'OK'
  END                                                      AS description_quality
FROM information_schema.columns
WHERE table_schema = :'your_database'
ORDER BY description_quality, table_name, column_name;


-- ── Audit 2: Abbreviation detector ──────────────────────────
-- Find column names that are likely abbreviations (AI-opaque).

SELECT
  table_name,
  column_name,
  LENGTH(column_name)                                      AS name_length,
  CASE
    WHEN LENGTH(column_name) <= 4                          THEN 'LIKELY_ABBREVIATION'
    WHEN column_name NOT LIKE '%[_]%'
     AND LENGTH(column_name) <= 8                          THEN 'POSSIBLE_ABBREVIATION'
    ELSE                                                        'OK'
  END                                                      AS naming_risk
FROM information_schema.columns
WHERE table_schema = :'your_database'
ORDER BY naming_risk, table_name;


-- ── Audit 3: Temporal debt ───────────────────────────────────
-- Find tables with no valid_from / valid_to pattern.
-- These tables overwrite history and produce stale AI facts.

SELECT
  t.table_name,
  CASE
    WHEN SUM(CASE WHEN c.column_name IN (
           'valid_from','valid_to','valid_time_start','valid_time_end'
         ) THEN 1 ELSE 0 END) > 0 THEN 'HAS_TEMPORAL_METADATA'
    WHEN SUM(CASE WHEN c.column_name IN (
           'updated_at','modified_at','last_modified'
         ) THEN 1 ELSE 0 END) > 0 THEN 'OVERWRITE_PATTERN_ONLY'
    ELSE                               'NO_TEMPORAL_METADATA'
  END                                                      AS temporal_pattern,
  COUNT(c.column_name)                                     AS total_columns
FROM information_schema.tables  t
JOIN information_schema.columns c USING (table_schema, table_name)
WHERE t.table_schema = :'your_database'
  AND t.table_type   = 'BASE TABLE'
GROUP BY t.table_name
ORDER BY temporal_pattern, t.table_name;
