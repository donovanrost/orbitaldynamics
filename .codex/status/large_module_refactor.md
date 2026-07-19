# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy validation extraction.

Status:
Completed and published.

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
- Strict compile passed across 3,865 files with warnings as errors.
- Focused policy and contact-feedback contracts passed: 6 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 9 valid and mutated standalone
  and nested policy fixtures.
- Static inspection confirms the facade retains only its arity-3/arity-4 seams
  plus shared model/field-group inputs; runtime xref reports `Schema` as the
  sole caller of the new owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema policy validation extraction, selected in `253ec596` and implemented in
`e207f932`. `schema.ex` moved from 6,963 to 6,950 lines; the dedicated owner is
76 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after policy
validation has one production owner.

Blocked:
No.
