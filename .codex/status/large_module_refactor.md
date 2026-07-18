# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline duplicate-identity annotation extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved duplicate timeline-identity group detection, row mapping, collision
annotation fields, superseded action preservation, and compact-map cleanup into
the 45-line `Timeline.DuplicateTimelineIdentityAnnotation`. The 5,970-line
Timeline retains one private facade used by operational reports, normalized
activity lists, and diff preparation.

Published commits:
Selected in `bbc879ed` and implemented in `6c6b6a86`.

Verification:
- Strict warnings-as-errors compile passed across 3,787 files.
- Three focused operational-report, normalized-list, and diff-propagation
  duplicate-identity examples passed before and after extraction.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for both moved definitions after normalizing
  only the public coordinator name and public/private definition kind.
- Format, diff, whitespace, exactly-one-facade, three-call-site, singular-helper
  removal, unchanged Timeline public-definition, sole-production-consumer, and
  xref checks passed.
- Independent read-only review found no production-code issues and confirmed
  exact grouping/filtering, row order, passthrough, activity-ID preservation,
  annotation fields, superseded values, replacement actions, and compaction.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline duplicate-identity annotation extraction, selected in `bbc879ed` and
implemented in `6c6b6a86`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
