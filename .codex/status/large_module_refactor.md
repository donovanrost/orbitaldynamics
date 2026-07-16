# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Realized-state-snapshot callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replaced the fourteen-function realized-state-snapshot callback bag with direct
planner-limit, aggregation, primitive, collection, stable-ID, spacecraft-state,
and realized-activity dependencies.

Result:
- Removed `realized_state_snapshot_contract_callbacks/0` and the callback
  argument from `RealizedStateSnapshotContracts.validate/3`.
- Preserved `OrbitalDynamics.Schema.validate_artifact/2` and
  `OrbitalDynamics.Schema.validation_report/2`.
- Reduced `schema.ex` from 13,534 to 13,513 lines and the snapshot contract
  module from 261 to 209 lines.
- Published implementation commit `6fd0cb7e`.

Verification:
- Focused snapshot/contact-feedback/schema-export tests: 9 passed, 180 excluded.
- Runtime probes preserved exact paths for stale `activity_count`, derived status
  counts, model limits, provider trust context, and nested activity status.
- Full schema export left `schemas/` unchanged.
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers` confirms the schema facade is the sole snapshot-contract
  caller; aggregation remains shared by the intended runtime/export modules.
- `mix format --check-formatted`, `git diff --check`, and callback-residue search
  passed.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Next candidate:
Plan-delta callback ownership cleanup after its activity-context dependency is
made direct. The snapshot work unblocked direct realized-activity composition,
and schema-contract, timeline-link, uncertainty, primitive, and stable-ID support
already have cohesive modules.

Deferred:
- Plan delta still composes callback-driven `ActivityContextContracts`; removing
  only the realized-activity callback would leave the ownership seam intact.
- Result-artifact validation remains blocked on facade-owned nested execution
  report validation.
- Timeline-transition application summary remains blocked on its callback-driven
  nested application-row validator.
- Branch events, approval requirements, quality/readiness gates, campaign
  planning/strategy, and resource-projection rows remain deferred because they
  compose facade-owned contextual or nested artifact validation.

Last published ledger:
`35d6bed2` (`Update refactor ledger after operational feedback cleanup`).

Blocked:
No.
