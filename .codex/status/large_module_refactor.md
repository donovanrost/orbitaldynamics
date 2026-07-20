# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner recommendation-pressure handoff test split.

Status:
Completed and verified.

Selected boundary:
Move the downstream operator-review, Cadence-import, and schema handoff
assertions from the 3,060-line recommendation-pressure assertion test into a
focused sibling test module. Reuse the deterministic scenario fixture from both
tests and keep the recommendation-explanation assertions in the original.

Selection evidence:
- The handoff section begins at `expected_handoff` and depends only on the
  shared scenario artifact.
- It independently verifies exhaustive field propagation through the strategy
  recommendation review row, selected import row, review import, nested source
  row, and both schema validators.
- The original section independently verifies the recommendation explanation
  and risk-pressure mappings.

Implementation:
Selected in `b603830b` and implemented in `1844e795`. Moved the exhaustive
expected-handoff map plus review/import/schema assertions into
`StrategyRecommendationPressureHandoffTest`. The original explanation test
moved from 3,060 to 1,029 lines; the focused handoff test is 2,047 lines and
both reuse the named scenario fixture.

Verification:
- Both focused recommendation-pressure tests passed with warnings as errors:
  2 tests.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format checks, new-file whitespace checks, and
  `git diff --check` passed.
- No production or checked-in schema-export files changed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner recommendation-pressure handoff test split, selected in
`b603830b` and implemented in `1844e795`. The 3,060-line assertion module became
a 1,029-line explanation test and a 2,047-line handoff test.

Next candidate:
Inspect the 2,047-line handoff test's expected-map construction versus its
review/import assertions; otherwise return to the largest schema contract test
boundary.

Blocked:
No.
