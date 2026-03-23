"""
Chapter 21: Real-Time Knowledge — Streaming Updates
Delta significance detector + incremental re-embedding Lambda.
Data Architecture for AI — Miguel Brito
"""

import hashlib
import json
import boto3
import numpy as np
from typing import Optional
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

session = boto3.Session()
bedrock = boto3.client('bedrock-runtime')


# ── Delta significance detector ───────────────────────────────

def should_reembed(
    old_content: dict,
    new_content: dict,
    relevant_fields: list,
    old_embedding: Optional[list] = None,
    similarity_threshold: float = 0.98,
) -> tuple:
    """
    Decide whether a content change warrants re-embedding.

    Two-stage filter:
      1. Hash comparison — skip if relevant content is unchanged
      2. Cosine similarity pre-check — skip if change is trivially similar (e.g. typo fix)

    Returns:
        (should_reembed: bool, reason: str)
    """
    old_rel = {k: old_content.get(k) for k in relevant_fields}
    new_rel = {k: new_content.get(k) for k in relevant_fields}

    old_hash = hashlib.sha256(str(sorted(old_rel.items())).encode()).hexdigest()
    new_hash = hashlib.sha256(str(sorted(new_rel.items())).encode()).hexdigest()

    if old_hash == new_hash:
        return False, 'content_unchanged'

    if old_embedding is not None:
        new_emb = _get_embedding(str(new_rel))
        sim = _cosine_similarity(old_embedding, new_emb)
        if sim >= similarity_threshold:
            return False, f'embedding_stable (similarity={sim:.4f})'

    return True, 'content_changed'


def _cosine_similarity(a: list, b: list) -> float:
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


def _get_embedding(text: str) -> list:
    """Embed text with Titan Embed v2."""
    resp = bedrock.invoke_model(
        modelId='amazon.titan-embed-text-v2:0',
        body=json.dumps({'inputText': text})
    )
    return json.loads(resp['body'].read())['embedding']


# ── Incremental re-embedding Lambda handler ───────────────────

def lambda_handler(event, context):
    """
    Process SQS delta work items: re-embed changed records and update OpenSearch.
    Triggered by the SQS delta queue populated by the CDC Lambda (Schema 21.1).
    """
    opensearch = _get_opensearch_client()
    results = {'succeeded': 0, 'failed': 0}

    for sqs_record in event['Records']:
        item = json.loads(sqs_record['body'])
        try:
            enriched  = _assemble_enriched_content(item)
            embedding = _get_embedding(enriched['text'])
            doc_id    = f"{item['table']}#{item['entity_id']}"

            opensearch.index(
                index='knowledge-base',
                id=doc_id,
                body={
                    'text':            enriched['text'],
                    'embedding':       embedding,
                    'entity_id':       item['entity_id'],
                    'entity_type':     item['table'],
                    'source_version':  item['source_record'].get('updated_at'),
                    'indexed_at':      context.aws_request_id,
                    'semantic_context': enriched.get('semantic_context', {}),
                    'source_record_id': item['entity_id'],   # for right-to-erasure (Ch. 13)
                    'source_table':     item['table'],
                },
                refresh='wait_for',   # immediately queryable
            )
            results['succeeded'] += 1

        except Exception as e:
            print(f"Re-embed failed for {item['entity_id']}: {e}")
            results['failed'] += 1
            raise  # let SQS retry / route to DLQ

    return results


def _assemble_enriched_content(item: dict) -> dict:
    """
    Build the enriched text representation for embedding.
    Combines data values with semantic context from Glue Data Catalog.
    See Ch. 12 (schema patterns) and Ch. 19 (semantic layer).
    """
    raise NotImplementedError("Implement with your Glue catalog client")


def _get_opensearch_client() -> OpenSearch:
    credentials = session.get_credentials()
    auth = AWS4Auth(
        credentials.access_key, credentials.secret_key,
        'us-east-1', 'aoss',
        session_token=credentials.token,
    )
    return OpenSearch(
        hosts=[{'host': 'YOUR_OPENSEARCH_ENDPOINT', 'port': 443}],
        http_auth=auth, use_ssl=True,
        connection_class=RequestsHttpConnection,
    )
