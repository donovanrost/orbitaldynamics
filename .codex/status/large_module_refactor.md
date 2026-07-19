# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource validation extraction.

Status:
Selected; implementation has not started.

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
Pending: focused resource/filter baselines, exact old/new fixture validation
reports, strict compile, broader Schema contract tests, schema export checks,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema optional decision-support validation extraction, selected in `5a801498`
and implemented in `27959afb`. `schema.ex` moved from 7,119 to 7,110 lines; the
dedicated owner is 59 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after resource
validation has one production owner.

Blocked:
No.
