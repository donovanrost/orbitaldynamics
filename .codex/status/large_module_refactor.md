# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline declared candidate-rejection reason policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move declared rejection reason collection, delimiter/list splitting, token
canonicalization, alias mapping, and allowed-reason fallback into
`Timeline.CandidateRejectionReasonPolicy`. `Timeline` retains one private entry
point and passes the existing allowed reason list explicitly; derived reason
classification and report assembly remain unchanged.

Why this slice:
The 6,264-line Timeline facade still owns a cohesive nine-clause parsing policy
for external rejection evidence. Moving the complete family isolates source
field order, recursive splitting, normalization, aliasing, and unknown fallback
without pulling derived candidate checks or summary coordinators across the
boundary.

Planned proof:
- Focused declared/derived candidate rejection, nested capacity evidence, and
  nested availability evidence examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all nine moved clauses after normalizing only
  public/private heads, facade names, and explicit allowed-reason routing.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline operational row-classification policy extraction, selected in
`f6d58e54` and implemented in `3a689cf2`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
