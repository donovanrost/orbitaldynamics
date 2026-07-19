# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy activity-feasibility matcher extraction.

Status:
Completed and pushed in `2afb9c0b`.

Selected boundary:
Extract `approval_rule_feasibility_match?/2`, activity provenance/context,
direction, station/spacecraft/target matching, and activity evidence accessors
into `OrbitalDynamics.Policy.ActivityMatcher`. Preserve private Policy seams
used by decision matching and rule-match evidence construction; reuse the
existing normalized direction predicate and RequirementContext helpers.

Selection evidence:
- `policy.ex` is now 4,378 lines; the selected continuous activity matcher spans
  161 lines at 3,795-3,955.
- The cluster has one responsibility: decide whether one normalized candidate
  activity/feasibility record satisfies one rule and expose the exact activity
  fields recorded in match evidence.
- It depends only on maps/lists, RiskMatcher's shared direction predicate, and
  RequirementContext normalization helpers.
- Policy bundles, requirement/risk/event matching, decision orchestration,
  escalation, fallback classification, and public APIs remain outside the
  boundary.

Verification:
- Strict warnings-as-errors compile passed across 3,850 files.
- Four focused activity target/direction/provenance/spacecraft/station tests
  passed.
- All 89 Policy tests passed.
- The Policy schema-contract test passed.
- Exact old/new comparison passed for 55 built-in bundle/activity decisions
  spanning top-level and nested feasibility direction, identity, status, and
  feedback provenance evidence.
- Static search confirms one activity matcher owner with seven explicit private
  Policy seams; three now-unused cross-family normalization seams were retired.
- Runtime xref confirms Policy owns the dependency on ActivityMatcher.
- Formatting, diff checks, and bounded review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy activity-feasibility matcher extraction, selected in `8b078935` and
implemented in `2afb9c0b`. `policy.ex` moved from 4,378 to 4,220 lines; the
dedicated matcher is 168 lines.

Next candidate:
Re-inventory Policy requirement-rule matching after all risk/event/activity
families have dedicated owners.

Blocked:
No.
