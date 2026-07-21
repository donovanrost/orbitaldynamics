# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Declare and validate nested V2 constraint reports.

Status:
Complete; ready to publish.

Selection evidence:
- V2 production always emits `constraint_report.v1`, but the repair registry
  declares neither the optional field nor its nested contract.
- Repair runtime validation therefore does not invoke the existing standalone
  constraint-report validator; malformed row/count/status evidence can pass
  when embedded in an otherwise valid repair.
- The generic report contract already owns row/count/model-limit validation,
  while V2 production has distinct deterministic model and assumption IDs.

Intended behavior:
- Declare the optional constraint report and `constraint_report.v1` nested
  contract in the V2 registry and generated JSON Schema.
- Run generic nested report validation inside repair validation, then pin the
  repair-specific model, constraint model, and source assumption.
- Keep the field optional for compatible older V2 artifacts.
- Add checked-fixture, nested shape/count, identity, optional-report, and schema-
  export coverage; refresh checked-in schemas and document the guarantee.

Level 6 pillar advanced:
Versioned V2 constraint evidence with executable nested contract validation.

Last published slice:
- `6345cacf` Reconcile V2 score report identity (`3728 passed`).

Likely files:
- V2 registry/runtime constraint contracts
- focused constraint and schema-export tests
- checked-in schema exports and V2 capability docs

Verification:
- Focused V1/V2 constraint, planner, and schema-export tests: `29 passed`.
- Campaign-repair schema fixtures: `35 passed`.
- Schema suite plus schema-lint/export task tests: `414 passed`.
- Campaign-planner suite: `759 passed`.
- Full checked-artifact lint: `155/155 passed`, zero warnings.
- Full suite: `3733 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Full schema export refreshed the V2 repair schema and aggregate bundle only.

Review:
- The V2 registry now declares optional `constraint_report` and its
  `constraint_report.v1` nested contract; generated schemas expose the property
  and definition without making the field required for older artifacts.
- Runtime repair validation invokes the existing standalone report contract for
  row shape, counts, status, and model limits, then pins the V2 repair model,
  constraint-model assumption, and source identity.
- Campaign-local `constraint_count` now follows producer semantics: configured
  supported constraints may outnumber evaluated row IDs when inputs are absent,
  but cannot undercount evaluated constraints. Artifact-metric reports retain
  exact row-derived count reconciliation.
- Both checked V2 repair fixtures, real planner output, all checked artifacts,
  and existing V1 constraint-report consumers remain valid.

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
