# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optional decision-support validation extraction.

Status:
Completed and published in `27959afb`.

Selected boundary:
Extract optional branch-comparison, ranking-comparison, optimizer-contract,
score-term-report, and branch-comparison source-row validation into
`OrbitalDynamics.Schema.DecisionSupportValidation`. Preserve existing private
callback arities and pass contract validation as explicit closures.

Selection evidence:
- `schema.ex` is 7,119 lines; the selected contiguous cluster spans
  6,311-6,373.
- The cluster has one responsibility: validate optional decision-support
  artifacts embedded in repair, strategy, review, and import handoffs.
- Four validators share contract dispatch; the source-row validator uses only
  primitive numeric/probability checks and its existing row-count contract.
- Registry data, JSON Schema export, contract dispatch ownership, unrelated
  family validation, and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,859 files with warnings as errors.
- All 4 focused optimizer/strategy tests passed.
- All 175 split Schema contract tests passed with warnings as errors.
- All 15 JSON-export contract tests passed.
- Exact old/new executable comparison passed for 8 valid and intentionally
  invalid checked-in decision-support reports.
- Static ownership confirms one decision-support validation owner with five
  preserved private Schema seams and explicit contract-validation closures.
- Runtime xref, format, diff checks, and bounded review passed.
- `schema.ex` moved from 7,119 to 7,110 lines; the new owner is 59 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema optional decision-support validation extraction, selected in `5a801498`
and implemented in `27959afb`. `schema.ex` moved from 7,119 to 7,110 lines; the
dedicated owner is 59 lines.

Next candidate:
Re-inventory remaining Schema resource/filter and family-validation clusters
after optional decision-support validation has one production owner.

Blocked:
No.
