# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-orientation context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move pointing and attitude context-map construction into one dedicated
orientation context module. Keep two private Timeline facades and pass the
existing stable-ID pattern as data for target validation.

Selection evidence:
- Pointing owns mode/target/boresight/angles/rate/error/status/model/source and
  confidence; attitude owns mode/target/Euler angles/error/status/model/source
  and confidence.
- The builders have three total context-coordinator call sites and share only
  field, numeric, stable-identifier, and compact-map dependencies.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should materially reduce the current 5,662-line Timeline.
- Observation quality, lighting, thermal, product, resource, broad context
  coordination, public API, and schema remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-product delivery context extraction, selected in `81be7c14`
implemented in `a7ffe1da`, and handed off in `ac27cc44`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
