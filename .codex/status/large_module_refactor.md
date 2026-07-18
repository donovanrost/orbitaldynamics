# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline provider-contact normalization policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move activity-type alias promotion, provider downlink inference, direction-based
contact inference, and command-feedback suppression into
`Timeline.ProviderContactNormalizationPolicy`. `Timeline` retains the three
ordered normalization entry points used by `activity_to_map/1`.

Why this slice:
The reduced Timeline facade is 7,082 lines. These eight exclusive clauses own
provider contact shape inference after direction and numeric normalization. The
boundary preserves the type-alias, inferred-downlink, then direction-contact
pipeline order.

Planned proof:
- Focused Timeline examples for type-less downlink inference, command-feedback
  suppression, direction-only command/health-check contacts, and
  activity-type-only inputs.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all eight moved clauses after normalizing only
  the three facade names.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline source-window normalization policy extraction, selected in `9f7b012d`,
implemented in `ca54e136`, and handed off in `ed199fe2`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing activity
normalization and lifecycle application.

Blocked:
No.
