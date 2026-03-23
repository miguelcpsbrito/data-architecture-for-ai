-- ============================================================
-- Chapter 13: Sensitivity, Classification, and Access
-- Sensitivity registry + RLS policy
-- Data Architecture for AI — Miguel Brito
-- ============================================================

CREATE TABLE column_sensitivity (
  table_name      VARCHAR(100) NOT NULL,
  column_name     VARCHAR(100) NOT NULL,
  classification  VARCHAR(20)  NOT NULL,  -- PUBLIC|INTERNAL|CONFIDENTIAL|RESTRICTED
  access_roles    TEXT[]       NULL,
  pii_category    VARCHAR(50)  NULL,
  log_access      BOOLEAN      NOT NULL DEFAULT FALSE,
  rationale       TEXT         NOT NULL,
  classified_by   VARCHAR(100) NOT NULL,
  classified_at   TIMESTAMP    NOT NULL,
  review_due      DATE         NULL,
  PRIMARY KEY (table_name, column_name)
);

-- ── Row-level security (Aurora PostgreSQL) ───────────────────
-- Enforced at the database layer; cannot be bypassed by any query.
-- Set session context before each retrieval call:
--   SET LOCAL app.user_id        = :requesting_user_id;
--   SET LOCAL app.user_territory = :user_territory;
--   SET LOCAL app.user_role      = :user_role;

ALTER TABLE account_ai_surface ENABLE ROW LEVEL SECURITY;

CREATE POLICY account_visibility ON account_ai_surface
  FOR SELECT
  USING (
    assigned_manager_id = current_setting('app.user_id')::uuid
    OR territory_code   = current_setting('app.user_territory')
    OR current_setting('app.user_role') = ANY(visibility_roles)
  );
