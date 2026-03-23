"""
Chapter 24: Migration Patterns
Migration phase gate definitions.
Data Architecture for AI — Miguel Brito
"""

# Migration phase exit criteria.
# Each gate defines what must be true before progressing to the next phase.
MIGRATION_PHASE_GATES = {
    "phase_0_to_1": {
        "name": "Audit → Parallel Surface Build",
        "required": [
            "Ch. 22 AI readiness assessment completed for all target entity types",
            "Priority migration list defined (5-10 entity types, sorted by value × feasibility)",
            "Legacy surface inventory documented (tables, columns, consumers)",
        ],
    },
    "phase_1_to_2": {
        "name": "Parallel Build → Pilot AI Use Case",
        "required": [
            "AI surface schema validates against contract (null rates, valid values, types)",
            "Completeness gate passes: coverage_pct >= 99.5%",
            "Transformation pipeline ran for 5+ consecutive days without contract violations",
            "Ch. 22 Dimensions 1, 3, 5 score >= 3/5 each",
            "Circuit breaker operational and tested (ch16_circuit_breaker.py)",
        ],
    },
    "phase_2_to_3": {
        "name": "Pilot → Incremental Coverage",
        "required": [
            "AI quality regression tests pass for top 20 representative queries",
            "Semantic enrichment correctly interprets top 10 query types for pilot use case",
            "Freshness monitoring CloudWatch alarms configured and tested",
            "Data contract published and version-controlled for all pilot surfaces",
        ],
    },
    "phase_3_to_4": {
        "name": "Incremental Coverage → Legacy Retirement",
        "required": [
            "All AI consumers confirmed migrated to new surface (AI system manifest updated)",
            "Ch. 15 major version deprecation protocol completed (60-day notice minimum)",
            "Legacy AI surface archived (not deleted) with 90-day retention",
            "Monitoring confirmed on new surface: no legacy surface metrics in production dashboards",
        ],
    },
    "phase_4_to_5": {
        "name": "Legacy Retirement → Continuous Improvement",
        "required": [
            "Ch. 22 assessment score >= 22/35 overall",
            "Dimensions 1 and 5 score >= 4/5 each",
            "Governance health dashboard stable for 30+ days",
            "Streaming update pipeline operational (or batch cadence within freshness SLA)",
        ],
    },
}


def check_phase_gate(phase_key: str, checklist: dict) -> dict:
    """
    Verify that all required items for a phase gate are checked.

    Args:
        phase_key: e.g. 'phase_1_to_2'
        checklist: dict mapping requirement text → bool (True = confirmed)

    Returns:
        {'passed': bool, 'missing': list[str]}
    """
    gate = MIGRATION_PHASE_GATES.get(phase_key)
    if not gate:
        raise ValueError(f"Unknown phase gate: {phase_key}")

    missing = [req for req in gate["required"] if not checklist.get(req, False)]
    return {"passed": len(missing) == 0, "missing": missing}
