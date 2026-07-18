# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline operational-kind classification extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved all 11 `operational_kind/1` clauses and the command/uplink direction list
into the existing `Timeline.OperationalRowClassificationPolicy`. Timeline keeps
one private facade and sources the identical direction list from the policy for
capability metadata and command-row classification. Timeline is now 5,950 lines;
the classification policy is 41 lines.

Published commits:
Selected in `54c846d6` and implemented in `c51daf17`.

Verification:
- Strict warnings-as-errors compile passed across 3,787 files.
- Three focused station-ID, provider-contact, and activity-type classification
  examples passed before and after extraction.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for all 11 ordered clauses and the direction
  constant after normalizing only public/private definition kind.
- Format, diff, whitespace, exactly-one-facade, exactly-eleven-policy-clause,
  direction-consumer, unchanged Timeline public-definition,
  sole-production-consumer, and xref checks passed.
- Independent read-only review found no production-code issues and confirmed
  exact clause precedence, type/direction/contact/ground-station behavior,
  direction metadata, command-row use, and the sole operational-row call site.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline operational-kind classification extraction, selected in `54c846d6` and
implemented in `c51daf17`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
