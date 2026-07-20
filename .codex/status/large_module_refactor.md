# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner recommendation-pressure scenario fixture extraction.

Status:
Completed and verified.

Selected boundary:
Move the deterministic prior-plan and multi-pressure strategy scenario from the
4,705-line recommendation-pressure test into a named CampaignPlanner
test-support fixture owner. Keep every recommendation, handoff, import, and
schema assertion in the existing test module.

Selection evidence:
- The test's scenario construction occupies lines 11-1,660 and produces only
  the `artifact` consumed by the remaining assertions.
- Its 3,000-plus assertion lines independently verify recommendation
  explanations, review/import handoffs, ordering, and schema contracts.
- A fixture owner separates input construction from contract verification
  without splitting or weakening the end-to-end assertion flow.

Implementation:
Selected in `1eee5dbc` and implemented in `c0678ba9`. Added the 1,658-line
`StrategyRecommendationPressureEventsFixture` owner and replaced the embedded
scenario with one fixture call. The assertion module moved from 4,705 to 3,060
lines. Two zero-float patterns now spell `+0.0` explicitly, preserving their
existing positive-zero match semantics while satisfying the strict warning
gate.

Verification:
- The exact recommendation-pressure end-to-end test passed with warnings as
  errors: 1 test.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format checks, new-helper whitespace checks, and
  `git diff --check` passed.
- No production or checked-in schema-export files changed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner recommendation-pressure scenario fixture extraction, selected
in `1eee5dbc` and implemented in `c0678ba9`. The assertion module moved from
4,705 to 3,060 lines and the deterministic scenario now has a named fixture
owner.

Next candidate:
Inspect the 3,060-line recommendation assertion module for cohesive
recommendation, handoff, and schema-verification sections that can become
independently focused test units without rebuilding the scenario repeatedly.

Blocked:
No.
