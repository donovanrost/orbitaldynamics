# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline core schema-provider extraction.

Status:
Completed and verified.

Selected boundary:
Move timeline identity, link, protection, uncertainty, activity-context,
candidate-source-window, cadence-import, preservation-source, and protection-
summary builders from the public `Schema` facade into a new
`TimelineCoreSchemaProviders` owner. Merge its lazy registry providers and
route remaining facade/report dependencies through public focused helpers.

Selection evidence:
- The public `Schema` facade remains 1,126 lines.
- Six builders are registry providers and the three remaining helpers feed only
  activity/report schema composition.
- The cluster is self-contained around the stable-ID pattern, common fragments,
  and `TimelineContextJsonSchema`.
- Public focused helpers can preserve lazy callback timing for downstream
  owners without facade wrappers.

Implementation:
Selected in `34f8879f` and implemented in `a9fa9e71`. Added the 84-line
`TimelineCoreSchemaProviders` owner with six lazy registry providers and three
public focused helpers, merged its registry context, and routed downstream
dependencies through the owner. Callback wiring kept the public `Schema`
facade at 1,126 lines while removing nine builder responsibilities.

Verification:
- Exact comparison passed for all six registry-provider outputs and all three
  public focused helpers.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `TimelineCoreSchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,125 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline core schema-provider extraction, selected in `34f8879f` and
implemented in `a9fa9e71`. Nine builders moved to the focused owner while the
public `Schema` facade remained 1,126 lines due to explicit callback wiring.

Next candidate:
Extract the remaining callback-heavy timeline report layer so core-owner
wiring can move out of the public facade.

Blocked:
No.
