# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: Cadence import direct-pressure routing extraction.

Status:
The 481-line Cadence import source-family dispatcher and its capacity-pack
normalization now live in a focused internal module. `CampaignPlanner` remains
the public facade and is 584 lines smaller than at slice selection.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/cadence_import_direct_pressure_branches.ex`

Public APIs preserved:
- `OrbitalDynamics.CampaignPlanner.build/2`
- `OrbitalDynamics.CampaignPlanner.repair/1`
- `OrbitalDynamics.CampaignPlanner.strategy/1`

Behavior/schema changes:
- No intended public behavior or schema changes.
- Direct Cadence import rows retain the same ordered source-family dispatch,
  approval/trust-boundary enrichment, source paths, and pressure adapters.
- Capacity-pack recommendation normalization moved with the dispatcher and is
  shared by both Cadence import and operator-review routing.

Tests run:
- `mix compile --warnings-as-errors` - passed.
- Focused campaign-planner strategy shard covering Cadence import feedback,
  capacity packs, review/import source reports, communications filters,
  objective/constraint routing, score-term routing, and timeline-diff routing -
  passed, 28 tests.
- `mix xref callers OrbitalDynamics.CampaignPlanner.CadenceImportDirectPressureBranches`
  - passed; runtime caller is `CampaignPlanner`.
- `mix xref graph --label compile-connected --source lib/orbital_dynamics/campaign_planner.ex`
  - passed; the new internal module is a compile-connected dependency.
- `mix format --check-formatted` on the ledger and touched source files - passed.
- `git diff --check` - passed.
- `git diff --no-index --check -- /dev/null` on the new module - passed with no
  whitespace diagnostics.
- Bounded local review - passed; reviewer sidecar was unavailable by runtime
  policy, and no must-fix behavior, dependency, or duplication issue remained.

Verification gaps:
- Full `mix test` was not run; the focused 28-test routing shard was used because
  this was a mechanical internal extraction with no schema or artifact change.

Last commit:
`a447a044` before this slice; publish pending.

Next candidate:
Inspect the 252-line `do_repair/1` orchestration cluster in
`lib/orbital_dynamics/campaign_planner.ex` for extraction behind a focused V2
repair module while preserving `CampaignPlanner.repair/1`.

Blocked:
No.

Notes:
- `campaign_planner.ex` decreased from 6,276 to 5,692 lines.
- The new internal dispatcher is 634 lines and owns one explicit routing-table
  responsibility; it should be split further only along real source-family
  boundaries, not into one-function micro-modules.
- The prior `Common.ValueCounts` proposal was rejected because extracting a
  five-line helper from a 27-line module would increase fragmentation without
  reducing maintenance risk.
