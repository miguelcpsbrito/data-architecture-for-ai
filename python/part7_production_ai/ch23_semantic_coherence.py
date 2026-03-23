"""
Chapter 23: Observability for the Data Layer
Semantic coherence monitoring — embedding cluster analysis.
Data Architecture for AI — Miguel Brito
"""

import json
import boto3
import numpy as np
from opensearchpy import OpenSearch

bedrock = boto3.client('bedrock-runtime')


def compute_semantic_coherence(
    opensearch_client: OpenSearch,
    concept_query: str,
    index_name: str = 'knowledge-base',
    top_k: int = 100,
) -> dict:
    """
    Measure the semantic coherence of a concept in the knowledge base.

    Returns mean pairwise cosine similarity of top-k retrieved embeddings.
    A high score indicates the concept is expressed consistently (tight cluster).
    A low score indicates vocabulary fragmentation (diffuse cluster).

    Score thresholds:
      > 0.85 → OK    (consistent representation)
      0.70–0.85 → WARN (investigate vocabulary drift)
      < 0.70 → FRAGMENTED (significant fragmentation; retrieval quality degraded)

    Run weekly; alert if score drops below threshold.
    """
    # Embed the concept query
    resp = bedrock.invoke_model(
        modelId='amazon.titan-embed-text-v2:0',
        body=json.dumps({'inputText': concept_query})
    )
    query_vec = json.loads(resp['body'].read())['embedding']

    # Retrieve top-k embeddings from the index
    response = opensearch_client.search(
        index=index_name,
        body={'size': top_k,
              'query': {'knn': {'embedding': {'vector': query_vec, 'k': top_k}}}}
    )
    vecs = np.array([h['_source']['embedding'] for h in response['hits']['hits']])

    if len(vecs) < 10:
        return {'coherence_score': None, 'sample_size': len(vecs),
                'warning': 'insufficient_sample'}

    # Mean pairwise cosine similarity (exclude diagonal self-similarity = 1.0)
    norms = np.linalg.norm(vecs, axis=1, keepdims=True)
    normalised = vecs / np.maximum(norms, 1e-9)
    sim_matrix = normalised @ normalised.T
    mask = ~np.eye(len(vecs), dtype=bool)
    mean_sim = float(sim_matrix[mask].mean())

    return {
        'concept':         concept_query,
        'coherence_score': round(mean_sim, 4),
        'sample_size':     len(vecs),
        'status': (
            'OK'         if mean_sim > 0.85 else
            'WARN'       if mean_sim > 0.70 else
            'FRAGMENTED'
        ),
    }
