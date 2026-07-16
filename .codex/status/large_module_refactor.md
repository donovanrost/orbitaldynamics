# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness-gate callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 10-entry callback bag in `OperationalReadinessGateContracts` with
direct primitive and readiness-context owners while retaining the timeline-
publication validator as the sole explicit orchestration boundary.

Why this slice:
Live inventory leaves `schema.ex` at 11,779 lines. The 114-line gate owner still
receives five shared primitive callbacks and four callbacks that merely route
to the now-direct readiness-context owner. Only timeline-publication validation
remains a genuine Schema orchestration hook.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every readiness gate/report
validation path, including required fields, capability enums, reason typing,
optional analysis fields, resource/operator/adapter/Cadence/timeline context,
exact messages/error order, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_readiness_gate_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No readiness-gate callback bag or lookup/apply trampolines remain; direct
primitive/context owners preserve validation composition and only the timeline
validator remains injected; focused, broader, and export checks pass; and
bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-readiness-report callback collapse published as `9d6a8856`:
`schema.ex` fell from 11,827 to 11,779 lines and its owner from 171 to 115. The
15-entry bag became direct shared owners, explicit model data, and two row
validator boundaries. 61 focused, 1,054 broader, and 22 export tests passed;
compile, xref, format, diff hygiene, checked-in regeneration, and bounded review
were clean.

Blocked:
No.
