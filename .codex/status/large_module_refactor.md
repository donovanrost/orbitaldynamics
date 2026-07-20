# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Handoff property schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Common fragment schema-provider extraction, selected in `45170a81` and
implemented in `8121e5bf`. The public `Schema` facade moved from 947 to 934
lines.

Next candidate:
Implement and verify the selected handoff-property extraction, then audit the
remaining public facade responsibilities.

Blocked:
No.
