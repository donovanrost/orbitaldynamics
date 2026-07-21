# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Declare and validate nested V2 command-window reports.

Status:
Complete; ready to publish.

Selection evidence:
- V2 always emits `command_window_report.v1` from repaired activities and
  approval policy, but the repair registry declares neither the field nor its
  nested contract.
- Repair runtime validation therefore does not apply the standalone report's
  row, derived-count, approval/dependency, timeline-identity, and model-limit
  checks.
- Both checked V2 reports pass standalone validation and the producer uses fixed
  repair activity source and source-assumption identities.

Intended behavior:
- Declare the optional command-window report and V1 nested contract in the V2
  registry and generated JSON Schema.
- Run the complete standalone command-window validator inside repair validation.
- Pin report source and source assumption to repaired activities.
- Keep the field optional for compatible older V2 artifacts.
- Add checked-fixture, nested count/source, optional-report, schema-export, and
  real command-repair coverage; document the executable guarantee.

Level 6 pillar advanced:
Versioned V2 command-window evidence with executable nested validation.

Last published slice:
- `21dd13bf` Reconcile V2 timeline transition reports (`3741 passed`).

Likely files:
- V2 registry/runtime command-window contracts
- focused command-window and schema-export tests
- checked-in schema exports and V2 capability docs

Verification:
- Focused command-window and repair-planner tests: `5 passed`.
- Campaign-repair schema fixtures: `47 passed`.
- Schema suite plus schema-lint/export task tests: `426 passed`.
- Campaign-planner suite: `759 passed`.
- Full checked-artifact lint: `155/155 passed`, zero warnings.
- Full suite: `3745 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Full schema export refreshed the V2 repair schema and aggregate bundle only.

Review:
- The V2 registry now declares optional `command_window_report` and its V1
  nested contract; generated schemas expose the property and complete report
  definition without requiring it from compatible older V2 artifacts.
- Runtime repair validation now applies the standalone command-window contract,
  including row types/identity, interval and dependency/exclusivity evidence,
  approval/review context, derived counts, and exact model limits.
- Repair-specific validation pins both the report source and embedded source
  assumption to repaired campaign activities, preventing another planning
  stage's valid command report from being relabeled as repair evidence.
- Both checked V2 repairs, the real command-repair path, all checked artifacts,
  and existing V1 command-window consumers remain valid.

Remaining maturity gaps:
- Continue exact V2 ranking/score reconciliation for replayable source fields.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
