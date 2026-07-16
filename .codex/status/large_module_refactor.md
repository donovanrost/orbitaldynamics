# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: V2 repair artifact assembly extraction.

Status:
`CampaignPlanner.do_repair/1` now retains repair orchestration and delegates the
final V2 artifact contract, optional source-report attachment, operator-review
package, and Cadence import manifest to `CampaignPlanner.RepairArtifact`.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_artifact.ex`
- `lib/orbital_dynamics/campaign_planner/repair_metadata.ex`

Public APIs preserved:
- `OrbitalDynamics.CampaignPlanner.repair/1`
- `OrbitalDynamics.CampaignPlanner.repair!/1`
- `OrbitalDynamics.CampaignPlanner.repair_from_file!/2`

Behavior/schema changes:
- No intended public behavior or schema changes.
- The V2 artifact retains the same fields, ordering inputs, optional source
  reports, repair identity, operator-review package, and Cadence import manifest.
- Source-plan identity is centralized through `RepairMetadata.source_plan_id/1`
  instead of adding another private copy.
- Ten facade-only private wrappers made obsolete by the extraction were removed.

Tests run:
- `mix compile --warnings-as-errors` - passed.
- All split `repair*_test.exs` files plus file-backed facade and strategy
  baseline-source-candidate coverage - passed, 62 tests.
- `mix xref callers OrbitalDynamics.CampaignPlanner.RepairArtifact` - passed;
  runtime caller is `CampaignPlanner`.
- `mix xref graph --label compile-connected --source lib/orbital_dynamics/campaign_planner.ex`
  - passed; the new module is a compile-connected dependency.
- `mix format --check-formatted` on the ledger and touched source files - passed.
- `git diff --check` - passed.
- `git diff --no-index --check -- /dev/null` on the new module - passed with no
  whitespace diagnostics.
- Conflict-marker scan - passed.
- Bounded local review - passed; no behavior, dependency, ordering, or
  duplication issue remained.

Verification gaps:
- Full `mix test` was not run. The complete split V2 repair family and its
  adjacent public-facade/strategy baseline coverage passed.

Last commit:
`c6aaecf0` before this slice; publish pending.

Next candidate:
Extract the cohesive branch feedback factor/score cluster from
`CampaignPlanner.branch_feedback_adjustments/4` through its private averaging
helpers into `CampaignPlanner.StrategyFeedbackAdjustments`. Compute branch
operational feedback in the parent so the new module does not need callback
plumbing for event identity.

Blocked:
No.

Notes:
- `campaign_planner.ex` decreased from 5,692 to 5,527 lines.
- `do_repair/1` decreased from 252 to 144 lines.
- `RepairArtifact` is 165 lines and owns one explicit output-assembly contract.
