# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-rejection-report callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the 23-function candidate-rejection facade bag and all callback
  arguments/wrappers from `CandidateRejectionReportContracts`.
- The family now directly uses primitive, collection, aggregation, stable-ID,
  and activity-context modules; model limits remain an explicit input.
- Preserved `OrbitalDynamics.Schema.validate_artifact/2` and
  `OrbitalDynamics.Schema.validation_report/2`.
- Reduced `schema.ex` from 13,388 to 13,358 lines and candidate-rejection
  contracts from 580 to 453 lines.
- Published implementation commit `fabbdd08`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Candidate-rejection contracts, curated report fixture, and schema-export
  coverage: 5 passed, 180 excluded.
- Runtime probes preserved exact row/model-limit/reason-count diagnostics,
  supported-reason and action-derived maps, reason-indexed ID sets, and optional
  source-row activity-context validation.
- Full schema export left `schemas/` unchanged; contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run; focused rejection/export coverage was used for this
  behavior-preserving boundary cleanup.

Next candidate:
Timeline-activity-lifecycle-state callback ownership cleanup. Its 16 callbacks
now map to primitive/stable-ID support plus direct lifecycle-transition,
activity-context, and protection-decision modules; timeline model limits can be
passed explicitly. Starting module size is 589 lines.

Blocked:
No.
