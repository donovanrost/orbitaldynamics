# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection-flow-summary callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 24-entry callback bag in `ResourceProjectionFlowSummaryContracts`
with direct shared owners while retaining explicit subsystem-assumption,
projected-resource, flow-row, and derived-count validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,578 lines. The 470-line flow-summary
owner and its sole Schema caller route 20 shared operations through lookup;
only four genuine Schema composition hooks remain. Its flow-row dependency is
now already typed and callback-free.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all resource-projection flow-
summary fields, model limits, nested rows, counts, exact paths/messages/order,
report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_flow_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- full resource-projection and focused schema/report/replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No resource-projection-flow-summary callback bag or lookup/apply trampolines
remain; direct shared owners preserve validation while four domain validators
remain explicit boundaries; focused, broader, and export checks pass; and
bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Resource-projection-row callback-bag collapse published as `8d012418`:
`schema.ex` fell from 11,599 to 11,578 lines and its owner from 399 to 288. The
20-entry bag became direct shared owners and five domain-validator arguments.
214 focused, 1,167 broader, and 22 export tests passed; compile, xref,
regeneration, format, diff hygiene, and bounded review were clean.

Blocked:
No.
