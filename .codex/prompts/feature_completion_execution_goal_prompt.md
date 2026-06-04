# `/goal` Prompt: Feature Completion Execution Loop

```text
Drive OrbitalDynamics toward feature completion across the remaining incomplete
areas in `docs/complete_feature_set.md`.

Objective:
Continuously implement the highest-value missing features from the current
feature map until the project has materially advanced across the remaining
incomplete areas, especially:

- mission-state-to-candidate refresh,
- typed operational timeline model,
- resource and communications modeling,
- formal schemas and compatibility,
- validation maturity,
- dynamics and event fidelity,
- orbit-data ingestion,
- planner/optimizer depth,
- operational policy library,
- long-running execution maturity.

Working loop:

1. Read `docs/complete_feature_set.md`, README, current docs, tests, and
   relevant code.
2. Pick the highest-leverage incomplete feature slice that can be implemented
   and verified safely.
3. State the selected slice briefly before editing.
4. Implement the slice using existing repo patterns.
5. Add focused tests.
6. Add or update example manifests/artifacts when public behavior or artifact
   shape changes.
7. Update docs, especially `docs/complete_feature_set.md`, to reflect the new
   status honestly.
8. Run the relevant tests.
9. Repeat with the next highest-leverage slice until blocked or until the
   remaining work is too large for the current goal.

Priority order:

1. Mission-state-to-candidate refresh.
2. Typed operational timeline model and approval/status semantics.
3. Cadence-facing schemas and artifact compatibility.
4. Resource and communications summaries.
5. Operational policy module.
6. Orbit-data ingestion and accepted planning-state adapters.
7. Validation maturity and reference fixtures.
8. Event/dynamics fidelity.
9. Planner/optimizer depth.
10. Long-running execution maturity.

Definition of done for each slice:

- Public behavior is implemented.
- Tests cover normal and failure cases.
- Artifacts remain deterministic for fixed inputs.
- New or changed artifacts have schema validation when applicable.
- Docs and feature map are updated.
- Relevant tests pass.

Important constraints:

- Keep Cadence as an artifact/import boundary. Do not implement Cadence
  database, API, UI, scheduling, or command execution.
- Prefer explicit, deterministic, auditable models over opaque optimizers.
- Preserve assumptions, provenance, validation level, source-window lineage,
  stable IDs, and schema versioning.
- Do not claim higher model fidelity than validation supports.
- Do not introduce high-fidelity external dependencies unless the slice
  explicitly scopes them behind an adapter contract.
- Avoid large rewrites. Prefer incremental, composable modules and artifacts.
- If a slice reveals a correctness bug, fix it before continuing.
- If a feature is too large, implement the smallest valuable vertical slice and
  document the remaining work.

Expected first slice:
Implement `candidate_refresh.v1`.

Candidate refresh V1 should:

- Accept an `accepted_planning_state.v1` snapshot plus ground stations, targets,
  current epoch, remaining horizon, propagator/options, and model assumptions.
- Build refreshed scenarios from accepted spacecraft states.
- Propagate those scenarios.
- Generate refreshed access windows, target visibility windows, and eclipse
  intervals.
- Generate candidate activities from refreshed windows.
- Optionally compare refreshed candidates against prior candidate activities and
  mark stale/invalidated candidates.
- Emit a deterministic `candidate_refresh.v1` artifact with assumptions,
  provenance, validation records, refreshed windows, candidate activities,
  invalidated candidates, and source-window lineage.
- Add an executable schema contract and schema lint support.
- Add focused tests and at least one example artifact or manifest.

After candidate refresh V1 is complete, continue through the priority list.
```

Short loop prompt to use after the goal is set:

```text
Continue the feature-completion loop. Pick the next highest-value incomplete
slice from `docs/complete_feature_set.md`, implement it, test it, update
docs/artifacts, and continue until blocked.
```
