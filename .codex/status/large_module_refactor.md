# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner V2 repair-execution boundary extraction.

Status:
Implementation published as `bb696784`; handoff publication pending.

Selected slice:
Move the state-transition phase at the start of `CampaignPlanner.do_repair/1`
and its repair-only preparation helpers into a new internal
`CampaignPlanner.RepairExecution.run/1` boundary.

Why this slice:
After the derived-branch orchestration extraction, `CampaignPlanner` is 1,894
lines. Its 144-line `do_repair/1` still directly owns the most stateful V2
responsibility: preparing source candidates, applying the station calendar,
matching realized activity state, reducing planned activities through repair
dispatch, propagating maneuver effects, and sorting execution outputs.

Current coupling/problem:
The public facade coordinates low-level V2 activity transitions even though
candidate input, realized-state, dispatch, transition, and source-report owners
already exist. Keeping that reduction in the facade obscures the boundary
between repair execution and the later approval/report/scoring/artifact phase.

Public facade to preserve:
`CampaignPlanner.repair/1`, `repair!/1`, file-backed entry points, V2 artifacts,
candidate and activity ordering, deltas, approvals, warnings, scores, reports,
metadata, deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_execution.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
`do_repair/1` delegates candidate preparation and repair state transitions to
`RepairExecution.run/1`; the facade retains approval, report, scoring, and
artifact assembly; public artifacts and errors are unchanged; focused and full
planner tests match live baseline; strict compile and independent review are
clean.

Verification gaps:
- The full planner directory retains the five previously documented failures:
  728/733 passed with the same test names, values, and stack locations.
- Independent review was clean. No code, API, artifact, determinism, ordering,
  ownership, error-behavior, or behavioral finding remains.

Tests run:
- Baseline and post-change focused repair-execution subset: 35 passed with
  warnings as errors.
- Post-change full planner directory: 728/733 passed with the same five
  documented failures and observations as the live baseline.
- Strict forced compile: 3,649 files clean with warnings as errors.
- Public `CampaignPlanner` definitions match selection commit `fec8a4f5`.
  Xref reports `CampaignPlanner` as the only runtime caller of the new owner.
- Format, tracked and new-file whitespace, and `git diff --check` passed. The
  selected repair-only helpers are absent from the facade.
- `CampaignPlanner` shrank from 1,894 to 1,802 lines. The new internal
  `RepairExecution` module is 111 lines.
- The extraction is callback-free and uses existing
  `RepairCandidateInputs`, `RepairRealizedState`, `RepairActivityDispatch`,
  `RepairManeuverTransitions`, `RepairPolicySemantics`, `RepairSourceReports`,
  and `StationCalendar` owners.
- Independent review reran the exact 35-test subset, 3,649-file compile,
  public-def, xref, formatting, diff, and new-file checks; results matched
  primary proof.

Behavior/schema changes:
None intended.

Outcome:
`do_repair/1` now delegates its candidate preparation and state-transition
phase to `RepairExecution.run/1`. The facade retains approval, reports, scoring,
and artifact assembly. Implementation published as `bb696784`.

Last completed slice:
Derived-branch generation boundary extraction published as implementation
`1841dc35` and handoff `b3be6001`: `CampaignPlanner` shrank from 2,023 to 1,894
lines; focused and full-baseline proof passed; independent review was clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.
