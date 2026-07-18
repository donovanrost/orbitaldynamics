# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-ID encoding policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move Timeline's remaining activity-ID encoding clause into the existing
`Timeline.ActivityIdentityPolicy`. `Timeline` retains one private entry point
and passes its existing artifact value encoder explicitly; other identity
facades and public coordinators remain unchanged.

Why this slice:
The 6,250-line Timeline facade still owns one exclusive identity leaf while
timeline, subject, and source-window identity behavior already belongs to
`ActivityIdentityPolicy`. Moving the final ID encoder completes that
responsibility boundary without changing normalization or identity derivation.

Planned proof:
- Focused operational-row, reusable transition, and unchanged public diff
  examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the moved clause after normalizing only the
  public/private head, facade name, and explicit encoding callback.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline optional activity-input policy extraction, selected in `cd27ded1` and
implemented in `fb8a47fa`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
