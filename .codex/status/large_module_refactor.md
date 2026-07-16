# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection-report callback-bag collapse.

Status:
Complete and published.

Selected slice:
Replace the 20-entry callback bag in `ResourceProjectionReportContracts` with
direct shared owners, explicit model/model-limit values, and five nested domain
validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,533 lines. The 259-line report owner and
its sole Schema caller route 13 shared operations and two static values through
lookup; only subsystem assumptions, two invalid-input rows, projected rows, and
derived counts remain genuine Schema composition hooks.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, every resource-projection report
field, allowed models/model limits, invalid/projected rows, derived counts,
exact paths/messages/order, report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- full resource-projection and focused schema/report/replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No resource-projection-report callback bag or lookup/apply trampolines remain;
direct shared owners preserve validation while model values and five domain
validators remain explicit inputs; focused, broader, and export checks pass;
and bounded review finds no blocker.

Outcome:
`schema.ex` fell from 11,533 to 11,513 lines and the report owner from 259 to
172. The 20-entry bag became direct primitive, stable-ID, and collection calls,
explicit model/model-limit values, and five typed domain-validator arguments.
214 focused, 1,167 broader, and 22 export tests passed; compile, xref,
checked-in regeneration, format, diff hygiene, and bounded review were clean.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Resource-projection-report callback-bag collapse; publication commit pending.

Blocked:
No.
