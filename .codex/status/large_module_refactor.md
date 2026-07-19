# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema decision-support validation consolidation.

Status:
Completed and published.

Selected boundary:
Move maneuver recommendation/review validation and optional objective
tradeoff/satisfaction validation into the existing
`OrbitalDynamics.Schema.DecisionSupportValidation` owner. Preserve the
existing arity-2 and arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,972 lines; the selected contiguous cluster spans
  6,021-6,065.
- The cluster has one responsibility: validate maneuver and objective
  decision-support evidence.
- Maneuver model limits remain shared facade/export data, while objective
  registry dispatch can be supplied as a callback to the existing owner.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,864 files with warnings as errors.
- Focused maneuver and objective contracts passed: 4 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 8 valid and mutated maneuver,
  objective, and nested campaign fixtures.
- Static inspection confirms the facade retains only its arity-2/arity-3 seams
  and a registry-dispatch callback; runtime xref reports `Schema` as the sole
  caller of the expanded owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema decision-support validation consolidation, selected in `57f70207` and
implemented in `88aa3c57`. `schema.ex` moved from 6,972 to 6,963 lines; the
existing owner moved from 59 to 103 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after decision-support
validation has one production owner.

Blocked:
No.
