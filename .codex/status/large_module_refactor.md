# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Handoff property schema-provider extraction.

Status:
Completed and verified.

Selected boundary:
Move link, feedback-maneuver, and thermal handoff property builders from the
public `Schema` facade into a new `HandoffSchemaProviders` owner. Build one lazy
handoff context and pass its three closures to the extracted operator/cadence
review owners.

Selection evidence:
- The public `Schema` facade remains 934 lines.
- All three helpers are consumed only as callbacks by the extracted
  operator/cadence review owners.
- Their shapes already belong to focused handoff JSON-schema modules.
- The owner needs only the stable-ID pattern and common probability fragment.

Implementation:
Selected in `70b42ade` and implemented in `bbab975b`. Added the 24-line
`HandoffSchemaProviders` owner with three lazy link/feedback/thermal property
closures and passed them to the extracted operator/cadence review owners. The
public `Schema` facade moved from 934 to 925 lines.

Verification:
- Exact comparison passed for all three handoff-provider keys and outputs.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `HandoffSchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,129 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Handoff property schema-provider extraction, selected in `70b42ade` and
implemented in `bbab975b`. The public `Schema` facade moved from 934 to 925
lines.

Next candidate:
Audit the remaining public facade responsibilities and select the next bounded
extraction only where ownership remains misplaced.

Blocked:
No.
