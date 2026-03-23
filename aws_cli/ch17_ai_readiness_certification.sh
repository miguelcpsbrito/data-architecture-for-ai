#!/usr/bin/env bash
# Chapter 17: AI readiness certification in Glue Data Catalog
# Data Architecture for AI — Miguel Brito
# Update ai_ready_valid_until quarterly; automated expiry alerts via CloudWatch.

aws glue update-table \
  --database-name ai_surface \
  --table-input '{
    "Name": "account_ai_surface",
    "Parameters": {
      "ai_ready":               "true",
      "ai_ready_certified_by":  "customer_data_steward",
      "ai_ready_certified_at":  "2024-11-01",
      "ai_ready_valid_until":   "2025-02-01",
      "ai_ready_use_cases":     "account_assistant,sales_intelligence,support_routing",
      "data_domain":            "customer",
      "governance_tier":        "CONFIDENTIAL",
      "steward_role":           "customer_data_steward",
      "steward_email":          "data-steward@company.com",
      "contract_id":            "account_ai_surface",
      "contract_version":       "2.1.0",
      "contract_registry":      "s3://governance/contracts/account_ai_surface_v2.1.yaml",
      "quality_last_check":     "2024-11-15T06:15:00Z",
      "quality_status":         "PASS",
      "freshness_sla_hours":    "30",
      "last_updated":           "2024-11-15T06:00:00Z"
    }
  }'
