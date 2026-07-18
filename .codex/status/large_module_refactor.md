# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline integrity-count policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move total timeline-integrity issue counts, unique issue types, issue-type
frequencies, dependency issue counts, and exclusivity issue counts into
`Timeline.IntegrityCountPolicy`; dependency/exclusivity type classifiers become
policy-internal. `Timeline` retains five private entry points; list extraction
and count-map sorting cross the boundary explicitly.

Why this slice:
The 6,272-line Timeline facade still owns nine exclusive aggregate/classifier
clauses shared by operational, review, transition-application, and integrity
summary surfaces. Moving them together isolates missing-count defaults, type
flattening, frequency sorting, map/type guards, and dependency/exclusivity
substring classification without extracting report coordinators.

Planned proof:
- Focused dependency/exclusivity review, public integrity summary, and selected
  transition integrity examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all nine moved clauses after normalizing only
  public/private heads, list/sort callbacks, and internal classifier callback
  routing.
- Format, diff, whitespace, ownership, exactly-five-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-state input policy extraction, selected in `36dabe24`,
implemented in `b1a9a980`, and handed off in `9e95a77d`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
