# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy activity-feasibility matcher extraction.

Status:
Selected; implementation has not started.

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
Pending: focused activity target/direction/provenance/spacecraft/station
baselines, exact old/new activity decision proofs, strict compile, full Policy
tests, relevant schema/contracts, static single ownership, runtime xref, and
bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy branch-event matcher extraction, selected in `cac7d7d9` and implemented
in `62a73bed`. `policy.ex` moved from 4,652 to 4,378 lines; the dedicated matcher
is 289 lines.

Next candidate:
Re-inventory Policy requirement-rule matching after all risk/event/activity
families have dedicated owners.

Blocked:
No.
