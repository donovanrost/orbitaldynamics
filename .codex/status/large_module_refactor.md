# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection-flow-row callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 9-entry callback bag in `ResourceProjectionFlowRowContracts` with
direct primitive/stable-ID owners while retaining explicit source-window and
nested-ID-match validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,612 lines. The 192-line flow-row owner
and its sole Schema caller route seven shared operations through lookup; only
source-window and nested-ID matching are genuine Schema composition hooks.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, resource-projection flow-row
stable IDs, source-window identity, lists/probabilities/numbers, latency and
resource-effect statuses, exact paths/order, report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_flow_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused resource-projection flow/report, schema, replay, and operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No resource-projection-flow-row callback bag or lookup/apply trampolines remain;
direct shared owners preserve validation while the two Schema domain validators
remain explicit boundaries; focused, broader, and export checks pass; and
bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Station-calendar-provider callback-bag collapse published as `5f09992f`:
`schema.ex` fell from 11,627 to 11,612 lines and its owner from 250 to 226. The
9-entry bag became direct shared validators and local error ownership. 179
focused, 1,167 broader, and 22 export tests passed; compile, xref, format, diff
hygiene, checked-in regeneration, and bounded review were clean.

Blocked:
No.
