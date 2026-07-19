# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource validation extraction.

Status:
Completed and published in `6d042e72`.

Selected boundary:
Extract resource-projection report/flow/row validation, resource-filter
report/suppression validation, optional wrappers, and shared invalid-input
checks into `OrbitalDynamics.Schema.ResourceValidation`. Preserve existing
private Schema seams and pass approval-requirement, policy-rule-match, and
nested-ID callbacks explicitly.

Selection evidence:
- `schema.ex` is 7,110 lines; the selected projection cluster spans
  6,004-6,094, the filter cluster spans 6,367-6,405, and projection
  model/limit providers sit at 6,481-6,500.
- The cluster has one responsibility: orchestrate executable validation for
  resource projection, flow, filter, and suppression artifacts.
- Most dependencies are existing resource contract modules; only three
  validation callbacks remain facade-owned.
- Registry data, JSON Schema export, contract dispatch, unrelated family
  validation, and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,860 files with warnings as errors.
- All 7 focused resource/filter tests passed.
- All 175 split Schema contract tests passed with warnings as errors.
- All 15 JSON-export contract tests passed.
- Exact old/new executable comparison passed for 8 valid and intentionally
  invalid checked-in resource artifacts.
- Static ownership confirms one resource-validation owner with preserved
  projection, filter, suppression, model-limit, and model-list Schema seams.
- Runtime xref, format, diff checks, and bounded review passed.
- `schema.ex` moved from 7,110 to 7,040 lines; the new owner is 139 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema resource validation extraction, selected in `94eed8dd` and implemented
in `6d042e72`. `schema.ex` moved from 7,110 to 7,040 lines; the dedicated owner
is 139 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after resource
validation has one production owner.

Blocked:
No.
