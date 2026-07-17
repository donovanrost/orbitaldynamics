# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planner branch event/state application extraction.

Status:
Selected.

Selected slice:
Extract branch plan-event and realized-event application, their station/capacity
and realized-state merge helpers, into `CampaignPlanner.BranchEventApplication`.
Consolidate station identity through the existing `BranchEventNormalizer`.

Why this slice:
The cluster owns how branch events mutate prior-plan candidates and realized
state, including station matching, reduced capacity, missed/delayed activities,
spacecraft degradation, and deterministic state merging. Moving both sides
together avoids a broad callback bag. Degraded mode/spacecraft helpers remain
explicit internal functions for branch-refresh summaries, and station identity
can reuse the existing normalizer instead of remaining duplicated.

Public facade to preserve:
All `OrbitalDynamics.CampaignPlanner` public functions, exact branch/event
artifacts, deterministic ordering, source paths, approval statuses, and trust
boundaries.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/branch_event_normalizer.ex`
- new `lib/orbital_dynamics/campaign_planner/branch_event_application.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused ground-station, degraded-spacecraft, maneuver, reduced-capacity, and
  branch-feedback tests
- deterministic strategy regression coverage
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The planner delegates plan and realized-state event application and state merges
to one internal module; event order, matching, statuses, reasons, capacity
math, degradation fields, and deterministic merge ordering remain exact;
focused tests pass; and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Campaign-planner branch candidate-plan staging published as `f071d63f`: all
four staged event families, replacement helpers, warnings, and deterministic
ordering now live in one cohesive internal module, 77 focused/regression tests
passed, and bounded review found no finding.

Next candidate:
After this slice, refresh the live CampaignPlanner hotspot and select another
explicit cluster only if it improves ownership without widening callbacks.

Blocked:
No.
