# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair activity-dispatch extraction.

Status:
Published as `ce902067`.

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
Added `RepairActivityDispatch` as the owner for activity normalization,
realized matching/status, protection priority, and ordered transition
selection. The repair reduce now delegates each activity directly; the three
repair-only status attributes and all dispatch helpers are gone from the
facade. The facade fell from 4,052 to 3,967 lines; the explicit 102-line owner
makes the bounded scope net +17 lines while removing 85 lines of orchestration
responsibility from the facade.

Verification gaps:
- Strict compilation and diff hygiene pass.
- Full focused repair/facade family passes 68/68.
- Case matching, status derivation, condition order, protection decision
  options, terminal status sets, transition arguments, and the changed reduce
  call site were audited against selection commit `ac2e83ed`.
- Independent bounded review found no blocker.

Last completed slice:
CampaignPlanner repair activity-dispatch extraction published as `ce902067`:
one owner now supplies normalization, status/protection priority, and
transition selection; 68 focused tests passed and bounded review found no
blocker.

Next candidate:
After activity dispatch, refresh the CampaignPlanner hotspot map and leave the
repair lane if no cohesive callback-free owner remains.

Blocked:
No.
