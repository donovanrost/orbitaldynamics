# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station-calendar schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the seven station-calendar/reservation provider builders and their two
private source-entry/contention-pair helpers from the public `Schema` facade
into a new `StationCalendarSchemaProviders` owner. Merge its lazy provider map
into the existing property context and pass policy/negotiation dependencies as
callbacks.

Selection evidence:
- The public `Schema` facade remains 1,887 lines.
- These nine contiguous private builders form a roughly 75-line
  station-calendar/reservation schema cluster.
- Seven are referenced only by the property provider registry; the source
  entry and contention pair are used only inside the same cluster.
- The owner can preserve laziness by accepting the existing negotiation and
  policy schema builders as callbacks.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Validation schema-provider extraction, selected in `bd0109e1` and implemented
in `f5050011`. The public `Schema` facade moved from 1,917 to 1,887 lines.

Next candidate:
Implement and verify the selected station-calendar provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
