# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection activity evidence validation extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract completed-fraction, station-capacity, latency, resource-quantity, and
nested actual-data-volume evidence validation into
`OrbitalDynamics.ResourceProjection.ActivityInputValidation`. Centralize the
advertised actual-data-volume evidence paths with that owner. Preserve all
public ResourceProjection report and flow-summary facades.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 2,418
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 822-1,042 and exclusively owns four
  validation decisions and their evidence discovery.
- Activity-input normalization is the only consumer of the validation entry
  points; actual-volume projection also consumes the shared evidence paths.
- Activity identity/type normalization, source-window normalization, resource
  arithmetic, flow construction, approval policy, public clauses, and artifact
  contracts remain outside this boundary.
- Existing top-level/metadata/model/source precedence, recursive capacity
  evidence discovery, first-error ordering, unit-interval/percent bounds,
  non-negative latency/resource guards, nil handling, numeric-string parsing,
  path presence semantics, exact reason strings, and path metadata must remain
  unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar reservation summary-value extraction, selected in `162c6a73`
and implemented in `def426ce`.
`communications/station_calendar.ex` moved from 2,425 to 2,268 lines; the
dedicated reservation-summary values owner is 210 lines.

Next candidate:
Complete and verify the selected ResourceProjection activity evidence
validation extraction.

Blocked:
No.
