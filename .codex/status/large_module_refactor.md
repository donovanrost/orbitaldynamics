# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-product delivery context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move the activity product/delivery context builder plus collection end,
planned/actual delivery, maximum/planned/actual latency, and planned/actual data
volume helpers into a dedicated context module. Keep one private Timeline
context facade and remove the eight helper facades.

Selection evidence:
- The builder exclusively consumes all eight adjacent timing/data-volume
  helpers and owns delivery IDs/status, latency deltas/margin, priority, and
  objective linkage.
- Existing delivery timing, field value, numeric value, relationship ID,
  metric delta, stable identifier, and encoding policies provide the boundary
  directly without Timeline callbacks.
- The extraction should materially reduce the current 5,792-line Timeline.
- Observation quality, pointing, attitude, thermal, resource, broad context
  coordination, public API, and schema remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-thermal context extraction, selected in `20d57037`,
implemented in `df9621d1`, and handed off in `6db09840`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
