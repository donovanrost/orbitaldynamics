# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair activity-identity ownership extraction.

Status:
Published as `6a51d53b`.

Selected slice:
Extract repair timeline ID, source-window ID, subject/station identity,
activity-context, and timeline-link helpers into `RepairActivityIdentity`;
remove duplicated facade and accumulator implementations.

Why this slice:
Replacement selection and transition metadata share identity helpers, while
`RepairAccumulator` independently duplicates the same timeline-ID derivation
for deltas. One exact internal owner removes that split without callbacks and
reduces the dependency closure required for a later transition extraction.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.repair/1`, exact repaired activities, deltas,
timeline links and contexts, generated timeline IDs, candidate matching, and
deterministic ordering.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_accumulator.ex`
- `lib/orbital_dynamics/campaign_planner/repair_activity_identity.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused repair facade and repair activity-transition families
- exact helper-body and call-site audit
- compile, format, diff hygiene, and bounded review

Definition of done:
All repair identity/context calls route through one owner; duplicate helper
bodies are absent; repaired artifacts and ordering remain exact; focused tests
pass; and bounded review finds no blocker.

Outcome:
Added `RepairActivityIdentity` as the single repair-local owner for activity
context, timeline links and IDs, source-window IDs, and station/subject
identity. The facade and `RepairAccumulator` now call that owner directly; the
two duplicated timeline-ID derivations and the facade's repair identity helper
cluster are gone. The facade fell from 4,540 to 4,496 lines and the accumulator
from 250 to 206; the new 55-line owner leaves the bounded scope net -33 lines.

Verification gaps:
- Strict compilation and diff hygiene pass.
- Repair facade/transition family passes 67/67.
- Shared station-event and capacity strategy paths pass 27/27.
- Former helper bodies and all changed call sites were audited against
  selection commit `fcbf614f`; repair identity semantics and ordering are
  unchanged.
- Independent bounded review found no blocker.

Last completed slice:
CampaignPlanner repair activity-identity ownership extraction published as
`6a51d53b`: one owner now supplies repair timeline/context/station/window
identity, the bounded scope is net -33 lines, 94 focused tests passed, and
bounded review found no blocker.

Next candidate:
With identity and accumulator ownership unified, remap replacement selection.
Extract it only if candidate scoring, policy values, and candidate-diff
matching can move as one complete owner without callbacks.

Blocked:
No.
