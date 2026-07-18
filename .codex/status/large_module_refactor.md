# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-field value policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move top-level/metadata field lookup, string/existing-atom key fallback, and
first numeric, numeric-or-scalar, scalar-string, provider-result-string, and
stable-identifier selection into `Timeline.ActivityFieldValuePolicy`.
`Timeline` retains seven private entry points. Numeric conversion,
provider-result artifact extraction, and stable-ID validation cross the
boundary explicitly.

Why this slice:
The reduced Timeline facade is 6,674 lines. These 10 exclusive clauses own the
shared field-selection semantics used across candidate rejection, activity
context, resource, link, dependency, exclusivity, and publication surfaces:
key precedence, metadata fallback, nil handling, scalar coercion, and stable-ID
filtering.

Planned proof:
- Focused activity-context examples covering top-level/metadata precedence,
  numeric and scalar coercion, provider-result strings, and stable identifiers.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 10 moved clauses after normalizing only the
  seven facade names and three callback boundaries.
- Format, diff, whitespace, ownership, exactly-seven-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-reference ID policy extraction, selected in `ff1f4dd0`,
corrected in `368a318e`, implemented in `b3bb5c3f`, and handed off in
`46559f51`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing lifecycle state
assembly.

Blocked:
No.
