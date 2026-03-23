# Data Architecture for AI — Code Reference

**Companion repository for the book:**
> *Data Architecture for AI: Building the Foundation That Makes Intelligent Systems Work*
> Miguel Brito · Book 2 of the AWS GenAI Series

[![Book 1 on Amazon](https://img.shields.io/badge/Book%201-AWS%20GenAI%20Developer%20Professional-orange)](https://a.co/d/0f0oywS3)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## What this repository contains

Every SQL schema, Python function, AWS CLI command, and Gremlin query from the book — organised by chapter and ready to adapt for your own data architecture.

This is not tutorial code. It is **production-pattern code**: the schemas, pipelines, and monitoring queries that the book argues you need to build AI systems that are reliable, maintainable, and trustworthy.

---

## Repository structure

```
data-architecture-for-ai/
│
├── sql/                          # SQL schemas and queries (PostgreSQL/Aurora dialect)
│   ├── part1_broken_foundation/  # Ch. 3 — audit queries
│   ├── part2_three_surfaces/     # Ch. 5–7 — factual, relational, contextual schemas
│   ├── part3_knowledge_changes/  # Ch. 9–10 — temporal patterns, provenance
│   ├── part4_data_models/        # Ch. 12–14 — AI surface, lineage, ownership
│   ├── part5_contracts_governance/ # Ch. 16–18 — validation, drift, succession
│   ├── part6_knowledge_layer/    # Ch. 19 — semantic glossary schema
│   └── part7_production_ai/      # Ch. 23–24 — observability, migration gates
│
├── python/                       # Python implementations
│   ├── part4_data_models/        # Ch. 12–13 — ETL, access control, field sets
│   ├── part5_contracts_governance/ # Ch. 15–16 — contract validation, circuit breaker
│   ├── part6_knowledge_layer/    # Ch. 19–21 — semantic enrichment, graph, streaming
│   └── part7_production_ai/      # Ch. 24–25 — migration gates, autopsy index
│
├── aws_cli/                      # AWS CLI commands (Glue, Lake Formation, Neptune)
│
├── reference/                    # Quick-reference constants and lookup tables
│
├── docs/                         # Additional documentation
│
└── .github/workflows/            # CI: SQL lint, Python type-check
```

---

## How to use this repository

### By chapter

Each file is named `chNN_description` and maps directly to a chapter. Open the chapter, find the schema you need, copy and adapt.

### By problem

| I need to… | Start here |
|---|---|
| Audit my data estate for AI readiness | `sql/part1_broken_foundation/ch03_audit_queries.sql` |
| Design the factual surface schema | `sql/part2_three_surfaces/ch05_factual_surface.sql` |
| Store typed relationships | `sql/part2_three_surfaces/ch06_relational_surface.sql` |
| Implement SCD Type 2 temporal history | `sql/part3_knowledge_changes/ch09_temporal_patterns.sql` |
| Track confidence and provenance | `sql/part3_knowledge_changes/ch10_provenance.sql` |
| Build the AI-ready surface ETL | `python/part4_data_models/ch12_ai_surface_etl.py` |
| Enforce sensitivity at the data layer | `sql/part4_data_models/ch13_sensitivity_access.sql` |
| Register column lineage and ownership | `sql/part4_data_models/ch14_lineage_ownership.sql` |
| Validate data contracts in a pipeline | `python/part5_contracts_governance/ch15_contract_validation.py` |
| Implement a pipeline circuit breaker | `python/part5_contracts_governance/ch16_circuit_breaker.py` |
| Build a business glossary and enrich retrieval | `sql/part6_knowledge_layer/ch19_semantic_glossary.sql` + `python/part6_knowledge_layer/ch19_semantic_enrichment.py` |
| Build and query a Neptune knowledge graph | `python/part6_knowledge_layer/ch20_knowledge_graph.py` |
| Stream knowledge base updates | `python/part6_knowledge_layer/ch21_streaming_updates.py` |
| Monitor freshness and quality | `sql/part7_production_ai/ch23_observability.sql` + `python/part7_production_ai/ch23_semantic_coherence.py` |
| Validate a data migration | `sql/part7_production_ai/ch24_migration_gates.sql` |
| Diagnose an AI quality failure | `reference/ch25_autopsy_index.py` |

---

## Prerequisites

### SQL
- PostgreSQL 14+ or Amazon Aurora PostgreSQL 15+
- Schema assumes the following extensions: `uuid-ossp` (or `pgcrypto` for `gen_random_uuid()`), `temporal_tables` (for system-versioned tables in Ch. 9)
- Queries are written in standard PostgreSQL dialect; Aurora-specific features are noted with comments

### Python
```
python >= 3.10
boto3 >= 1.34
great-expectations >= 0.18
numpy >= 1.26
opensearch-py >= 2.4
gremlin-python >= 3.7
pyyaml >= 6.0
psycopg2-binary >= 2.9
```

Install all dependencies:
```bash
pip install -r requirements.txt
```

### AWS services used
- Amazon Aurora PostgreSQL — factual, relational, and contextual surfaces
- AWS Glue — ETL pipelines and Data Catalog
- AWS Lake Formation — column and row-level access control
- Amazon DataZone — governance portal and business glossary
- Amazon Neptune — knowledge graph (property graph with Gremlin)
- Amazon Neptune Analytics — hybrid graph-vector queries
- Amazon Bedrock — LLM inference and Knowledge Bases
- Amazon OpenSearch Serverless — vector index
- Amazon Kinesis / MSK — streaming change events
- AWS DMS — Change Data Capture from Aurora
- Amazon CloudWatch — custom metrics and alarms
- Amazon Macie — PII detection

---

## A note on the code

The code in this repository is **reference patterns**, not a production framework. Every schema, query, and function will need adaptation to your specific:
- Table names and column names
- AWS account IDs, region, and resource ARNs
- Data volume and performance requirements
- Security and compliance requirements

Placeholders that require your values are marked with `:your_value` in SQL and `%(param)s` / `raise NotImplementedError(...)` in Python.

---

## Contributing

Found an error, an improvement, or a pattern that should be in the book?

1. Open an issue describing the problem or suggestion
2. For code changes: fork, make your change, open a pull request with a clear description
3. For SQL: test against PostgreSQL 15 before submitting
4. For Python: run `mypy` and `ruff` before submitting

---

## License

MIT License — see [LICENSE](LICENSE). The code is yours to use, adapt, and build on.

The book text itself is copyright Miguel Brito and is not included in this repository.

---

## Book series

| Book | Topic | Status |
|---|---|---|
| Book 1 | AWS GenAI Developer Professional (AIP-C01) | [Published](https://a.co/d/0f0oywS3) |
| **Book 2** | **Data Architecture for AI** | **This repository** |
| Book 3 | Beyond the Model: Architecting Production Generative AI Systems on AWS | Forthcoming |
