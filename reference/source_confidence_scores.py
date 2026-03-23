"""
Chapter 10: Source Confidence Scores
Quick-reference lookup for base confidence by source type.
Data Architecture for AI — Miguel Brito
"""

SOURCE_CONFIDENCE_SCORES = {
    "government_registry":       0.95,
    "signed_legal_document":     0.92,
    "operational_system":        0.85,
    "third_party_data_provider": 0.75,
    "manual_crm_entry":          0.60,
    "web_scraping":              0.50,
    "user_submitted_form":       0.40,
    "ml_model_inference":        0.35,
    "free_text_extraction":      0.30,
}
# Usage: base_confidence = SOURCE_CONFIDENCE_SCORES.get(source_type, 0.40)
# Then apply recency decay from ch09_temporal_patterns.sql

CONTRACT_VERSION_PROTOCOL = {
    "patch": {
        "notice_days":     1,
        "dual_publish":    False,
        "consumer_action": "None required. Monitor for unexpected value changes.",
        "examples":        ["Correct wrong values", "Improve null documentation"],
    },
    "minor": {
        "notice_days":     7,
        "dual_publish":    False,
        "consumer_action": "May adopt new columns. Existing queries unaffected.",
        "examples":        ["New optional column", "New valid enum value"],
    },
    "major": {
        "notice_days":              60,
        "dual_publish":             True,
        "migration_window_days_min": 30,
        "consumer_action": "Must update before or within migration window.",
        "examples":        ["Column rename", "Type change", "Column removal"],
    },
}

OBSERVABILITY_ALERTS = [
    # (dimension, condition, severity, response)
    ("Freshness", "AI surface data age > freshness SLA",                   "P1", "Halt pipeline; notify consumers; staleness warning in AI responses"),
    ("Freshness", "Source update not reflected > 2x expected cadence",     "P2", "Investigate source pipeline; escalate to producer"),
    ("Freshness", "Index chunk source_version mismatch rate > 5%",         "P2", "Queue affected chunks for re-embedding"),
    ("Quality",   "Column null rate exceeds contract max_null_rate",        "P1", "Halt pipeline; notify steward and producer"),
    ("Quality",   "Categorical field distribution shift > 5% vs. 30d",     "P2", "Trigger semantic investigation; do not halt automatically"),
    ("Quality",   "Entity duplication rate increase > 2pp week-on-week",   "P2", "Investigate entity resolution pipeline; escalate to steward"),
    ("Quality",   "Controlled vocabulary violation rate > 0%",              "P1", "Reject affected records; notify producer"),
    ("Lineage",   "Orphaned relationship count > 0 for AI-critical tables", "P2", "Trigger cascade validity; investigate entity deletion"),
    ("Lineage",   "Column lineage registry stale: pipeline version mismatch","P3","Alert steward; update lineage registry"),
    ("Lineage",   "Failed re-embed rate > 1% in streaming pipeline",        "P1", "Investigate DLQ; check embedding model availability"),
    ("Volume",    "AI surface row count drops > 5% without explanation",    "P1", "Halt downstream; investigate pipeline; check source availability"),
    ("Volume",    "Knowledge graph vertex count decreases",                 "P2", "Investigate entity deletion pipeline; check cascade validity"),
    ("Volume",    "Bedrock KB document count inconsistent with source",     "P2", "Re-trigger ingestion; check S3 event routing"),
]
