"""
Chapter 20: Knowledge Graphs in Practice
Entity extraction with Bedrock + Neptune ingestion.
Data Architecture for AI — Miguel Brito
"""

import boto3
import json
import psycopg2
from gremlin_python.driver import client as gremlin_client


# ── Bedrock entity and relationship extraction ────────────────
EXTRACTION_PROMPT = """
Extract entities and relationships from the following text.
Return a JSON object with two arrays:
  'entities': [{id, type, name, canonical_id_hint}]
  'relationships': [{subject_id, predicate, object_id, confidence}]

Entity types: Customer, Employee, Product, Contract, Location, Event
Relationship types: owned_by, managed_by, uses_product, located_in, supersedes, caused_by, involves
Confidence: 0.9=explicit in text; 0.7=strongly implied; 0.5=inferred

Text:
{text}

Return ONLY the JSON object, no preamble or explanation.
"""

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')


def extract_entities_and_relationships(text_chunk: str) -> dict:
    """
    Extract typed entities and relationships from a text chunk using Bedrock.
    Returns structured data ready for Neptune graph ingestion.
    """
    response = bedrock.invoke_model(
        modelId='anthropic.claude-sonnet-4-6',
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 2000,
            'messages': [{'role': 'user', 'content': EXTRACTION_PROMPT.format(text=text_chunk)}]
        })
    )
    content = json.loads(response['body'].read())
    text = content['content'][0]['text'].strip()
    if text.startswith('```'):
        text = text.split('\n', 1)[1].rsplit('```', 1)[0].strip()
    return json.loads(text)


# ── Neptune ingestion (relational surface → graph) ────────────
def ingest_relational_surface_to_neptune(
    pg_conn,
    neptune_endpoint: str,
    predicates: list = None,
) -> dict:
    """
    Migrate active relationships from entity_relationships (Ch. 6) into Neptune.
    Vertices are upserted if not already present. Idempotent: safe to re-run.

    Args:
        pg_conn: psycopg2 connection to Aurora
        neptune_endpoint: Neptune cluster endpoint (without port or protocol)
        predicates: optional list of predicate types to filter (None = all)
    """
    predicates_filter = ''
    params: list = []
    if predicates:
        placeholders = ','.join(['%s'] * len(predicates))
        predicates_filter = f'AND predicate IN ({placeholders})'
        params = predicates

    with pg_conn.cursor() as cur:
        cur.execute(
            f"""
            SELECT subject_id, subject_type, predicate,
                   object_id, object_type,
                   valid_from, valid_to, confidence, source_system
            FROM entity_relationships
            WHERE valid_to IS NULL {predicates_filter}
            """,
            params,
        )
        rows = cur.fetchall()

    g = gremlin_client.Client(f'wss://{neptune_endpoint}:8182/gremlin', 'g')
    ingested = 0

    for row in rows:
        subj_id, subj_type, pred, obj_id, obj_type, \
            valid_from, valid_to, confidence, source = row

        # Upsert vertices (idempotent)
        for cid, ctype in [(subj_id, subj_type), (obj_id, obj_type)]:
            g.submit(
                "g.V().has('canonical_id', cid).fold()"
                ".coalesce(unfold(),"
                " addV(ctype).property('canonical_id', cid))",
                {'cid': str(cid), 'ctype': ctype}
            ).all().result()

        # Add directed, time-stamped edge
        g.submit(
            "g.V().has('canonical_id', sid).as('s')"
            ".V().has('canonical_id', oid)"
            ".addE(pred).from('s')"
            ".property('valid_from', vf)"
            ".property('valid_to',   vt)"
            ".property('confidence', conf)"
            ".property('source',     src)",
            {'sid': str(subj_id), 'oid': str(obj_id),
             'pred': pred, 'vf': str(valid_from), 'vt': str(valid_to),
             'conf': float(confidence or 0.8), 'src': source}
        ).all().result()
        ingested += 1

    g.close()
    return {'ingested': ingested, 'total': len(rows)}
