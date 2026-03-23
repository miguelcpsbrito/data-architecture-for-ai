#!/usr/bin/env bash
# Chapter 12: Add AI-ready column descriptions to Glue Data Catalog
# Data Architecture for AI — Miguel Brito
# Replace ACCOUNT_ID, DATABASE, TABLE, and column comments with your values.

aws glue update-table \
  --database-name enterprise_data \
  --table-input '{
    "Name": "account_facts",
    "StorageDescriptor": {
      "Columns": [
        {
          "Name": "account_id",
          "Type": "string",
          "Comment": "Canonical account identifier (UUID). Use to join to contract_facts and interaction_history. Never reused after account closure."
        },
        {
          "Name": "account_type",
          "Type": "string",
          "Comment": "Account tier: Enterprise (>1000 employees or >$1M ARR, enterprise SLA, dedicated CSM), Commercial (50-1000 employees, shared support), SMB (<50 employees, self-serve)."
        },
        {
          "Name": "account_status",
          "Type": "string",
          "Comment": "Current status: active (revenue generating, all services enabled), inactive (no revenue 90+ days, renewal outreach triggered), suspended (services restricted pending payment), churned (contract terminated)."
        },
        {
          "Name": "adjusted_balance_usd",
          "Type": "double",
          "Comment": "Outstanding balance USD after credits, prepayments, and manual adjustments. Calculated nightly by finance_reconciliation_job. Source: finance_erp (confidence: 0.92). Null: no outstanding balance or calculation pending."
        },
        {
          "Name": "is_premium_account",
          "Type": "boolean",
          "Comment": "True: enrolled in Premium Service Programme. Entitlements: white-glove onboarding, quarterly business reviews, 4-hour response SLA, dedicated CSM. False: standard terms. Null: classification pending (new accounts, 30-day onboarding window)."
        }
      ]
    }
  }'
