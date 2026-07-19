# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy branch-event matcher extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract `approval_rule_event_match?/2`, event status/allocation/station-calendar
and provenance matching, direction/identity/context matching, and event evidence
accessors into `OrbitalDynamics.Policy.EventMatcher`. Preserve private Policy
seams used by decision matching and rule-match evidence construction; reuse the
existing normalized direction predicate and RequirementContext helpers.

Selection evidence:
- `policy.ex` is now 4,652 lines; the selected continuous event matcher spans
  282 lines at 3,787-4,068.
- The cluster has one responsibility: decide whether one normalized branch
  event satisfies one rule and expose the exact event fields recorded in match
  evidence.
- It depends only on maps/lists, RiskMatcher's shared direction predicate, and
  RequirementContext normalization helpers; activity matching remains a
  separate neighboring family.
- Policy bundles, requirement/risk/activity matching, decision orchestration,
  escalation, fallback classification, and public APIs remain outside the
  boundary.

Verification:
Pending: focused event type/direction/station/spacecraft/target/provenance/status
baselines, exact old/new event decision proofs, strict compile, full Policy
tests, relevant schema/contracts, static single ownership, runtime xref, and
bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy risk-matcher extraction, selected in `27fba3ea` and implemented in
`bd14ec63`. `policy.ex` moved from 4,960 to 4,652 lines; the dedicated matcher
is 326 lines.

Next candidate:
Re-inventory the neighboring Policy activity matcher after branch-event
matching has one production owner.

Blocked:
No.
