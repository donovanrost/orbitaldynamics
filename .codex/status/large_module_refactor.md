# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline terminal-exception classification policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move the terminal-exception row classifier into
`Timeline.TerminalExceptionPolicy`. `Timeline` retains one private entry point
and passes the existing terminal-status list and provider-result failure
predicate explicitly; provider-result normalization remains in its current
module.

Why this slice:
The 6,226-line Timeline facade still owns one exclusive OR-chain classifier
covering terminal statuses, explicit action reasons, and contact/command result
failures. Isolating it preserves the previously deferred callback boundary
without moving provider-result interpretation or report assembly.

Planned proof:
- Focused cancelled/rejected terminal statuses, provider failure aliases, and
  provider failure maps examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the moved definition after normalizing only the
  public/private head, facade name, terminal-status argument, and callback.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline diff protection-context policy extraction, selected in `de7c4f8f` and
implemented in `30c111c7`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
