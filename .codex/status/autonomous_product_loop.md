# Autonomous Product Loop Status

Current slice:
Expose resource-projection row policy evidence schemas.

Status:
Implemented, locally verified, and read-only reviewed clean; pending publish.

Discovery:
After the resource-projection battery row slice, live fixture/schema comparison
for `resource_projection_report.v1` `projected_resources` shows only two
remaining row fields emitted by the battery-handoff projection fixture without
named projected-resource row schema fields: `approval_requirements` and
`approval_rule_matches`.

Why this matters:
These arrays carry the policy evidence that explains why a projected resource
row requires operator review or is blocked by policy. The nested approval
requirement and policy rule-match schemas already exist elsewhere in the schema
module, so exposing them at projected-resource row scope should make the
battery-handoff policy evidence schema-visible without changing the policy
model.

Likely files:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- generated schemas embedding `resource_projection_row_json_schema/0`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- [x] `resource_projection_report.v1` projected-resource row schema exposes
  `approval_requirements` and `approval_rule_matches` as typed arrays using the
  existing nested policy schemas.
- [x] Executable validation rejects malformed nested approval requirement and
  policy rule-match values.
- [x] Focused schema tests assert row schema shape and representative invalid
  nested values.
- [x] Checked-in schemas and bundle are refreshed.
- [x] Focused schema tests, schema export tests, schema lint, generated-schema
  spot-checks, and whitespace checks pass.
- [x] Read-only review finds no must-fix issues.
- [ ] Slice-owned files only are committed and pushed.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs:19622`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `jq -e` spot-checks for projected-resource policy evidence arrays in
  `schemas/resource_projection_report.v1.schema.json`,
  `schemas/campaign_plan.v1.schema.json`,
  `schemas/resource_projection_flow_summary.v1.schema.json`, and
  `schemas/orbital_dynamics.schema_bundle.v1.json`
- row-gap scan for `resource_projection_report.v1` `projected_resources`
  fixtures returned no missing emitted row keys
- `git diff --check -- . ':!.gitignore'`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- Read-only reviewer reran focused schema test, whitespace check, direct and
  embedded generated-schema `jq -e` shape checks, and the projected-resource
  row-gap scan, and reported no must-fix findings.

Last completed implementation commit:
`af84b24bcefe4def1c871d7ca153b9a2a10f97a1` pushed to `origin/main`.

Last ledger correction commit:
`6a67024d5d01d5b0a40dfeaa73238b772d9fc5a5` pushed to `origin/main`.

Next candidate:
Run a fresh row-gap scan across `resource_projection_report.v1` fixtures and
pick the next schema-visible gap, if any remain.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
