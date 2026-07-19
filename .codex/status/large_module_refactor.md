# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state input grouping policy completion.

Status:
Selected; implementation has not started.

Selected boundary:
Move lifecycle-state input row mapping and timeline-identity grouping into the
existing `LifecycleStateInputPolicy`. Keep one facade wrapper that supplies the
three existing normalization/identity callbacks and remove its two subordinate
delegation wrappers.

Selection evidence:
- The group helper's only work is calling the two already extracted input-policy
  functions across indexed activities and grouping their results.
- `lifecycle_state_input_row/1` and `lifecycle_state_row_timeline_id/1` have no
  consumer outside that group helper and become redundant facade plumbing.
- One focused lifecycle-state summary test covers valid normalization, duplicate
  timeline identities, invalid inputs, durable identity grouping, facade parity,
  and schema validation.
- Timeline is 5,025 lines; `LifecycleStateInputPolicy` is 19 lines.
- Public Timeline APIs, summary row classification/aggregation, schema/model
  ownership, capability values, generated exports, and other lifecycle
  responsibilities remain outside the boundary.

Verification:
Pending: focused baseline, mechanical policy completion, strict compile,
focused and full Timeline tests, schema contracts, structural/static checks, and
bounded review.

Behavior/schema changes:
None intended. Input normalization, invalid-row routing, identity grouping, row
ordering, summary fields, capabilities, and schema exports should remain
byte-for-byte stable.

Last completed slice:
Timeline application identity collection policy completion, selected in
`6db5ac0d` and implemented in `2fb91b08`.

Next candidate:
Evaluate lifecycle-state summary assembly now that input grouping and row
classification have explicit policy owners.

Blocked:
No.
