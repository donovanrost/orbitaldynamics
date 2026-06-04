# `/goal` Prompt: Autonomous Product Completion Loop

```text
Drive OrbitalDynamics toward a mature Cadence-facing LEO mission-planning
substrate. Work autonomously for as long as the goal remains productive.

Context:
- OrbitalDynamics is an Elixir orbital/astrodynamics and mission-planning
  toolkit.
- The product direction is to become the auditable planning engine for Cadence,
  a ground data system for large-constellation spacecraft operations.
- The repo already contains V1 campaign planning, V2 rolling repair, V3
  strategy comparison, candidate refresh, artifact schemas, validation records,
  station-calendar overlays, policy decisions, timeline reports, resource
  summaries, orbit-data adapters, optimizer explanation artifacts, and golden
  artifact tests.
- The next work should not merely add more report fields. It should convert the
  remaining thin artifact surfaces into useful product behavior while preserving
  deterministic, inspectable, schema-validated artifacts.

Primary objective:
Continuously implement the highest-value missing product features from
`docs/complete_feature_set.md`, prioritizing the gaps that most directly move
OrbitalDynamics from "planning artifact prototype" to "operational planning
substrate."

Autonomy rule:
Do not stop after proposing work. Inspect the repo, choose the highest-value
safe slice, implement it, test it, update docs/artifacts, then repeat. Continue
until blocked by missing product decisions, unsafe/destructive action, external
credentials/network requirements, or until the remaining work is too large to
make useful progress in the current goal.

Source-of-truth files to read first:
- `docs/complete_feature_set.md`
- `docs/leo_constellation_campaign_planner.md`
- `docs/artifact_reference.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/timeline.ex`
- `lib/orbital_dynamics/policy.ex`
- `lib/orbital_dynamics/resource_summary.ex`
- `lib/orbital_dynamics/communications/station_calendar.ex`
- `lib/orbital_dynamics/schema.ex`
- current tests under `test/orbital_dynamics/`

First action:
Before adding new features, review the latest code for known correctness issues
or review comments. Fix correctness issues first when they affect planning
decisions, artifact trust, schema validation, resource/contact interpretation,
or operator-review outcomes. Then resume the product-completion loop.

Product priority order:

1. Typed operational timeline and activity model.
   Build beyond report-only rows. Add first-class APIs and contracts for
   operational activities, timeline identity, status transitions, approval
   state, lock/executed preservation, dependencies, exclusivity, source-window
   provenance, and Cadence import boundaries. Preserve the artifact-only
   execution boundary: do not command spacecraft or mutate Cadence schedules.

2. Resource and communications allocation model.
   Move from thin resource/contact annotations toward explicit allocation and
   contention semantics. Prioritize station reservation handling, provider
   calendar semantics, same-station contention, contact direction, link
   capacity, storage pressure, downlink completion, power/fuel/payload
   availability, antenna availability, and resource roll-forward summaries.
   Keep the first models deterministic and auditable.

3. Branch-local candidate refresh depth.
   Expand mission-state-derived refresh so V2/V3 can regenerate and compare
   access, visibility, eclipse, resource, and contact opportunities from
   current mission state and branch assumptions. Prefer executable refresh
   requests over stale prior-plan candidates. Preserve freshness, diff,
   resource-filter, contact-filter, and source-window lineage reports.

4. Cadence-facing import/export contracts.
   Harden JSON-friendly artifacts that Cadence would import or review:
   proposed contacts, contact intents, operational timeline rows, plan deltas,
   approval requirements, operator-review packages, policy decisions, resource
   summaries, station-calendar reports, realized feedback, and candidate
   refresh artifacts. Add schema validation, JSON Schema export coverage,
   golden fixtures, compatibility notes, and stable-ID rules.

5. Operational policy library.
   Broaden reusable policy bundles and policy decision behavior for station
   reservations, command/contact authority, degraded-mode restrictions,
   maneuver authority, timeline protection, auto-approval boundaries, blocking
   rules, escalation metadata, and organization-specific adapter hooks.
   Policy must classify and explain; it must not execute workflow.

6. Validation and trust maturity.
   Extend validation records, tolerance policies, backend acceptance policies,
   reference fixture reports, event timing metadata, model-limit declarations,
   and golden artifacts. Do not claim operational or high-fidelity trust without
   matching evidence. Prefer honest `educational`, `analysis`, and
   `artifact_contract` levels over inflated claims.

7. Dynamics, events, and orbit-data maturity.
   Add practical vertical slices for force/event/orbit-data gaps only when they
   can be validated and documented honestly. Candidate slices include refined
   AOS/LOS timing, drag/atmosphere interfaces, Earth-rotation/frame assumptions,
   finite-burn or maneuver uncertainty metadata, broader CCSDS metadata,
   separate TLE/SGP4 regime boundaries, and richer lighting/event detectors.

8. Planner and optimizer depth.
   Improve beyond simple greedy selection only after the constraints and
   resources are concrete enough to optimize. Candidate slices include local
   search, repair-neighborhood search, multi-objective ranking, Pareto
   explanations over generated alternatives, branch-tree comparisons,
   deterministic stochastic search, and external solver adapter contracts.
   Preserve explainability.

9. Long-running execution maturity.
   Improve resumable studies, persistent queues, adaptive chunking, payload cost
   reporting, distributed execution evidence, operational scale targets,
   failure recovery, and benchmark trend artifacts.

Working loop:

1. Refresh context from code/docs/tests.
2. Select one vertical slice that advances the highest-priority incomplete
   product area.
3. State the selected slice briefly.
4. Implement public behavior using existing repo patterns.
5. Add focused tests for success, failure, edge cases, deterministic ordering,
   and schema validation where applicable.
6. Update or add example manifests/artifacts/fixtures when public artifact
   shape changes.
7. Update docs, especially `docs/complete_feature_set.md`, with honest status:
   implemented, partial, near-term, later, or out of scope.
8. Run the relevant tests. Prefer targeted tests during the loop and `mix test`
   when the implemented slice is broad enough.
9. If tests fail, fix the failure before moving to a new feature.
10. Repeat with the next highest-value slice.

Definition of done for each slice:
- The feature has usable public behavior, not just documentation.
- Artifacts remain deterministic for fixed inputs.
- JSON-facing maps are atom/string-key tolerant where existing APIs are.
- New or changed artifacts include schema validation when appropriate.
- Stable public IDs, assumptions, provenance, validation level, model limits,
  and source-window lineage are preserved or explicitly added.
- Tests cover normal behavior and at least one failure or edge case.
- Docs reflect the real maturity level without overstating fidelity.
- Existing V1/V2/V3 examples and contracts remain compatible unless an
  intentional versioned extension is documented.

Important constraints:
- Keep Cadence as an artifact/import/review boundary. Do not implement Cadence
  database, UI, API, schedule mutation, command execution, or approval workflow.
- Prefer explicit deterministic models over opaque intelligence.
- Do not add external dependencies casually. If an external standard, solver,
  or reference tool is needed, put it behind an adapter contract and document
  the limitation.
- Do not broaden scope into non-LEO regimes unless the slice is a clean adapter
  or contract boundary.
- Do not make flight-certification or high-fidelity claims.
- Avoid large rewrites. Add composable modules, contracts, fixtures, and tests.
- Preserve existing public behavior unless changing it is necessary to fix a
  correctness issue or versioned contract gap.
- If a feature is too large, implement the smallest useful vertical slice and
  document the remaining work.

Preferred first slices if no higher-priority correctness bug is found:

1. Promote operational timeline from report-only to a first-class typed
   activity/timeline model:
   - typed activity normalization,
   - status and approval transition helpers,
   - dependency/exclusivity metadata,
   - lock/executed preservation semantics,
   - timeline diff contract improvements,
   - operator-review rows that point to concrete transition reasons.

2. Promote station calendar/resource handling from annotation to allocation
   semantics:
   - explicit reserved/unavailable/reduced-capacity precedence,
   - provider reservation IDs and ownership,
   - affected-contact review rows,
   - same-station contention groups,
   - deterministic resolution recommendations,
   - tests that prove reserved time cannot disappear when overlapping other
     station events.

3. Deepen branch-local refresh in V2/V3:
   - derive refresh requests from accepted mission state,
   - apply branch station/resource/objective/feedback events,
   - prefer refreshed candidates over stale prior candidates,
   - preserve candidate-diff reasons through repair, strategy explanation, and
     operator review.

Verification guidance:
- Use targeted `mix test test/path_test.exs` while iterating.
- Run broader `mix test` after broad planner/schema/artifact changes.
- Run schema lint/export tests when artifact contracts change.
- If a Mix command fails because of environment sandboxing or BEAM filesystem
  lock issues, record the exact failure and retry appropriately if possible.
- Never leave a known failing test caused by the current slice unresolved.

Completion report:
At the end of the goal, summarize:
- slices implemented,
- files changed,
- tests run and results,
- artifacts/docs updated,
- remaining highest-priority gaps,
- any blocked work and why.
```
