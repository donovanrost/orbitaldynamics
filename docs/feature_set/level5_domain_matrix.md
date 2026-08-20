# Level 5 Domain Readiness Matrix

Audit snapshot: `e8c64928` on 2026-08-19.

This is a base-branch audit. It does not inspect or predict the unmerged
event-precision, explainable-search, or resumable-execution work.

## Basis and criterion

Evidence was timeboxed to the live source/tests, the checked-in output of the
executable [`capability_catalog/0`](../../lib/orbital_dynamics.ex), the
[`current capability snapshot`](current_capability_snapshot.md), the numbered
domain status summaries, checked-in artifacts, and recent Git history. Planning
prose was not treated as proof.

The catalog was not rerun during this audit because the Herdr worktree's runtime
and shared dependency paths were not configured at the time. The host runtime
was available; this was a worktree setup limitation, not evidence that Mix or
Elixir was absent. The checked-in
[`capability_catalog_v1.json`](../../study_results/capability_catalog_v1.json)
is traceable to the public function, schema fixture, and
[`capability task tests`](../../test/mix/tasks/orbital_dynamics.capabilities_test.exs),
but no current test-pass claim is made.

At this snapshot the catalog declares 121 artifact contracts, seven
propagators, four environment providers, six planning groups, and 17 operations
groups. The checked-in
[`validation fixture rollup`](../../study_results/validation_reference_fixtures.json)
contains 202 passing internal fixtures. Those facts demonstrate contract breadth,
not external numerical or operational acceptance.

A domain is practically Level 5-ready when it helps an accepted,
provenance-bound mission snapshot regenerate time-valid opportunities, repair a
prior plan in each branch, enforce physical/resource/network/policy feasibility
during selection, compare feasible branches with reproducible reasons, and emit
an idempotent review/import handoff using fidelity validated for its declared
planning envelope. Direct scheduling, approval, reservation, and command
execution remain outside OrbitalDynamics.

Maturity labels are `L0` absent/deferred, `L1` vocabulary, `L2` executable
foundation, `L3` deterministic but thin prototype, `L4` end-to-end enabling
behavior with one practical gap, and `L5` credible readiness in the declared
envelope.

## Queue matrix

The maturity cell deliberately reports contract breadth separately from
numerical or operational fidelity. Slice IDs map directly to the waves below.

| # | Domain and current maturity | Verified evidence | Smallest missing Level 5 behavior | Dependencies and independently mergeable slice |
|---:|---|---|---|---|
| 1 | **Core astrodynamics — L2.** Contract: narrow. Fidelity: educational; frame/time labels without transforms. | [`Frame`](../../lib/orbital_dynamics/frame.ex), [`OrbitElements`](../../lib/orbital_dynamics/orbit_elements.ex), and the catalog say `no_frame_transformation` and `no_time_scale_conversion`. | One provider-backed Earth inertial/body-fixed state transform with round-trip tolerance and unsupported-time-scale rejection. | Depends on 4 and 18; consumed by 2, 3, 5. **W1-A:** isolated J2000-to-provider-defined-Earth-fixed transform and fixture. |
| 2 | **Orbit data/state updates — L3.** Contract: broad. Fidelity: narrow planning-grade interchange. | [`OrbitData`](../../lib/orbital_dynamics/orbit_data.ex) supports accepted Cartesian state, narrow OPM/OEM, and metadata-only TLE/OMM; catalog limits say OEM selects one sample and covariance is not propagated. | Interpolate multi-sample OEM to the strategy epoch with source samples, method, coverage, frame/time, and covariance status preserved. | Depends on 1 and 18; feeds 11, 13, 14. **W1-B:** bounded single-object OEM interpolation in the already supported inertial frame. **Decision:** whether SGP4 is Level 5. |
| 3 | **Propagation/force models — bounded L5.** Contract: medium. Fidelity: planning-grade only inside the declared sample envelope. | [`J2Drag`](../../lib/orbital_dynamics/propagators/j2_drag.ex) is opt-in and unchanged as a default; the [Orekit D3 corpus](../../priv/validation/external_truth/orekit_13_1_7_j2_drag_envelope/README.md) checks 200 states across six combined-force cases plus zero-density J2 and zero-J2 drag branches. | No missing behavior inside the declared eight-case 250--800 km, 1--24 hour, 5--30 s sample envelope at 0.01 m and 0.00001 m/s component tolerances. Unsampled continuous combinations and the broader computability guard envelope remain outside the accuracy claim. | Depends on 4 and 18; feeds 5. **W2-A delivered:** opt-in scalar J2-plus-drag propagator with no default change. |
| 4 | **Environment/ephemerides — L2.** Contract: medium. Fidelity: assumption-declared. | [`Environment`](../../lib/orbital_dynamics/environment.ex) has provider/coverage contracts, fixed Sun, constant/tabular rotation, and reference atmosphere; no authoritative ephemeris/EOP source exists. | Offline finite-coverage, time-varying Sun/Earth-orientation data with source revision archived on results. | Depends on 1, 18, 22; feeds 3, 5. **W1-C:** one checked-in tabular campaign-horizon provider and request-fit fixture. **Decision:** authoritative source/update policy. |
| 5 | **Event detection — L3.** Contract: broad. Fidelity: sampled, linearly refined analysis. | [`AccessWindows`](../../lib/orbital_dynamics/event_detectors/access_windows.ex) and peer detectors emit rich timing provenance, but the catalog says sample-cadence-limited and not root-solved. | Shared bracket/root contract with verified worst-case event-time error across sampling cadences, first used for AOS/LOS. | Depends on 1, 3, 4, 18. **W2-B, reserved event-precision lane:** replace access refinement only and carry convergence/tolerance to source windows; base-state recommendation only. |
| 6 | **Spacecraft/payload modeling — L2.** Contract: broad. Fidelity: thin external summaries. | [`SubsystemModel`](../../lib/orbital_dynamics/subsystem_model.ex) and [`ResourceProjection`](../../lib/orbital_dynamics/resource_projection.ex) model battery/storage from declared activity hints; catalog limits say no subsystem simulation or continuous propagation. | Time-indexed battery/storage state that can make a branch candidate infeasible before selection. | Depends on 5, 8, 9, 18. **W1-D:** immutable battery/recorder `resource_state_trace.v1` with before/after activity state. **Decision:** compute here or import digital-twin state. |
| 7 | **Ground network/communications — L3.** Contract: broad. Fidelity: declared calendars and fixed-rate capacity. | [`LinkCapacity`](../../lib/orbital_dynamics/communications/link_capacity.ex), [`ContactAllocation`](../../lib/orbital_dynamics/communications/contact_allocation.ex), and [`StationCalendar`](../../lib/orbital_dynamics/communications/station_calendar.ex) are artifact-only; catalog limits say no link budget/provider reservation. | Source-bound data rate from range/elevation and declared terminal/link parameters, consumed by allocation and downlink completion. | Depends on 3-6, 9, 18. **W2-C:** one-way, one-mode downlink budget used only when supplied. **Decision:** ownership of link and provider truth. |
| 8 | **Activities/timelines — L4.** Contract: broad. Fidelity: artifact-operational. | [`Timeline`](../../lib/orbital_dynamics/timeline.ex) and [`TimelineFeedback`](../../lib/orbital_dynamics/timeline_feedback.ex) cover lifecycle, integrity, preservation, diffs, transitions, and realized reconciliation without schedule mutation. | Reapplying the same feedback/transition batch to a named prior revision must reproduce the replacement revision or report a revision conflict. | Depends on 13, 15, 17, 20. **W2-D:** add `timeline_revision.v1` identity to transition reports and one idempotent replay test; no store. |
| 9 | **Constraints/scoring — L3.** Contract: broad. Fidelity: planner-local, heuristic, uncalibrated. | [`CampaignLocal`](../../lib/orbital_dynamics/constraints/campaign_local.ex) evaluates after candidate generation; [`ModelLimits`](../../lib/orbital_dynamics/campaign_planner/model_limits.ex) says no solver and not calibrated from outcomes. | Typed hard feasibility consumed before ranking and impossible to outweigh with positive score, with one reason preserved through recommendation. | Depends on 6-7; feeds 10, 12-14. **W2-E, reserved explainable-search lane:** promote one resource/downlink constraint to candidate eligibility; base-state recommendation only. |
| 10 | **Search/optimization — L2.** Contract: medium. Fidelity: grid/Monte Carlo plus greedy. | [`Optimizer`](../../lib/orbital_dynamics/optimizer.ex) declares greedy per-scenario selection, no cross-scenario allocation, no MILP/CP-SAT, and Pareto/ranking summaries that do not search. | Explore beyond greedy first fit with a bounded trace of pruning, incumbent replacement, and termination. | Depends on 6-7 and 9; feeds 12-14. **W3-A, reserved explainable-search lane:** opt-in bounded beam search, retaining greedy default. **Decision:** improvement, bounded-gap, or optimum claim. |
| 11 | **Planning-state refresh — L4.** Contract: very broad. Fidelity: deterministic with precomputed/thin physical inputs. | [`CandidateRefresh`](../../lib/orbital_dynamics/candidate_refresh.ex) replays broad state/feedback/report evidence; catalog limits say refreshed events are precomputed and filters are thin. | Refresh itself propagates accepted state and regenerates events under explicit model/provider policy before building candidates. | Depends on 2-9, 17-18; feeds 13-14. **W3-B:** opt-in refresh runner for one declared propagation/event bundle, preserving the precomputed path. |
| 12 | **V1 campaign planning — L4.** Contract: very broad. Fidelity: end-to-end greedy prototype. | [`BuildOrchestration`](../../lib/orbital_dynamics/campaign_planner/build_orchestration.ex) produces candidates, ranked timelines, resources/comms/objectives, review, and import through `Optimizer.greedy_timeline_contract/3`. | V1 selection must consume hard feasibility and the chosen search contract rather than repair infeasibility after ranking. | Depends on 5-11, 15, 17-18. **W4-A:** opt-in new optimizer with emitted search trace; prove default greedy artifact stability. |
| 13 | **V2 rolling repair — L4.** Contract: very broad. Fidelity: end-to-end artifact repair. | [`RepairOrchestration`](../../lib/orbital_dynamics/campaign_planner/repair_orchestration.ex) handles realized state, protection, refresh, constraints, resources/comms, and review/import; [`repair_determinism_test.exs`](../../test/orbital_dynamics/campaign_planner/repair_determinism_test.exs) covers reproducibility. | Accepted orbit-state change must regenerate opportunities and change eligible remaining-horizon replacements while locked/executed work survives. | Depends on 8, 11-12, 15, 17-18. **W4-B:** one end-to-end shifted-access repair fixture proving refresh plus preservation. |
| 14 | **V3 strategy/orchestration — L4.** Contract: very broad. Fidelity: heuristic branch generation/ranking. | [`StrategyOrchestration`](../../lib/orbital_dynamics/campaign_planner/strategy_orchestration.ex) runs branch-local V2 repair. The [`canonical V3 artifact`](../../study_results/leo_constellation_campaign_strategy_v3.json) has 27 branches and explicitly heuristic, uncalibrated model limits. | Apply hard blockers before score order and emit “no recommendable branch” when every branch is infeasible/policy-blocked. | Depends on 9-13 and 15. **W4-C:** typed recommendation eligibility plus counterfactual for the highest-scoring rejected branch. **Decision:** blockers versus reviewable risks. |
| 15 | **Policy/safety/authority — L4.** Contract: broad. Fidelity: static classification. | [`Policy`](../../lib/orbital_dynamics/policy.ex) provides bundles, selectors, decisions, escalation, and no-execution boundaries; catalog limits say no external authority lookup/workflow. | Bind every eligibility/approval result to immutable authority revision, effective time, source, and stale/missing behavior. | Depends on 8, 12-14, 17, 20, 22. **W1-E:** `authority_context.v1` copied through decision/recommendation/review/import; no external lookup. **Decision:** authority source and auto-approval. |
| 16 | **Future V4+ — L0.** Contract: none. Fidelity: deliberately deferred. | [`CampaignPlanner`](../../lib/orbital_dynamics/campaign_planner.ex) and the catalog expose V1/V2/V3 only; no V4 entry point exists. | No Level 5 behavior is missing here; the gap is an activation gate preventing V4 scope from displacing Level 5 work. | Depends on Level 5 exit review. **W5-D:** short ADR defining V4 activation/ownership criteria. **Decision:** confirm deferral. |
| 17 | **Reproducibility/artifacts/audit — L4.** Contract: very broad. Fidelity: strong artifacts, partial recovery. | [`study.run --resume`](../../lib/mix/tasks/orbital_dynamics.study.run.ex) validates and reuses a complete artifact through [`ResultSet.Artifact`](../../lib/orbital_dynamics/result_set/artifact.ex); it does not resume partial work. | Resume interrupted scenario/chunk work from integrity-checked partial output and match uninterrupted semantic output. | Depends on 19 and 22. **W1-F, reserved resumable-execution lane:** versioned completed-scenario/hash checkpoint plus one interrupted local recovery test; base-state recommendation only. |
| 18 | **Validation/verification — bounded L5.** Contract: very broad. Fidelity: external numerics are exact-claim scoped. | The content-bound [Orekit event case](../../priv/validation/external_truth/orekit_13_1_7_leo_j2_drag_access_eclipse/README.md) covers one exact state/access/eclipse path; the separate [D3 state corpus](../../priv/validation/external_truth/orekit_13_1_7_j2_drag_envelope/README.md) covers eight independently generated force/orbit/drag/step/duration cases with counterfactual oracle tests. | No missing validation behavior inside those declared exact and bounded sample claims. Continuous combinations, other providers/models, operational acceptance, and flight certification remain explicitly unpromoted. | Depends on 1, 3-5, 17. **W3-C delivered:** Orekit 13.1.7 truth bundles with exact content/provenance/tool/data/tolerance identities. |
| 19 | **Performance/distribution — L3.** Contract: medium. Fidelity: prototype distribution/benchmarks. | [`ScenarioRunner`](../../lib/orbital_dynamics/scenario_runner.ex) supports local/distributed Task.Supervisor chunking and [`OperationalScale`](../../lib/orbital_dynamics/operational_scale.ex) records targets; no worker-failure recovery is proven. | Kill one worker, reuse successful chunks, retry failed work, and prove deterministic output and retry accounting. | Depends on 17. **W3-D, reserved resumable-execution lane:** fault injection plus execution-report retry/reuse summary. **Decision:** scale, topology, SLO, retry budget. |
| 20 | **Cadence boundary — L4.** Contract: very broad. Fidelity: producer-side artifact handoff. | [`CadenceImport`](../../lib/orbital_dynamics/cadence_import.ex) and [`OperatorReview`](../../lib/orbital_dynamics/operator_review.ex) cover extensive typed handoff with no writes; no consumer conformance harness exists here. | Consumer dry-run accepts V3, preserves identity/authority, and returns idempotency/conformance evidence without writes. | Depends on 12-15, 17, 22. **W5-A:** in-memory fake Cadence adapter protocol/conformance test. **Decision:** adapter owner and review-row volume budget. |
| 21 | **Developer/user experience — L3.** Contract: broad. Fidelity: usable but uneven stable workflow. | [`campaign.run`](../../lib/mix/tasks/orbital_dynamics.campaign.run.ex), [`capabilities`](../../lib/mix/tasks/orbital_dynamics.capabilities.ex), lint/export/report tasks, and examples exist; API docs and semantic coverage remain uneven. | One machine-checked command path produces V1/V2/V3 from pinned examples and reports capability/schema versions and actionable failures. | Depends on 12-14, 17, 20. **W3-E:** generated Level 5 workflow index and example/link/contract smoke gate; no new CLI. **Decision:** supported public surface. |
| 22 | **Security/trust/external inputs — L3.** Contract: broad. Fidelity: provenance/shape controls, not authenticity. | [`accepted_state_contracts.ex`](../../lib/orbital_dynamics/schema/accepted_state_contracts.ex) and provider/realized contracts require many trust boundaries and stable IDs, but no content authenticity or backend sandbox exists. | Reject file-backed mission state/provider/policy inputs whose bytes do not match declared content identity before planning. | Depends on 17; first consumers are 2, 4, 7, 15, 20. **W1-G:** SHA-256 verification for one orbit-data and one provider-table input; defer signatures. **Decision:** signing authority and Level 5 versus Level 6 gate. |

## Dependency-aware parallel waves

Wave 0 resolves product contracts: the fidelity envelope (1-5, 18), resource
and link ownership (6-7), search/eligibility claims (9-10, 14), authority (15),
V4 deferral (16), runtime SLO (19), adapter ownership/review volume (20), public
surface (21), and signing boundary (22).

Shared schema-registry, catalog, and fixture-rollup files are a serialized
integration seam. Parallel lane owners should keep their implementation/tests
separate and let one integration owner update those shared files after lane
patches.

| Wave | Low-overlap ownership lanes | Exit condition |
|---|---|---|
| **W1 — state and integrity** | `1 Frame`, `2 OrbitData`, `4 Environment`, `6 Resource`, `15 Policy`, `17 ResultSet/StudyRun` (reserved), `22 input verification` | Explicit state/provider/authority/content/checkpoint contracts are independently testable. |
| **W2 — analytical behavior** | `3 Propagators`, `5 EventDetectors` (reserved), `7 Communications`, `8 Timeline`, `9 Constraints` (reserved) | Decision inputs produce bounded numerical or hard-feasibility evidence. |
| **W3 — orchestration engines** | `10 Search` (reserved), `11 CandidateRefresh`, `18 Validation fixtures`, `19 Runner recovery` (reserved), `21 workflow/docs` | Search/refresh/recovery operate against the new contracts and the selected fidelity path has external evidence. |
| **W4 — planner consumption** | `12 BuildOrchestration` then `13 RepairOrchestration` then `14 StrategyRecommendation` | V1 consumes feasibility/search, V2 proves fresh-state repair, and V3 cannot recommend an ineligible branch. |
| **W5 — boundary and scope** | `20 Cadence conformance`, `16 V4 activation ADR` | Consumer-side dry-run passes; V4 remains gated by the Level 5 exit review. |

## Drift and prioritization

- Many capability pages use **implemented** to mean an API or artifact family
  exists. That is not a Level 5 claim. Domains 2, 5, 6, 10, 17, 18, and 22 also
  describe their own behavior as partial.
- Domain 17 still lists resumable studies as later work, while live code already
  reuses a complete matching artifact. The real gap is partial checkpoint and
  recovery.
- Domain 21 still asks for a schema-validation CLI even though schema lint/export
  tasks exist. The gap is a stable verified workflow and compatibility contract.
- Ground-network prose lists contention resolution as later, while live code has
  advisory deterministic resolution. The gap is calibrated/provider-authoritative
  resolution and reservation.
- Level 5 prose says combined futures remain, while V3 already has deterministic
  opt-in combined branches. The gap is robust joint-future generation and
  calibrated eligibility/selection.
- The last 80 commits are dominated by CampaignStrategy/CampaignRepair source
  binding. They improve contract fidelity and auditability, not numerical or
  operational fidelity unless a planning decision changes under validated input.

The queue priority is therefore: **hard feasibility and validated decision
inputs first; executable refresh and recoverability second; planner consumption
third; consumer conformance last.** Until those proofs land, the honest claim is
“broad, deterministic, audit-friendly Level 5 artifact prototype with L3-L4
planning behavior and L2-L3 physical/operational fidelity.”
