# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Quality-gate-row callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 14-entry callback bag in `QualityGateRowContracts` with direct
primitive, stable-ID, and readiness-context owners while retaining explicit
source-gate handoff, source-report handoff, and timeline validator boundaries.

Why this slice:
Live inventory leaves `schema.ex` at 11,762 lines. The 148-line row owner still
receives seven shared primitive/stable callbacks and four callbacks that merely
route to the extracted readiness-context owner. Only the two source handoff
checks and timeline validation remain genuine Schema orchestration hooks.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every quality-gate row/report
validation path, including stable row IDs, rank and capability enums, source
handoff checks, resource/operator/adapter/Cadence/timeline context, exact
messages/error order, aggregation consumers, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/quality_gate_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No quality-gate-row callback bag or lookup/apply trampolines remain; direct
shared/context owners preserve validation and aggregation while only the two
source handoff and timeline validators remain injected; focused, broader, and
export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-readiness-gate callback collapse published as `db7d887c`:
`schema.ex` fell from 11,779 to 11,762 lines and its owner from 114 to 32. The
10-entry bag became direct primitive/context owners and one timeline boundary.
61 focused, 1,054 broader, and 22 export tests passed; compile, xref, format,
diff hygiene, checked-in regeneration, and bounded review were clean.

Blocked:
No.
