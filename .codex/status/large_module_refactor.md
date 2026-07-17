# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair activity-identity ownership extraction.

Status:
Selected.

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
Pending.

Verification gaps:
- Pending.

Last completed slice:
CampaignPlanner repair-accumulator mutation ownership cleanup published as
`0f91bc40`: all 37 mutation points remained exact, repair-family tests passed
67/67, and bounded review found no blocker.

Next candidate:
With identity and accumulator ownership unified, remap replacement selection.
Extract it only if candidate scoring, policy values, and candidate-diff
matching can move as one complete owner without callbacks.

Blocked:
No.
