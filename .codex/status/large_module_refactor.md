# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-readiness validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract operational-readiness, operational-summary, and quality-gate validator
orchestration plus their model-limit providers into
`OrbitalDynamics.Schema.OperationalReadinessValidation`. Preserve the existing
private `Schema` validator seams as thin delegates so contract dispatch and
callback wiring remain unchanged.

Selection evidence:
- The refreshed production ranking places `schema.ex` first at 7,293 lines;
  `policy.ex` is now 1,507 lines and no longer a leading hotspot.
- The selected model-limit providers span lines 3,062-3,131 and the validator
  family spans 6,742-6,886.
- The cluster has one responsibility: orchestrate executable validation for
  operational-readiness and quality-gate artifact families.
- Its dependencies are existing family contract modules, OperationalReadiness
  capabilities, and callbacks wholly owned by the selected family.
- Registry data, JSON Schema export, contract dispatch, Cadence row validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused operational/readiness contract baselines, exact old/new fixture
validation reports, strict compile, broader Schema contract tests, schema export
checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy approval-policy normalizer extraction, selected in `34b34b50` and
implemented in `b1d4a27a`. `policy.ex` moved from 2,119 to 1,507 lines; the
dedicated normalizer is 656 lines.

Next candidate:
Re-inventory remaining Schema JSON-property and family-validation clusters
after operational-readiness validation has one production owner.

Blocked:
No.
