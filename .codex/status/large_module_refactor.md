# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema campaign-artifact property-dispatch extraction.

Status:
Slice selected; implementation not started.

Selected slice:
Move the `campaign_plan` and `campaign_repair` `json_schema_property/3`
dispatch clauses from `OrbitalDynamics.Schema` into an internal
`Schema.CampaignArtifactPropertyDispatch` owner.

Why this slice:
The repo-wide hotspot refresh shows `Schema` remains 7,794 lines, while
candidate refresh, campaign planner, and operator review are now compact
facades. Campaign plan and repair already have family-specific JSON-schema
builders; only their routing/context assembly remains in the facade.

Current coupling/problem:
The Schema facade still assembles campaign-plan row callbacks and
campaign-repair transition-contract recursion directly. This mixes
family-specific JSON-property dispatch with registry/export facade concerns.

Public facade to preserve:
`Schema.contracts/0`, `contract/1`, `json_schema/1`, `json_schema_bundle/0`,
write/export functions, validation/lint APIs, campaign plan and repair JSON
Schema documents, checked-in exports, deterministic ordering, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/campaign_artifact_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The two campaign artifact clauses delegate through the new internal dispatcher;
required/optional fields and recursive timeline-transition property routing are
unchanged; focused campaign schema tests pass; strict compile, schema export
tests, checked-in export diff, and independent review are clean.

Verification gaps:
- Focused campaign schema and export baselines still need to be captured.
- Checked-in schema exports must remain byte-identical.

Tests run:
- Live hotspot inventory: `Schema` is 7,794 lines and remains the only original
  production goal hotspot in the repo-wide top tier.
- Existing `CampaignPlanJsonSchema` and `CampaignRepairJsonSchema` modules own
  property construction; this slice moves only routing/context assembly.
- No runtime or schema code has changed in this slice.

Behavior/schema changes:
None intended.

Outcome:
Pending.

Last completed slice:
Campaign-planner V1 build orchestration published as implementation `6fc2e3e4`
and handoff `52ebb0ec`: the facade shrank from 1,443 to 1,078 lines; focused
34/34, full-baseline, and 3,652-file compile proof passed; independent review
was clean after restoring exact report evaluation order.

Next candidate:
Implement and verify campaign-artifact schema property dispatch.

Blocked:
No.
