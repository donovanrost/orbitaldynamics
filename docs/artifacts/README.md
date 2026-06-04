# Artifacts

Canonical artifact reference for OrbitalDynamics. This directory replaces the
original `docs/artifact_reference.md` monolith.

## Front matter

- [overview.md](overview.md) — the front-matter intro listing what artifacts
  this reference covers.
- [canonical_examples.md](canonical_examples.md) — checked-in canonical
  artifact examples and where to find them.

## Field families

One file per artifact family, with the original prose and field tables
verbatim. The three largest families have been split into per-topic sub-files
under a sibling directory; the named `*.md` is the index in those cases.

- [field_families/mission_activities.md](field_families/mission_activities.md)
- [field_families/result_artifacts.md](field_families/result_artifacts.md)
- [field_families/v1_campaign_plan.md](field_families/v1_campaign_plan.md) — index over [`field_families/v1_campaign_plan/`](field_families/v1_campaign_plan/) (operational timeline, contact allocation, candidate refresh, command windows, station calendar, schema validation, etc.)
- [field_families/v2_repair_artifact.md](field_families/v2_repair_artifact.md)
- [field_families/v3_strategy_artifact.md](field_families/v3_strategy_artifact.md) — index over [`field_families/v3_strategy_artifact/`](field_families/v3_strategy_artifact/) (branch replay, mission-state replay, branch-local feedback and recommendation)
- [field_families/policy_bundles.md](field_families/policy_bundles.md) — index over [`field_families/policy_bundles/`](field_families/policy_bundles/) (built-in bundles, selectors, and policy evidence in downstream artifacts)
- [field_families/candidate_refresh_artifact.md](field_families/candidate_refresh_artifact.md)

## Compatibility

- [compatibility_checks.md](compatibility_checks.md) — schema-level and
  shape-level compatibility expectations across artifact versions.
