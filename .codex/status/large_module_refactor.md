# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-template provenance extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved activity-template context wrapping, provenance validation/field selection,
operational-hint normalization, and number/boolean/string hint insertion into a
118-line `Timeline.ActivityTemplateProvenancePolicy`. The 5,861-line Timeline
retains two private facades for provenance and context, including the existing
activity-precondition callback.

Published commits:
Selected in `4151821b` and implemented in `43f3319f`.

Verification:
- Strict warnings-as-errors compile passed across 3,788 files.
- Two focused template validation/normalization and operational-context
  examples passed before and after extraction.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for all 12 moved clauses after normalizing
  only public/private definition kind.
- Format, diff, whitespace, exactly-two-facade, internal-helper-removal,
  consumer/callback, unchanged Timeline public-definition,
  sole-production-consumer, and xref checks passed.
- Independent read-only review found no production-code issues and confirmed
  exact validation gates, field selection, hint normalization/insertion order,
  numeric/boolean/string behavior, adapters, consumers, and callback wiring.
  Nonempty binary confirmation status remains trimmed exactly as in the baseline.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-template provenance extraction, selected in `4151821b` and
implemented in `43f3319f`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
