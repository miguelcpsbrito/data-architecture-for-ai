"""
Chapter 12: Schema Patterns for AI-Ready Data Models
AWS Glue ETL pipeline for the AI-ready surface.
Data Architecture for AI — Miguel Brito
"""

import sys
import yaml
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args    = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc      = SparkContext()
glueContext = GlueContext(sc)
job     = Job(glueContext)
job.init(args['JOB_NAME'], args)

# ── Read from operational Aurora tables ──────────────────────
accounts_df   = glueContext.create_dynamic_frame.from_catalog(
    database="operational_db", table_name="accounts")
account_types = glueContext.create_dynamic_frame.from_catalog(
    database="operational_db", table_name="account_types")
customers_df  = glueContext.create_dynamic_frame.from_catalog(
    database="operational_db", table_name="customers")

# ── Semantic denormalisation: resolve foreign keys ────────────
enriched = accounts_df \
    .join(account_types, 'account_type_code') \
    .join(customers_df,  'customer_id')

# ── Naming convention transformations ────────────────────────
renamed = enriched \
    .rename_field('tp_cd',      'account_type') \
    .rename_field('stat',       'account_status') \
    .rename_field('cr_lmt',     'credit_limit_usd') \
    .rename_field('adj_bal',    'adjusted_balance_usd') \
    .rename_field('flg_prm',    'is_premium_account') \
    .rename_field('flg_rev',    'is_under_manual_review') \
    .rename_field('src_sys',    'source_system') \
    .rename_field('lst_txn_dt', 'last_transaction_date')

# ── Controlled vocabulary canonicalisation ────────────────────
with open('vocab_map.yaml') as f:
    vocab_map = yaml.safe_load(f)


def apply_vocabulary_canonicalisation(record, vocab):
    """Expand coded values to controlled vocabulary terms."""
    r = dict(record)
    for field, mapping in vocab.items():
        if field in r and r[field] in mapping:
            r[field] = mapping[r[field]]
    return r


canonicalised = renamed.map(
    lambda r: apply_vocabulary_canonicalisation(r, vocab_map))

# ── Write to AI surface (partitioned for incremental refresh) ─
glueContext.write_dynamic_frame.from_options(
    frame=canonicalised,
    connection_type="s3",
    connection_options={"path": "s3://ai-surface/accounts/"},
    format="parquet")

job.commit()
