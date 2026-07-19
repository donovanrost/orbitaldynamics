# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract approval requirements, policy-decision evidence, policy escalations,
policy decisions, rule matches, and policy bundles into
`OrbitalDynamics.Schema.PolicyValidation`. Preserve the existing arity-3 and
arity-4 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,963 lines; the selected policy-validation seams span
  6,643-6,661, 6,720-6,736, and 6,759-6,790.
- The cluster has one responsibility: validate nested and standalone policy
  evidence consumed by campaign, resource, import, and review contracts.
- Policy model limits and field groups remain shared facade/export data and can
  be passed into the new validator without moving their ownership.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused policy baselines, exact old/new fixture validation reports,
strict compile, broader Schema contract tests, JSON Schema export checks,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema decision-support validation consolidation, selected in `57f70207` and
implemented in `88aa3c57`. `schema.ex` moved from 6,972 to 6,963 lines; the
existing owner moved from 59 to 103 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after policy
validation has one production owner.

Blocked:
No.
