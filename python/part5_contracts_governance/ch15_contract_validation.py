"""
Chapter 15: The Contract That Doesn't Exist
Contract validation with Great Expectations.
Data Architecture for AI — Miguel Brito
"""

import great_expectations as gx
import yaml
import logging

logger = logging.getLogger(__name__)


class ContractViolationError(Exception):
    """Raised when the data does not meet the contract commitments."""
    pass


def build_expectation_suite_from_contract(contract_path: str) -> gx.core.ExpectationSuite:
    """
    Build a Great Expectations suite from a data contract YAML file.
    Call this in the ETL pipeline before writing to the AI surface.
    """
    with open(contract_path) as f:
        contract = yaml.safe_load(f)

    spec    = contract["contract"]
    context = gx.get_context()
    suite   = context.add_expectation_suite(f"{spec['id']}_{spec['version']}")

    for col in spec["schema"]["columns"]:
        if not col.get("nullable", True):
            suite.add_expectation(
                gx.expectations.ExpectColumnValuesToNotBeNull(column=col["name"])
            )
        if "valid_values" in col:
            suite.add_expectation(
                gx.expectations.ExpectColumnValuesToBeInSet(
                    column=col["name"], value_set=col["valid_values"]
                )
            )

    for quality in spec.get("quality", []):
        col = quality.get("column")
        if col and "max_null_rate" in quality:
            suite.add_expectation(
                gx.expectations.ExpectColumnValuesToNotBeNull(
                    column=col, mostly=1 - quality["max_null_rate"]
                )
            )
        if col and "value_range" in quality:
            suite.add_expectation(
                gx.expectations.ExpectColumnValuesToBeBetween(
                    column=col,
                    min_value=quality["value_range"]["min"],
                    max_value=quality["value_range"]["max"],
                )
            )

    return suite


def validate_against_contract(batch, contract_path: str, run_id: str) -> None:
    """
    Validate a data batch against the contract specification.
    Raises ContractViolationError if any commitment is violated.
    Call this BEFORE writing to the AI surface.
    """
    suite   = build_expectation_suite_from_contract(contract_path)
    context = gx.get_context()

    results = context.run_validation_operator(
        "action_list_operator",
        assets_to_validate=[batch],
        run_id=run_id,
    )

    if not results.success:
        logger.error("Contract violation: %s", results.statistics)
        raise ContractViolationError(
            f"Contract {contract_path} violated — "
            f"do not write to AI surface. Stats: {results.statistics}"
        )

    logger.info("Contract validation passed for run %s", run_id)
