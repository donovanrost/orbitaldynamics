# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection station policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved station unavailable, reservation, and reduced-capacity classification;
top-level/source status lookup; top-level/source capacity-fraction lookup; and
the three capacity field names into the 109-line
`Timeline.CandidateRejectionStationPolicy`. The 6,104-line Timeline retains
three thin private facades for the derived-reason coordinator and sources the
identical field list from the policy for existing capability metadata.

Published commits:
Selected in `68aec198` and implemented in `da7ab611`.

Verification:
- Strict warnings-as-errors compile passed across 3,784 files.
- Three focused direct-status, nested-capacity, and nested-availability
  candidate-rejection examples passed before and after extraction.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for all 11 moved clauses and the capacity
  field constant after normalizing only public/private definition kind.
- Format, diff, whitespace, exactly-three-facade, unchanged Timeline
  public-definition, sole-production-consumer, and xref checks passed.
- Independent read-only review found no production-code issues and confirmed
  exact field/token lists, lookup precedence, recursive-list behavior,
  normalization, numeric routing, capacity threshold, and metadata exposure.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline candidate-rejection station policy extraction, selected in `68aec198`
and implemented in `da7ab611`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
