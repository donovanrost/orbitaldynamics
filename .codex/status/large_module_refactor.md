# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair activity-dispatch extraction.

Status:
Selected.

Selected slice:
Extract activity normalization/matching, realized-status derivation,
protection priority, and transition dispatch into `RepairActivityDispatch`.

Why this slice:
All transition owners are now explicit. The remaining repair-only status
attributes and dispatch helpers form a closed orchestration responsibility
that can move without callbacks while preserving condition priority.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.repair/1`, exact repaired activities, deltas,
warnings, approvals, transition choice, protection policy, and deterministic
ordering.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_activity_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- full focused repair/facade family
- normalized case/condition order and status/protection audit
- compile, format, diff hygiene, and bounded review

Definition of done:
The repair reduce delegates each activity to one dispatch owner; normalization,
realized matching/status, protection priority, transition selection, and
ordering remain exact; focused tests pass; and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
CampaignPlanner repair maneuver timing-impact extraction published as
`4d66a619`: one owner now supplies movement and downstream annotation, 17
focused tests passed, and corrected bounded review found no blocker.

Next candidate:
After activity dispatch, refresh the CampaignPlanner hotspot map and leave the
repair lane if no cohesive callback-free owner remains.

Blocked:
No.
