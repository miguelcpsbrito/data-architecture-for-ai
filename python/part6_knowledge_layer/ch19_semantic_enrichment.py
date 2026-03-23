"""
Chapter 19: Building the Semantic Layer
Semantic enrichment step for the retrieval pipeline.
Data Architecture for AI — Miguel Brito
"""

import re
from typing import Optional

# Pattern for canonical term references in column descriptions.
# Format: [canonical term]  e.g. [Monthly Recurring Revenue]
TERM_REFERENCE_PATTERN = re.compile(r'\[([^\]]+)\]')


def enrich_with_semantic_context(
    retrieved_record: dict,
    column_descriptions: dict,   # col_name -> description from Glue Data Catalog
    db_conn,
) -> dict:
    """
    Expand [canonical term] references in column descriptions to full glossary
    definitions at retrieval time. Include the result in the model's context.

    Args:
        retrieved_record: the data values from the AI surface
        column_descriptions: column → description from Glue Data Catalog
        db_conn: connection to the database hosting semantic_glossary

    Returns:
        dict with 'data_values', 'semantic_context', 'total_terms_expanded'
    """
    enriched_context: dict = {}
    terms_expanded: set = set()

    for col_name in retrieved_record:
        description = column_descriptions.get(col_name, '')
        for term in TERM_REFERENCE_PATTERN.findall(description):
            if term in terms_expanded:
                continue
            definition = _lookup_glossary_term(term, db_conn)
            if definition:
                enriched_context[term] = definition
                terms_expanded.add(term)

    return {
        'data_values':          retrieved_record,
        'semantic_context':     enriched_context,
        'total_terms_expanded': len(terms_expanded),
    }


def _lookup_glossary_term(term: str, db_conn) -> Optional[dict]:
    """Query semantic_glossary for a canonical term or synonym."""
    with db_conn.cursor() as cur:
        cur.execute(
            """
            SELECT canonical_term, definition, calculation,
                   synonyms, excludes, business_context
            FROM semantic_glossary
            WHERE (canonical_term = %s OR %s = ANY(synonyms))
              AND status = 'active'
            LIMIT 1
            """,
            (term, term),
        )
        row = cur.fetchone()
        if not row:
            return None
        return {
            'canonical_term':   row[0],
            'definition':       row[1],
            'calculation':      row[2],
            'synonyms':         row[3] or [],
            'excludes':         row[4] or [],
            'business_context': row[5],
        }
