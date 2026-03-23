"""
Chapter 16: When Contracts Break
Pipeline circuit breaker — three-state machine (CLOSED / OPEN / HALF-OPEN).
Data Architecture for AI — Miguel Brito
"""

import enum
import logging
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import Optional

logger = logging.getLogger(__name__)


class CircuitState(enum.Enum):
    CLOSED    = 'closed'     # operating normally; output flows to AI surface
    OPEN      = 'open'       # violation detected; output blocked; last valid surface maintained
    HALF_OPEN = 'half_open'  # testing recovery; limited output to validate the fix


@dataclass
class PipelineCircuitBreaker:
    """
    Circuit breaker for data pipelines.

    States:
      CLOSED    — normal operation; record_success() returns True
      OPEN      — contract violation detected; allows_output returns False
      HALF_OPEN — after recovery_timeout_min, tests whether the fix holds

    Usage:
        cb = PipelineCircuitBreaker(contract_id="account_ai_surface_v2.1")
        if validation_passes:
            if cb.record_success():
                write_to_ai_surface(data)
        else:
            cb.record_failure(violation_description)
    """
    contract_id:          str
    failure_threshold:    int = 1    # violations before OPEN
    recovery_timeout_min: int = 60   # minutes before HALF_OPEN
    half_open_max_passes: int = 3    # consecutive passes to close

    state:             CircuitState       = field(default=CircuitState.CLOSED, init=False)
    failure_count:     int                = field(default=0,    init=False)
    pass_count:        int                = field(default=0,    init=False)
    last_failure_at:   Optional[datetime] = field(default=None, init=False)
    last_state_change: Optional[datetime] = field(default=None, init=False)

    def record_success(self) -> bool:
        """Call when validation passes. Returns True if output should proceed."""
        if self.state == CircuitState.CLOSED:
            self.failure_count = 0
            return True
        if self.state == CircuitState.HALF_OPEN:
            self.pass_count += 1
            if self.pass_count >= self.half_open_max_passes:
                self._transition(CircuitState.CLOSED)
                logger.info("Circuit %s closed after recovery", self.contract_id)
            return True
        return False  # OPEN: block output

    def record_failure(self, violation: str) -> bool:
        """Call when validation fails. Returns True if output should proceed (never)."""
        self.failure_count += 1
        self.last_failure_at = datetime.utcnow()
        logger.error("Contract %s violation: %s", self.contract_id, violation)
        if self.failure_count >= self.failure_threshold:
            self._transition(CircuitState.OPEN)
            self._notify_incident(violation)
        return False

    def check_recovery_eligible(self) -> None:
        """Transition OPEN → HALF_OPEN after timeout elapses."""
        if (self.state == CircuitState.OPEN and self.last_failure_at
                and datetime.utcnow() - self.last_failure_at
                > timedelta(minutes=self.recovery_timeout_min)):
            self._transition(CircuitState.HALF_OPEN)
            self.pass_count = 0
            logger.info("Circuit %s entering half-open", self.contract_id)

    def _transition(self, new_state: CircuitState) -> None:
        self.state = new_state
        self.last_state_change = datetime.utcnow()

    def _notify_incident(self, violation: str) -> None:
        """Trigger incident notification. Implement with SNS / PagerDuty / Slack."""
        logger.critical(
            "CIRCUIT OPEN: contract %s — %s — last valid surface maintained.",
            self.contract_id, violation,
        )

    @property
    def allows_output(self) -> bool:
        self.check_recovery_eligible()
        return self.state != CircuitState.OPEN
