"""
Chapter 25: Data Architecture Failures — Ten Autopsies
Diagnostic index: map AI quality failures to root causes and correct chapters.
Data Architecture for AI — Miguel Brito

Usage:
    from ch25_autopsy_index import AUTOPSY_REFERENCE_MAP, find_autopsies_by_chapter

    # Find all autopsies related to Ch. 13 (Sensitivity)
    find_autopsies_by_chapter(13)
"""

AUTOPSY_REFERENCE_MAP = {
    "01": {
        "title":        "The Customer 360 That Answered No Question",
        "failure_mode": "Mixed surfaces, canonical identifier failure",
        "root_cause":   (
            "847-column table mixing facts, relationships, and context. "
            "No entity resolution across 12 source systems. "
            "No canonical identifiers."
        ),
        "correct_design_chapters": [4, 5, 6, 7],
        "key_fix": (
            "Separate the three surfaces. Implement canonical identifiers "
            "through entity resolution before building any AI surface."
        ),
    },
    "02": {
        "title":        "The Policy Bot That Gave Outdated Advice",
        "failure_mode": "Temporal knowledge failure",
        "root_cause":   (
            "Knowledge base built once from 340 documents, never updated. "
            "No change detection, no freshness monitoring, no stale chunk retirement."
        ),
        "correct_design_chapters": [8, 15, 16, 21],
        "key_fix": (
            "Every chunk must carry source document provenance. "
            "Change detection must trigger re-embedding when source documents update."
        ),
    },
    "03": {
        "title":        "The RAG System That Leaked Restricted Documents",
        "failure_mode": "Ownership boundary failure",
        "root_cause":   (
            "Access control implemented at application layer only. "
            "AI retrieval bypassed the deal pipeline application entirely. "
            "No column_sensitivity registry. No data-layer RLS."
        ),
        "correct_design_chapters": [13],
        "key_fix": (
            "Access control must be at the data layer, not the application layer. "
            "Every AI access path must enforce the same sensitivity controls."
        ),
    },
    "04": {
        "title":        "The Model That Confidently Hallucinated",
        "failure_mode": "Provenance and confidence failure",
        "root_cause":   (
            "Web-scraped claims stored with same weight as verified audit records. "
            "No confidence scores. No provenance metadata."
        ),
        "correct_design_chapters": [10],
        "key_fix": (
            "Every fact must carry a confidence score from the source quality table. "
            "Provenance chains must link claims to specific source documents."
        ),
    },
    "05": {
        "title":        "The Pipeline That Broke Silently",
        "failure_mode": "Data contract failure",
        "root_cause":   (
            "No data contract. Column renamed upstream without notification. "
            "No circuit breaker. Pipeline error not alerted. "
            "AI surface served 11-day-old data with no staleness signal."
        ),
        "correct_design_chapters": [15, 16],
        "key_fix": (
            "Formal data contracts with schema commitments. "
            "AI data access manifest for impact assessment before schema changes. "
            "Circuit breaker halts pipeline on contract violation."
        ),
    },
    "06": {
        "title":        "The Knowledge Base That Grew Stale",
        "failure_mode": "Freshness governance failure",
        "root_cause":   (
            "No freshness SLA. No staleness monitoring. No steward. "
            "Knowledge base accurate at launch, never updated. "
            "18 months of accumulated drift."
        ),
        "correct_design_chapters": [8, 15, 17, 21],
        "key_fix": (
            "Freshness SLAs in data contracts. Continuous freshness monitoring. "
            "Named steward accountable for knowledge base currency. "
            "Streaming update pipeline keeps knowledge base current."
        ),
    },
    "07": {
        "title":        "The Embedding That Encoded PII",
        "failure_mode": "Sensitivity classification failure",
        "root_cause":   (
            "PII detection applied to structured data only. "
            "PDF archive ingested without Macie scanning. "
            "No chunk-level provenance for right-to-erasure."
        ),
        "correct_design_chapters": [13],
        "key_fix": (
            "Macie must scan ALL document sources before ingestion. "
            "Every chunk must store source_record_id for targeted erasure. "
            "Right-to-erasure process must be designed and tested before go-live."
        ),
    },
    "08": {
        "title":        "The Knowledge Graph Nobody Maintained",
        "failure_mode": "Governance and ownership failure",
        "root_cause":   (
            "No steward. No governance operating model. No monitoring. "
            "No succession plan. 22 months of structural drift."
        ),
        "correct_design_chapters": [14, 17, 18],
        "key_fix": (
            "Every entity type and relationship type must have a named steward. "
            "Orphan monitoring must run continuously. "
            "AI readiness certification required for graph to be AI-approved."
        ),
    },
    "09": {
        "title":        "The Semantic Layer Only the Data Team Understood",
        "failure_mode": "Accessibility failure",
        "root_cause":   (
            "340-entry business glossary in Confluence wiki. "
            "Not connected to the Glue Data Catalog. "
            "Semantic enrichment step not implemented in retrieval pipeline."
        ),
        "correct_design_chapters": [19],
        "key_fix": (
            "The semantic layer must be infrastructure, not documentation. "
            "Column descriptions must reference canonical terms. "
            "Retrieval pipeline must expand terms at query time."
        ),
    },
    "10": {
        "title":        "The AI That Knew Everything — and Nothing About Now",
        "failure_mode": "Temporal modelling failure",
        "root_cause":   (
            "Overwrite-on-update pattern. No temporal history preserved. "
            "AI system could answer 'what is X now?' but not "
            "'what was X six months ago?' or 'how has X changed?'"
        ),
        "correct_design_chapters": [8, 9],
        "key_fix": (
            "Stop the overwrite pattern. Implement SCD Type 2: "
            "close current record, create new record. "
            "This single change preserves complete history and enables "
            "point-in-time queries without a full architectural overhaul."
        ),
    },
}


def find_autopsies_by_chapter(chapter: int) -> list:
    """Return all autopsies whose correct_design_chapters includes the given chapter."""
    return [
        {"autopsy": num, "title": data["title"], "failure_mode": data["failure_mode"]}
        for num, data in AUTOPSY_REFERENCE_MAP.items()
        if chapter in data["correct_design_chapters"]
    ]


def diagnose(symptom_keywords: list) -> list:
    """
    Rough diagnostic: find autopsies whose failure_mode or root_cause
    contains any of the given keywords (case-insensitive).
    """
    results = []
    for num, data in AUTOPSY_REFERENCE_MAP.items():
        text = f"{data['failure_mode']} {data['root_cause']}".lower()
        if any(kw.lower() in text for kw in symptom_keywords):
            results.append({
                "autopsy": num,
                "title":   data["title"],
                "correct_design_chapters": data["correct_design_chapters"],
                "key_fix": data["key_fix"],
            })
    return results
