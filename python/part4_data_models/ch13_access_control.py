"""
Chapter 13: Sensitivity, Classification, and Access at the Data Model Level
Minimum necessary data field sets and access helpers.
Data Architecture for AI — Miguel Brito
"""

# Minimum necessary data: field sets by question category.
# Each set contains only the fields needed to answer that category
# of question; do not retrieve the full record unless required.
FIELD_SETS = {
    "account_identity": [
        "account_id", "account_name", "account_type", "account_status",
        "customer_name", "customer_industry",
    ],
    "account_commercial": [
        # Requires: CONFIDENTIAL clearance minimum
        "account_id", "account_name",
        "credit_limit_usd", "adjusted_balance_usd", "payment_terms",
        "contract_start_date", "contract_end_date", "annual_contract_value_usd",
    ],
    "account_strategic": [
        # Requires: account_manager or sales_director role
        "account_id", "account_name",
        "strategic_tier", "renewal_risk", "is_premium_account",
        "assigned_manager_id", "last_qbr_date",
    ],
    "account_contact": [
        # Requires: RESTRICTED clearance; access is logged
        "account_id", "account_name",
        "primary_contact_name", "primary_contact_email", "primary_contact_phone",
    ],
}


def get_retrieval_fields(question_category: str, user_permissions: dict) -> list:
    """
    Return only the fields appropriate for this question category,
    filtered to what the user is permitted to access.
    """
    base_fields = FIELD_SETS.get(question_category, FIELD_SETS["account_identity"])
    return [f for f in base_fields if user_can_access_field(f, user_permissions)]


def user_can_access_field(field_name: str, user_permissions: dict) -> bool:
    """
    Check column_sensitivity registry for this field against user permissions.
    Implementation: query column_sensitivity WHERE table_name = 'account_ai_surface'
    AND column_name = field_name, then check access_roles against user_permissions['roles'].
    """
    raise NotImplementedError("Implement against your column_sensitivity registry")
