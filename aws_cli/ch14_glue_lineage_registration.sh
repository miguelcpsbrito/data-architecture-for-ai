#!/usr/bin/env bash
# Chapter 14: Register lineage and ownership in Glue Data Catalog + Lake Formation
# Data Architecture for AI — Miguel Brito

# Step 1: Register lineage metadata as Glue table parameters
aws glue update-table \
  --database-name ai_surface \
  --table-input '{
    "Name": "account_ai_surface",
    "Parameters": {
      "lineage.pipeline":        "account_ai_surface_etl",
      "lineage.pipeline_version":"2.3.1",
      "lineage.source_tables":   "operational_db.accounts,operational_db.account_types",
      "lineage.last_run":        "2024-11-15T09:00:00Z",
      "ownership.steward_role":  "customer_data_steward",
      "ownership.steward_email": "data-steward@company.com",
      "ownership.producer_team": "platform_data_engineering",
      "ownership.review_due":    "2025-02-15",
      "quality.freshness_sla":   "24h",
      "quality.last_verified":   "2024-11-14T22:30:00Z"
    }
  }'

# Step 2: Apply sensitivity classification tags via Lake Formation
aws lakeformation add-lf-tags-to-resource \
  --resource '{"Table": {"DatabaseName": "ai_surface", "Name": "account_ai_surface"}}' \
  --lf-tags '[
    {"TagKey": "sensitivity",  "TagValues": ["CONFIDENTIAL"]},
    {"TagKey": "data_product", "TagValues": ["account_ai_surface_v2"]},
    {"TagKey": "ai_approved",  "TagValues": ["true"]}
  ]'

# Step 3: Grant the AI retrieval role SELECT access
aws lakeformation grant-permissions \
  --principal DataLakePrincipalIdentifier=arn:aws:iam::ACCOUNT_ID:role/AIRetrievalRole \
  --resource '{"Table": {"DatabaseName": "ai_surface", "Name": "account_ai_surface"}}' \
  --permissions SELECT
