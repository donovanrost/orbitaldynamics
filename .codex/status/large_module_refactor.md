# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-thermal context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move the activity thermal-context map builder and its six thermal metric
facades into a dedicated context module. Have the context call the existing
thermal-metric and scalar policies directly, keep one private Timeline context
facade, and remove the six Timeline metric facades.

Selection evidence:
- The context owns thermal zone, observed/planned/actual temperatures, delta,
  operating limits, margin, status/model/source/confidence, and compaction.
- The six thermal metric facades are consumed only by the thermal context.
- Existing thermal metric, field value, numeric value, stable identifier,
  artifact encoding, and delta policies supply all dependencies directly, so
  the extraction requires no callbacks at the Timeline boundary.
- The extraction should remove the roughly 31-line builder and six facade
  functions while adding one thin facade, materially reducing the current
  5,861-line Timeline.
- Lighting, attitude, resource, delivery timing, broad context coordination,
  public API, and schema remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused and full
Timeline tests, schema-contract tests, structural equivalence, static
ownership/facade/public-definition/xref checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-template provenance extraction, selected in `4151821b`,
implemented in `43f3319f`, and handed off in `ea9403c2`.

Next candidate:
Implement and verify this selected boundary before remapping the reduced
Timeline facade.

Blocked:
No.
