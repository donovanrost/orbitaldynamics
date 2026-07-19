# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy branch-event matcher extraction.

Status:
Completed and pushed in `62a73bed`.

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
- Strict warnings-as-errors compile passed across 3,849 files.
- Seven focused event type/direction/station/spacecraft/target/provenance/status
  tests passed.
- All 89 Policy tests passed.
- The Policy schema-contract test passed.
- Exact old/new comparison passed for 55 built-in bundle/event decisions
  spanning direction, identity, status/allocation, provider calendar,
  reservation, and feedback provenance evidence.
- Static search confirms one event matcher owner with six explicit private
  Policy seams.
- Runtime xref confirms Policy owns the dependency on EventMatcher.
- Formatting, diff checks, and bounded review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy branch-event matcher extraction, selected in `cac7d7d9` and implemented
in `62a73bed`. `policy.ex` moved from 4,652 to 4,378 lines; the dedicated matcher
is 289 lines.

Next candidate:
Re-inventory the neighboring Policy activity matcher after branch-event
matching has one production owner.

Blocked:
No.
