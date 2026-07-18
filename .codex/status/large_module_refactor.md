# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline operational-kind classification extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move all 11 `operational_kind/1` clauses and the command/uplink direction list
into the existing `Timeline.OperationalRowClassificationPolicy`. Keep one
private Timeline facade and source the identical direction list from the policy
for capability metadata and command-row classification.

Selection evidence:
- The ordered clauses own command, health-check, observation, maneuver,
  attitude, coast, direction-based command, contact-type, ground-station, and
  generic activity classification.
- `operational_kind/1` has one runtime call site in operational row construction.
- The direction list has two existing Timeline consumers: capability metadata
  and command-row classification; both can retain the same module attribute
  sourced from the policy.
- The extraction should replace roughly 23 classifier lines with one thin
  facade, reducing the current 5,970-line Timeline without callbacks.
- Cadence import status, required actions, normalization, row construction,
  public API, and schema logic remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused and full
Timeline tests, schema-contract tests, canonical AST and constant equivalence,
static ownership/facade/public-definition/xref checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline duplicate-identity annotation extraction, selected in `bbc879ed` and
implemented in `6c6b6a86`, and handed off in `21ad7ef3`.

Next candidate:
Implement and verify this selected boundary before remapping the reduced
Timeline facade.

Blocked:
No.
