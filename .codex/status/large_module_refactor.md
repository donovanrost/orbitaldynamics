# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness-report callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 15-entry callback bag in `OperationalReadinessReportContracts` with
direct primitive, collection, stable-ID, classification, and evidence-count
owners; pass model limits as data and retain only explicit gate/evidence row
validator boundaries.

Why this slice:
Live inventory leaves `schema.ex` at 11,827 lines. The 171-line readiness-report
owner still receives 15 opaque entries even though classification and evidence
aggregation now have direct extracted owners. The remaining real composition
boundaries are the gate and evidence row validators; expressing those directly
avoids a wide replacement dependency object.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every readiness resource,
report validation path, including contract/model fields, stable IDs, capability
enums, gate/evidence rows, assumptions, model limits, classification, derived
gate counts, exact messages/error order, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_readiness_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No readiness-report callback bag or lookup/apply trampolines remain; direct
shared owners and explicit model data preserve report composition while only
gate/evidence validators remain injected; focused, broader, and export checks
pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-readiness-evidence callback collapse published as `10eb4132`:
`schema.ex` fell from 11,860 to 11,827 lines and its owner from 531 to 470. The
11-entry bag became direct primitives, exact local aggregation helpers, and two
explicit domain validator boundaries. 61 focused, 1,054 broader, and 22 export
tests passed; compile, xref, format, diff hygiene, checked-in regeneration, and
bounded review were clean.

Blocked:
No.
