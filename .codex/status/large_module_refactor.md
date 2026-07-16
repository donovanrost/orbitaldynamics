# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-activity-lifecycle-state callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the 16-function lifecycle-state facade bag and all callback arguments
  and application wrappers from `TimelineActivityLifecycleStateContracts`.
- The family now directly uses primitive, collection, stable-ID,
  lifecycle-transition, activity-context, and protection-decision modules;
  timeline report model limits remain explicit inputs.
- Preserved `OrbitalDynamics.Schema.validate_artifact/2` and
  `OrbitalDynamics.Schema.validation_report/2`.
- Reduced `schema.ex` from 13,358 to 13,326 lines and lifecycle-state contracts
  from 589 to 485 lines.
- Published implementation commit `c5119bde`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Status-state, approval-state, lifecycle-state, deterministic bundle, and
  checked-in export coverage: 5 passed, 7 excluded.
- Focused public-facade coverage preserved exact model-limit, transition,
  action, reason, type, stable-ID, activity-context, and protection diagnostics.
- Full schema export left `schemas/` unchanged; contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run; focused lifecycle-state/export coverage was used for this
  behavior-preserving boundary cleanup.

Next candidate:
- Timeline-preservation callback ownership cleanup. Its four schema-only call
  sites and 19 callbacks map to primitive, aggregation, collection, stable-ID,
  timeline-identity, and row-validation owners; timeline report model limits
  can be passed explicitly. Starting module size is 629 lines.

Blocked:
No.
