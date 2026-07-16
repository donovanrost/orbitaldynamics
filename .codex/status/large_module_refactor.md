# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection report-count message restoration.

Status:
Selected; implementation pending.

Selected slice:
Restore the five generic equality messages lost when
`ResourceProjectionReportCountContracts` moved from Schema's `/5` equality
facade to the primitive `/5` function.

Why this slice:
The flow-row verification exposed three failures in the full resource-
projection file. Git history identifies `7e015529` as the regression: Schema's
`/5` facade emitted `must equal <expected>`, while the primitive `/5` default
emits a nil message. Two additional unasserted call sites share the defect.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, resource-projection report count
paths, expected values, exact `must equal <expected>` messages and issue order,
report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema/resource_projection_report_count_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- full resource-projection and focused schema/report tests
- broader candidate-refresh/operator-review regression if shared code changes
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
All five former `/5` equality calls use the primitive `/6` form with the exact
legacy generic message; the full resource-projection file and export checks
pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.
- Full resource-projection file currently remains 211/214 due the selected
  report-count message regression.

Last completed slice:
Resource-projection-flow-row callback-bag collapse published as `f65244f9`:
`schema.ex` fell from 11,612 to 11,599 lines and its owner from 192 to 135. The
9-entry bag became direct shared validators and two domain boundaries. 174
targeted, 1,167 broader, and 22 export tests passed; compile, xref, format,
diff hygiene, checked-in regeneration, and bounded review were clean.

Blocked:
No.
