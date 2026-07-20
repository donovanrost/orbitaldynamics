# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station-calendar schema-provider extraction.

Status:
Completed and pushed.

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
Selected in `5ec99bb8` and implemented in `9b22678f`.
The new `StationCalendarSchemaProviders.build/2` returns seven lazy provider
closures and owns the source-entry/contention-pair helper chain. `Schema`
removes the seven registry-local captures and nine private builders, then
passes negotiation and policy schema functions as explicit callbacks when
merging the focused provider map.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- Direct comparison confirmed the extracted provider map has the exact seven
  keys and produces outputs exactly equal to the original helper composition,
  including both internal helper chains.
- Xref reports one runtime edge from `Schema` to the new provider owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,110 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,887 to 1,813 lines; the new focused
  owner is 106 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Station-calendar schema-provider extraction, selected in `5ec99bb8` and
implemented in `9b22678f`. The public `Schema` facade moved from 1,887 to 1,813
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
