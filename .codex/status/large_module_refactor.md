# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation validation extraction.

Status:
Selected; implementation has not started.

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
Pending: focused contact-allocation baselines, exact old/new fixture validation
reports, strict compile, broader Schema contract tests, schema export checks,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema resource validation extraction, selected in `94eed8dd` and implemented
in `6d042e72`. `schema.ex` moved from 7,110 to 7,040 lines; the dedicated owner
is 139 lines.

Next candidate:
Re-inventory remaining Schema station-summary and family-validation clusters
after contact-allocation validation has one production owner.

Blocked:
No.
