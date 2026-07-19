# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation validation extraction.

Status:
Completed and published in `90c1d4c3`.

Selected boundary:
Extract contact-allocation report, row, capacity-pack group, count,
duplicate-evidence, and five summary-family validators into
`OrbitalDynamics.Schema.ContactAllocationValidation`. Preserve existing private
Schema seams and pass the shared domain-callback bundle explicitly.

Selection evidence:
- `schema.ex` is 7,040 lines; report/row/group validation spans 5,915-5,952 and
  count/summary validation spans 6,357-6,422.
- The cluster has one responsibility: orchestrate executable contact-allocation
  validation across report and summary artifact families.
- Its only facade-owned dependency is the existing contact-allocation domain
  callback bundle; model limits can be read directly from capabilities.
- Registry data, JSON Schema export, contract dispatch, station-summary
  validation, and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,861 files with warnings as errors.
- All 9 focused contact-allocation tests passed.
- All 175 split Schema contract tests passed with warnings as errors.
- All 15 JSON-export contract tests passed.
- Exact old/new executable comparison passed for 12 valid and intentionally
  invalid checked-in contact-allocation artifacts.
- Static ownership confirms one contact-allocation validation owner with the
  existing domain-callback bundle passed through preserved private Schema seams.
- Runtime xref, format, diff checks, and bounded review passed.
- `schema.ex` moved from 7,040 to 7,037 lines; the new owner is 118 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema contact-allocation validation extraction, selected in `c862c76e` and
implemented in `90c1d4c3`. `schema.ex` moved from 7,040 to 7,037 lines; the
dedicated owner is 118 lines.

Next candidate:
Re-inventory remaining Schema station-summary and family-validation clusters
after contact-allocation validation has one production owner.

Blocked:
No.
