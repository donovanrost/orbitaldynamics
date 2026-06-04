# `/goal` Prompt: V3 Feature Completeness

```text
Implement the next feature-completeness pass for LEO Constellation Campaign Planner V3 in OrbitalDynamics.

Current state:
- V1 generates fixed-horizon LEO campaign plans.
- V2 repairs prior plans against realized operations.
- V3 currently exists as a deterministic what-if branch comparison layer over V2 repair.
- The V3 artifact shape is useful, but the behavior is still too thin to count as a feature-complete mission orchestration layer.

Goal:
Make V3 substantially more feature-complete as a mission orchestration system. V3 should use mission state, branch assumptions, operational feedback, resource summaries, approval policy, and concrete plan deltas to compare alternate futures and recommend a strategy with useful explanations.

Primary outcome:
V3 should move from "compare caller-supplied branch wrappers" toward "evaluate real operational strategy alternatives from a living mission-state snapshot."

Done means:
- Existing V1, V2, and V3 behavior remains deterministic and tested.
- `CampaignPlanner.strategy/1` still accepts explicit branches, but can also derive useful default branches from `mission_state` when requested.
- `mission_state` actively influences branch generation, branch repair inputs, resource/risk evaluation, approval classification, and recommendation explanations.
- Strategic additions such as urgent targets are feasibility-backed when candidate windows exist, and clearly marked as unvalidated placeholders when they do not.
- Operational feedback affects branch scoring or risk estimation in at least one practical way.
- Resource summaries influence scoring and warnings through thin but explicit models for fuel, downlink capacity, storage, or spacecraft availability.
- Approval policy supports action-specific classifications instead of only risk-count and approval-count thresholds.
- Recommendation explanations cite concrete changed activities, objectives, risks, approvals, and tradeoffs.
- Example V3 request and result artifacts are updated to demonstrate the new behavior.
- Docs explain the completed V3 feature slice and remaining limits.
- Add focused tests for all new behavior.

Important implementation direction:
Keep this pragmatic and incremental. Do not build a full optimizer, digital twin database, Cadence integration, or high-fidelity resource simulator. Prefer explicit, deterministic, inspectable models that make V3 operationally meaningful while preserving the current artifact-first boundary.

Feature areas to implement, in priority order:

1. Mission-state-driven behavior
- Expand how `MissionState` is used beyond artifact recording.
- Use `mission_state.spacecraft_states` and/or `mission_state.degradations` to derive degraded spacecraft repair inputs when branches do not explicitly provide them.
- Use `mission_state.ground_network` to derive ground-station outage, degraded availability, or capacity assumptions.
- Use `mission_state.objectives` to drive priority commitments, required downlink completion, coverage/revisit objectives, and branch scoring.
- Use `mission_state.resources` for fuel, storage, downlink capacity, and other thin resource summaries.
- Keep all accepted mission-state shapes JSON-friendly and atom/string-key tolerant.

2. Derived branch generation
- Add an option such as `derive_branches?: true` or `branch_generation_policy` to `strategy/1`.
- When enabled, generate a baseline branch and useful what-if branches from mission state.
- Candidate derived branches should include:
  - degraded spacecraft branch for spacecraft marked degraded,
  - ground station outage/capacity branch for unavailable or reduced ground assets,
  - fuel preservation branch when fuel margin is low or requested,
  - urgent target branch for high-priority unscheduled commitments,
  - downlink-constrained branch when required downlink completion is at risk.
- Preserve explicit caller-provided branches and merge or append derived branches deterministically.
- Deduplicate branches by stable branch id.

3. Feasibility-backed urgent target handling
- Replace or refine synthetic urgent target insertion.
- If candidate observation windows exist for the urgent target, choose the best viable candidate by priority, score, horizon, overlap, and optional spacecraft constraints.
- If no candidate window exists, allow a placeholder only when policy permits, mark it as not physically validated, add a warning, and require approval.
- Do not silently stage impossible urgent observations as if they were valid.
- Include target id, selected scenario id, source window, feasibility status, and approval requirement in the artifact.

4. Operational feedback use
- Use `operational_feedback.contact_success_rate` to adjust downlink/contact score or risk.
- Use `operational_feedback.observation_success_rate` to adjust observation score or risk.
- Use `operational_feedback.maneuver_success_rate` to adjust maneuver-related risk.
- Use `operational_feedback.station_throughput_factor` to adjust downlink completion/resource score.
- Record the adjustment in score terms or risk indicators so the recommendation is explainable.
- Keep the first model simple and deterministic.

5. Thin resource model
- Add resource scoring/risk for at least two of:
  - fuel margin,
  - downlink capacity,
  - onboard storage,
  - spacecraft availability,
  - payload availability.
- Resource inputs should come from `mission_state.resources`, spacecraft state entries, or branch events.
- The model can be approximate, but must be explicit in assumptions and score terms.
- Add warnings or risks when resource summaries indicate a plan is likely infeasible or fragile.

6. Action-specific approval policy
- Extend `ApprovalPolicy` to support action-specific rules.
- Examples:
  - moved contact requires operator review,
  - strategic urgent target insertion requires operator review,
  - low-risk contact move may be auto-approvable,
  - maneuver timing changes require operator review or can be blocked,
  - degraded-spacecraft payload activity is blocked or requires review,
  - command/health activities can remain allowed under degraded mode.
- Approval output should explain which rule fired.
- Preserve existing coarse policy fields for backward compatibility.

7. Better recommendation explanation
- Expand recommendation tradeoffs beyond numeric score deltas.
- Include concrete explanations such as:
  - which priority commitments are satisfied or missed,
  - which activities moved, canceled, preserved, or added,
  - which risks drove approval status,
  - which branch wins despite lower mission value because it reduces risk or approval burden,
  - which branch loses because it violates a resource or approval policy.
- Add a top-level `recommendation.explanation` or structured explanation list.
- Keep explanations deterministic and suitable for operator display.

8. Branch artifact improvements
- Include per-branch:
  - derived branch source if applicable,
  - resource impacts,
  - feedback adjustments,
  - objective satisfaction summary,
  - approval rule matches,
  - feasibility summary for strategic additions.
- Preserve existing fields so current tests and consumers remain stable unless there is a deliberate schema update.

9. Examples and docs
- Update `studies/leo_constellation_campaign_strategy_v3.json` or add a new example that demonstrates:
  - derived branches,
  - mission-state degradations/resources/objectives,
  - urgent target feasibility,
  - operational feedback,
  - action-specific approval rules,
  - concrete recommendation explanation.
- Update `study_results/leo_constellation_campaign_strategy_v3.json` or corresponding result artifacts.
- Update `docs/leo_constellation_campaign_planner.md` to distinguish:
  - V3 first slice already implemented,
  - this feature-complete V3 pass,
  - still-out-of-scope future work.
- Update README pointers only if needed.

10. Tests
Add or expand tests for:
- mission-state-derived degraded spacecraft branch,
- mission-state-derived ground station outage or reduced capacity branch,
- mission-state-derived fuel preservation branch,
- urgent target chooses a real candidate window when available,
- urgent target placeholder is marked unvalidated and approval-required when no candidate exists,
- operational feedback changes score/risk deterministically,
- resource summaries create score terms and risks,
- action-specific approval policy classifies moved contacts, urgent additions, and maneuver changes,
- recommendation explanation names concrete activities/objectives/risks,
- derived branch generation is deterministic,
- explicit and derived branches merge without duplicates,
- existing V1/V2/V3 examples still work.

Out of scope:
- Cadence database, UI, or API changes.
- Autonomous command execution.
- Persistent digital twin storage.
- ML-based learning.
- Full power/storage/fuel simulation.
- New high-fidelity propagation backend work.
- Non-LEO mission regimes except as documented future extension points.
- Flight certification or precision claims beyond current validation evidence.

Quality constraints:
- Keep public artifacts JSON-friendly.
- Accept atom-keyed and string-keyed maps where current APIs already do.
- Keep deterministic ordering and deterministic IDs for fixed inputs.
- Preserve existing schema fields unless there is a clear reason to add a versioned extension.
- Prefer clear, explicit helper functions over opaque generic abstractions.
- Keep every generated strategy artifact tied to assumptions, provenance, policy, and model limits.
- If a feature is only a thin approximation, say so in artifact assumptions or docs.

Verification:
- Run `mix test`.
- Run any existing study/demo commands needed to refresh V3 example artifacts.
- If tests cannot run or examples cannot be refreshed, explain exactly why and what remains unverified.

Suggested first step:
Review `lib/orbital_dynamics/campaign_planner.ex`, `test/orbital_dynamics/campaign_planner_test.exs`, `docs/leo_constellation_campaign_planner.md`, and the V3 study/result examples. Then implement the highest-value feature slice first: mission-state-derived branches plus richer recommendation explanations. Continue through the remaining feature areas as far as possible within the goal.
```
