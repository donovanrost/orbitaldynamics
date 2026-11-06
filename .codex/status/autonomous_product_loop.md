# Autonomous Product Loop Status

Overall maturity target:
Bring all 22 feature domains to credible Level 5 readiness inside their
explicitly declared prototype, numerical, and operational envelopes before
activating Level 6 scope.

Current slice:
Level 5 implementation closeout documentation from integrated baseline
`28fd92e42ccd34d41e4c82257064ca1cca273156`.

Status:
Implementation closure is recorded for all 22 bounded domain slices, including
the independently approved D3 Orekit envelope repair. The prior four-partition
gate passed at the pre-D3 baseline `b88f38bb`; the new four-partition gate at
exact `28fd92e4` also passed. External acceptance remains open.

Evidence boundary:
Level 5 means credible readiness inside the declared prototype, numerical, and
operational envelopes. It is not a production-grade or external acceptance
claim. V4 remains gated because the ADR requires named external approvals,
owners, and resources; implementation closure does not activate V4.

Closeout evidence:
- The historical audit remains in
  `docs/feature_set/level5_domain_matrix.md`; the integrated 22-domain evidence
  ledger is in `docs/feature_set/level5_implementation_closeout.md`.
- Every supplied domain implementation commit, D1 through D22, is contained in
  the closeout baseline.
- Cross-domain approval binding is integrated through `585e0a24` and
  `b0411cd5`.
- Cross-domain deterministic fixture coverage is integrated through
  `31c57b3d`, `41d582e5`, and `b88f38bb`.
- The original D3 implementation `a0423071` is paired with independently
  validated Orekit source `c8455c3b` and merge `28fd92e4`.
- D3 accuracy is bounded to eight independently generated cases and 200 sampled
  Cartesian states. Unsampled continuous combinations, broader arithmetic
  guard bounds, other providers/frames/time scales/backends, operational
  acceptance, and flight certification remain outside the claim.
- The checked capability catalog records 127 contracts.
- The deterministic reference rollup records 209 sorted passing rows.
- Curated typed fixtures cover 126/127 contracts; only the rollup self-report,
  `validation_reference_fixture_report.v1`, is deliberately excluded.

Verification:
- Domain-focused implementation and integration evidence is mapped in the
  closeout ledger.
- Documentation links and consistency are checked as part of this closeout
  slice.
- The following four partition results are pre-D3 evidence from exact
  `b88f38bb`; they are not the post-D3 gate.
- Partition 1: **PASS**, 1,286 total, 1,286 passed, 0 failed, 0 excluded. The
  closeout ledger records the exact ExUnit/wall timings, exit status, revision,
  environment, cleanliness, rerun, and diagnostic evidence supplied for that
  partition.
- Partition 2: **PASS**, 1,290 total, 1,290 passed, 0 failed, 0 excluded. The
  closeout ledger records the exact ExUnit/wall timings, exit status, revision,
  environment, cleanliness, rerun, and diagnostic evidence supplied for that
  partition.
- Partition 3: **PASS**, 2,113 total, 2,113 passed, 0 failed, 0 excluded
  reported. The closeout ledger records the exact ExUnit/wall timings, exit
  status, revision, environment, rerun decision, diagnostics, cleanliness, and
  no-edit/no-commit evidence supplied for that partition.
- Partition 4: **PASS**, 1,276 total, 1,276 passed, 0 failed, 0 excluded. The
  closeout ledger records the exact ExUnit/wall timings, exit status, revision,
  environment, cleanliness, rerun, and diagnostic evidence supplied for that
  partition.
- Pre-D3 full-suite baseline at exact `b88f38bb`: **PASS**; 5,965 total, 5,965
  passed, 0 failed, 0 excluded reported across the four summaries. All four
  invocations exited 0. This is not the post-D3 repository-wide gate.
- D3 source-focused gate: 60 passed; verifier gate: 647/647 passed; second
  independent review: 37 passed.
- D3 Orekit regeneration was byte-identical at raw-result SHA-256
  `5398bf4f44ace3b9928d069b768690aa14fd75a91b7560d22b845689afcddc38`.
  Generated artifacts were byte-identical, and schema lint reported 0 errors
  and 0 warnings.
- Post-D3 partition 1 at exact
  `28fd92e42ccd34d41e4c82257064ca1cca273156`: **PASS**, 1,282 total, 1,282
  passed, 0 failed, 0 excluded; exit 0. The closeout ledger records the exact
  timing, one-invocation, cleanliness, rerun, and diagnostic evidence.
- Post-D3 partition 2 at exact
  `28fd92e42ccd34d41e4c82257064ca1cca273156`: **PASS**, 1,292 total, 1,292
  passed, 0 failed, 0 excluded; exit 0. The closeout ledger records the exact
  timing, uninterrupted-invocation, cleanliness, rerun, and diagnostic
  evidence.
- Post-D3 partition 3 at exact
  `28fd92e42ccd34d41e4c82257064ca1cca273156`: **PASS**, 2,114 total, 2,114
  passed, 0 failed, 0 excluded; exit 0. The closeout ledger records the exact
  timing, seed, timeout, cleanliness, rerun, and diagnostic evidence.
- Post-D3 partition 4 at exact
  `28fd92e42ccd34d41e4c82257064ca1cca273156`: **PASS**, 1,282 total, 1,282
  passed, 0 failed, 0 excluded; exit 0. The closeout ledger records the exact
  timing, uninterrupted-run, cleanliness, retry, and diagnostic evidence.
- Overall post-D3 internal full-suite gate: **PASS**; 5,970 total, 5,970 passed,
  0 failed, 0 excluded reported across the four summaries. All four exact-head
  invocations exited 0 (`p1=1282`, `p2=1292`, `p3=2114`, `p4=1282`).

Implementation closure:
- D1-D10: frame transforms, OEM interpolation, J2-plus-drag propagation with
  independently validated eight-case/200-state sample-envelope evidence,
  source-bound environment, access refinement, resource traces, link budget,
  timeline replay, hard feasibility, and bounded local search are integrated.
- D11-D15: executable refresh, V1 search selection, V2 shifted-access repair,
  V3 hard eligibility, and authority context are integrated.
- D16-D22: the V4 gate, checkpoint recovery, bounded external-reference
  validation, deterministic retry, Cadence dry-run conformance, checked
  workflow, and file-input identity are integrated.

Remaining external acceptance:
- Record authoritative integrated verification with pinned inputs, environment,
  revisions, results, and named approvers.
- Obtain operational-model and truth-data approval for sources, coverage,
  tolerances, and update policy.
- Obtain Cadence consumer, mission-operations/authority,
  product/architecture, and program/resource decisions required by the
  [V4 activation ADR](../../docs/feature_set/v4_activation_gate_decision.md).
- Record a named V4 delivery owner and approved compatibility, staffing,
  compute, data, verification, and operations resources before considering V4
  activation.

Next action:
Present the bounded implementation and post-D3 internal full-suite evidence
package to the named external owners. Do not translate implementation closure,
focused D3 verification, or the post-D3 full-suite pass into external
acceptance or V4 activation.

Blocked:
No implementation or full-suite reporting slice is open. External acceptance
decisions remain outstanding.

Notes:
This closeout changes documentation/status only. It does not merge, push,
modify generated/runtime artifacts, or activate V4.

## Configurable reference mission queue 2026-11-04

The user authorized progressing through the ten slices in
[development_queue.md](../../docs/mission_planning/development_queue.md) until
feedback is needed. This is a separate development lane from the historical
Level 5 closeout and does not change its external-acceptance status.

Current slice: complete — all ten configurable reference-mission slices.
Review: parent performs bounded local review; no delegation requested.
Publication: preserve existing uncommitted work; no remote publication requested.

Reference-mission slice 1 complete: independent wheel RK4 bundle and offline
comparison command; 16/16 numerical rows and focused content/conservation checks
passed. Local review fixed unknown-status classification. Starting slice 2,
independent wheel accounting for saved plans. Historical closeout is unchanged.

Reference-mission slice 2 complete: stationary independent wheel accounting and
execution handoff, including coherent semantic mutation rejection; 29 focused
tests pass. Local review added frame/epoch and array-count checks. Moving paths
remain unsupported by this checker. Starting slice 3, whole-search work budgets.

Reference-mission slice 3 complete: scoped whole-search callback counters and
shared hard cap, failure accounting, incumbent retention and one/two-spacecraft
benchmark. Full fast suite 5,399 passed/1,148 excluded; endpoint duplicate-work
review fix then passed 12 focused tests and preserved the full battery-only
report. No context leaks or unverified adoption on cap exhaustion. Starting
slice 4, time-bounded activity/mode availability.

Reference-mission slice 4 complete: interval/type/mode outages and restoration,
protected conflicts and independent calendar checking. Seven focused tests and
four-step operations/independent checks pass. Full fast suite 5,406 passed/1,148
excluded. Starting slice 5, offline observed-state quality and provenance.

Reference-mission slice 5 complete: quality policy, provenance/freshness/bounds
gates, synthetic-role stamping and independent quality checking. Seven focused
tests and 5,413 fast-suite tests pass (1,148 excluded). Local review verified
missing quality rejects safely, observed-only policy never promotes synthetic
state, and uncertainty screening is not a robust-feasibility claim. Starting
slice 6: preserve in-progress activity prefixes and non-abortive continuations.

Reference-mission slice 6 complete: explicit original-profile continuation,
executed prefixes, exact protected tails and single-charge/single-completion
history. Eleven focused tests and full fast suite 5,424 passed/1,148 excluded.
Native five-cycle and independent checks pass; motion/wheel references pass.
Local review fixed UTC boundary cancellation and a fictitious terminal roundoff
slew. Starting slice 7, explicit rolling-horizon extension and coverage.

Reference-mission slice 7 complete: explicit finite provider coverage, saved
overlap predictions, new demand, actual-deadline expiry and preserved lineage.
Three extension cases and 57 lifecycle/validation tests pass; full fast suite
5,427 passed/1,148 excluded in 264.4 s. Three-cycle native/independent example
executes past the original end. Local review added independent extension guards.
Starting slice 8, bridge existing communications artifacts into service planning.

Reference-mission slice 8 complete: reuse station calendar/contact allocation/
command window contracts, screen deadlines/lead time and station/spacecraft
contention, retain explicit observed/synthetic receipts. Seven focused tests,
three-cycle native/independent replay and 5,434 fast-suite tests pass (1,148
excluded, 258.2 s). Local review added contact busy intervals and original-start
checks. Starting slice 9, declared lumped thermal evolution and cooldown.

Reference-mission slice 9 complete: linear lumped thermal resource, analytic
interval extrema, cooldown, temperature packets/quality and independent history
checks. Eight thermal tests and full fast suite 5,442 passed/1,148 excluded in
274.9 s; final advance/thermal regression 12 passed. Four-cycle replay/independent
validation pass. Local review fixed epoch numeric equivalence and resource-state
invariant coverage. Starting slice 10, integrated constellation assessment.

Reference-mission slice 10 complete: five-case multi-spacecraft assessment,
operator report, preserved artifacts and compact durable observations. All native
expectations met; independent fixed-attitude checks passed and moving/stopped
cases remain partial. Full fast suite 5,445 passed/1,148 excluded (275.2 s);
final 11 focused tests pass after null-row and work-category reporting fixes.
Local review distinguished simulated execution from the accepted ledger on a
failed advance and retained complete structured failed-search work. All ten
selected slices are complete. No remote publication, commit or historical maturity
acceptance status changed. See the queue and integrated assessment for explicit
assumptions, checkpoint sensitivity and remaining engineering/validation gaps.

## Checkpoint-faithful replay follow-up complete

User authorized implementing the next recommended slice. Unchanged execution now
follows source-bound saved motion through arbitrary phase checkpoints, preserves
original clocks/modes and carries exact modeled boundary state into replanning.
Contiguous acquisition already underway retains its exact destination activity;
braking separated by a later idle hold does not lock that future activity.
Synthetic prediction/execution provide explicit parent-motion confirmation;
unconfirmed/mismatched state or conflicting protected work cannot silently abort
the maneuver. Declared skips retain a labeled counterfactual policy.

Independent reconstruction uses no producer motion/history helpers; quaternion
boundary tolerance is 1e-12 per component. Coherent source-phase mutation fails
chain validation. New 11-checkpoint example passes native checks; independent
physics remains partial for moving wheels and varying-phase battery loads. Both
illumination checkpoint scenarios now deliver six services/value 150.

Validation: seven new motion tests; 62 targeted lifecycle/validation tests;
18 focused rigid/motion tests; final seven motion tests; full fast suite
5,452 passed/1,148 excluded in 292.4 s. Frozen numerical motion baseline passes;
latest independent illumination chains have no error issues and retain their
explicit wheel-dynamics gap. Formatting and whitespace checks pass.

Parent local review covered source binding, exact destination pins, repeated
clipping, one-sided original-clock torque checks, phase/mode loads, idle hold
freedom and compact bounded records. No subagents, rig, commits or pushes used.
Artifacts and limitations: docs/mission_planning/checkpoint_replay.md and
checkpoint_replay_observation.json. Historical maturity acceptance is unchanged.

## Independent execution acceptance follow-up complete

User authorized separating execution-state acceptance from replacement planning.
Validated execution checkpoints are persisted before planning, preserve finite
declared state even when future planning fails, and bind to the original parent.
Algorithm-only retries preserve ledger, budgets, receipts, continuations and motion
without another execution replay. Failed plans are stale_pending_replan; the
offline scenario driver blocks further execution until an explicit retry produces
a replacement. Separate disk accept/plan commands and operations v2 distinguish
accepted execution epoch/history from the stored plan boundary/history.

Independent validation reconstructs checkpoint state and controls without producer
acceptance helpers and rejects coherently rehashed state changes. Stationary
accept/fail/retry/finish passes native and independent checks. Three-spacecraft
example accepts three completions at +200 s despite a 1,000-callback planning
failure, retries from that checkpoint, then closes all six services/value 150.
No independent error issues; moving-wheel physics remains partial.

Validation: full fast suite 5,460 passed/1,148 excluded (263.9 s), before final
format marker/schema refinements; final focused 20 passed (11.6 s). Parent local
review covered checkpoint persistence, immutable retry constraints, finite state
outside operating limits, rejected quality, command receipt/motion preservation,
no double costs/completions, pending-state guards and independent reporting.
No subagents, rig, commits or pushes used. Historical maturity acceptance unchanged.
Evidence: docs/mission_planning/execution_checkpoints.md and
execution_checkpoint_observation.json.

## Independent moving-resource validation follow-up complete

User authorized the recommended independent moving-wheel and changing-phase
battery validation slice. Resource evidence saves exact wheel kinematics. An
independent explicit rotation-matrix/global impulse checker validates rotor and
body momentum, Euler motor demand, all cadences, samples, limits, margins and
execution handoffs. Original-clock phase reconstruction handles clipped maneuvers.
Fixed inputs and matching tracking profile epochs bind poses; intermediate
tracking poses remain declared evidence. No orbit/pointing/continuous-feasibility
claim is made. Battery accounting independently integrates mode plus phase loads
with efficiency, capacity clipping, curtailment/unmet demand, sample coverage and
reserve checks. Earlier moving artifacts lacking kinematics remain partial.

Validation: full fast suite 5,466 passed/1,148 excluded (336.1 s, assessment ran
concurrently). Final focused 33 tests passed; six final new mutation/reference
tests passed after initial-frame, quaternion and cadence refinements. Eleven-step
motion and constellation retry artifacts pass independent checks. Five-case
assessment expectations are met: four completed cases independently pass; stopped
work-cap case stays partial with three accepted completions and a stale plan.
Both illumination cases finish six services/value 150. Independent checker
equations agree with all eight frozen body-frame RK4 cases within 1e-5 Nms/Nm
at 0.25-second intervals. Formatting and whitespace checks pass.

Parent local review covered no producer imports, distinct global momentum
accumulation, phase/profile/initial-state bindings, sign-equivalent quaternions,
one-sided accelerations, complete cadences and intervals, diagnostic mutations,
state handoff and no replay/debit on retry. No delegation, rig, commits or pushes.
Historical maturity acceptance is unchanged. Durable evidence:
docs/mission_planning/moving_resource_validation.md and
moving_resource_validation_observation.json.

## Environment validation reuse follow-up complete

User asked to reset the Rust experiment and pursue repeated validation. Discarded
all uncommitted experiment source/limit changes at 78a30e61; removed native build
outputs and stale experimental BEAM modules. Renamed the clean experiment branch
to `experiment/environment-validation-reuse`. Prior local timing data remains in
ignored tmp only; no Rust source or new Rust dependency remains.

Implemented a one-entry process-local successful admission cache, keyed by the
complete exact immutable dataset and local validator function/code identity.
Changed/copied-inexact datasets still run the original file-evidence and semantic
gates. Failed admissions do not replace successful state. Per-query body/frame/
time/interpolation/coverage gates remain active. Already-admitted identity emitters
use the pinned digest rather than recomputing it. Local function identity binds
the executing code version even during an upgrade; one old function reference
may remain until entry replacement/process exit. Cache bookkeeping is not a
security sandbox against arbitrary code executing in the same process.

Validation: five new trace tests, 14 provider/new checks passed, and full fast
suite 5,471 passed/1,148 excluded in 271.8 s. Existing physics/provider targeted
checks pass. Actual module reload forces a fresh semantic hash. Tests prove one
hash for unchanged/copy-exact data, strict numeric types, failed admissions, one
entry per process, correct file provenance and query guards. Formatting and
whitespace checks pass.

Two alternating-order before/after observations on the original six-asset/nine-
request study: planning medians 19.49 -> 6.37 s (3.06x), persisted-report workflow
21.15 -> 8.04 s (2.63x). All four full reports independently streamed and hashed
byte-identically. Original numerical controls/work ceilings retained; no budget
relaxation, changed search, skipped physics or physical validation promotion.

Parent local review covered admission/emitter control flow, exact immutable
matching, code-upgrade races, bounded successful-only retention, process lifetime,
trace barriers/cleanup, old-provider isolated benchmarking and timing boundaries.
No subagents, rig, commits or pushes. Work remains uncommitted on the new branch;
historical maturity acceptance unchanged. Evidence:
docs/mission_planning/environment_validation_reuse.md and
environment_validation_reuse_observation.json.

Follow-up: the user requested committing this completed slice and merging it
into main. The implementation is unchanged from the verified result above; the
existing 5,471-test result and exact-report comparison apply. No remote push was
requested.

## Follow-up: 100-spacecraft scaling and next hotspots

Complete analysis/profiling slice on main after a8380c7c. Added an opt-in bounded
6–100-spacecraft benchmark with explicit demand, memory/runtime guards, compact
saved summaries and optional statistical stack sampling. Numerical fidelity and
physical checks remain enabled; finite analysis/subsystem admission ceilings
were expanded, with explicit larger budgets only in the scaling fixture. Separate
saved-operations/replay asset bounds are unchanged.

Fixed nine-request observations at 6/25/50/100 spacecraft: 7.62/18.74/40.04/73.61
seconds and 0.28/1.07/1.79/3.20 GB sampled VM memory. All complete with supported
planning/resources. Profiled/unprofiled 100-asset inputs and compact result
digests match; this does not establish full diagnostic-report identity. At
100 assets/25 requests the sampled 6 GB guard stops the case after 162.534 s,
observing 6.160 GB; no completed plan is claimed.

Repeated JSON normalization appears in 57.2% of inclusive 100-asset stack samples;
tabular Earth-orientation preparation appears in 18.1%. Percentages overlap and
are not exclusive CPU attribution. Retained dense per-pair evidence is the first
memory target, followed by duplicate model-result normalization and prepared
Earth-orientation data. No optimization implemented here; future changes must
preserve changed/raw-input validation, audit failures and result semantics.

Six new harness tests; focused checks 10 passed/1 excluded. Full fast suite:
5,477 passed/1,148 excluded in 255.5 s. Parent local review covered fixture nesting,
controls, task termination, saved failure/stop behavior, numerical fidelity,
compact parity scope and sampling limits. No agents, rig, commit or push used.
Historical maturity acceptance unchanged. Evidence:
docs/mission_planning/constellation_scaling.md and
constellation_scaling_observation.json.

## Follow-up: compact opportunity diagnostic retention

Complete. The existing core include_samples:false option now also omits dense
event scans and raw complete-model observations after scalar, unknown-region,
endpoint and full-model contradiction audits finish. Temporary model samples
still drive identical counts and window checks before release. Windows, root
brackets, unknown intervals, failures/reasons, counters, first contradictions
and first complete failed sample per check are retained, with explicit retention
metadata. Full diagnostics remain the core/reference default; reference callers
can select the boolean option. Scaling defaults compact and accepts an explicit
--full-diagnostics switch to reproduce historical retention. No model validation,
physics checks, numerical controls, budgets or subsystem histories were removed.

100 spacecraft/nine requests: 73.61 -> 66.80 seconds, sampled VM memory
3.20 -> 0.76 GB (76.2% lower), with equal input and compact result digests.
100 spacecraft/25 requests now finishes all 25 services with supported planning
and resources in 167.05 seconds, sampled VM peak 1.88 GB, versus the prior
profiled case stopping at 6.16 GB. All 900/2,500 pair searches complete under the
declared search policy. These are single local observations; prior demand-case
elapsed time is not a completed or unprofiled speed baseline.

Six-spacecraft full/compact canonical outcome projections match after removing
only omitted dense diagnostics, retention metadata and the include-samples flag.
The projection retains every other report field, including complete subsystem
histories. Encoded report size falls 72.83 -> 19.45 MB. This is distinct from
100-asset compact-summary parity and does not establish physical accuracy.

Two new analytic runner tests cover outcome parity across unknowns/source gaps,
margin rejection, hidden contradictions, first-failure provenance and unchanged
budget/declaration errors. A reference-adapter test rejects non-boolean controls.
Focused opportunity/scaling/benchmark checks: 25 passed. Full fast suite:
5,480 passed/1,148 excluded in 264.8 s. Formatting/whitespace checks pass. Local
review covered audit ordering, bounded retained examples, query accounting,
default/full controls and report-parity scope. Repeated JSON validation and
Earth-orientation preparation remain future CPU targets. No agents, rig, commits
or pushes used; historical maturity acceptance unchanged. Evidence:
docs/mission_planning/opportunity_retention.md and
opportunity_retention_observation.json.

## Follow-up: planning memory attribution

Complete dev-only measurement slice. Added an isolated opt-in profiler with
normal sampling, post-GC retained-term sizing and GC-traced/bracketed sampling.
Stage hooks are compiled only into its own VM, with exact anchor checks and
restoration; production source/build artifacts are not rewritten by the hooks.
Three sequential 100-spacecraft/25-request diagnostic passes complete supported
planning/resources and match the prior exact input and compact result digests.
These are diagnostic runs, not performance or independent-physics validation.

Natural peak 1.889 GB occurs in final transition/horizon path checking;
opportunity generation peaks at 284 MB. At candidate-search completion the
path cache has 388,668 entries/260.8 MB of reachable heap terms. Final checks
grow it to 613,893 entries/411.0 MB; the whole evaluator cache is 457.7 MB,
including a 61,260-entry pointing/physical cache measuring 36.9 MB. Cached full
checks/metrics are retained across rejected starts and final paths.

The completed report measures 302.4 MB of reachable terms, including overlapping
horizon (143.1 MB), resource (85.8 MB), analysis (49.2 MB) and other evidence.
Component sizes overlap and are not additive. Post-scheduler collection shrinks
the worker from 1,039 to 368 MB in the retained pass. The GC-traced follow-up
observes 1.898 GB VM then 811 MB after worker inspection about 134 ms later;
145 major/24,303 minor collections complete. Sequential snapshots and the
largest-heap trace subset do not assign exact peak bytes to copying space, but
show substantial transients around the smaller live workspace.

Next memory target is path-cache lifetime, preserving evidence and evaluation-
budget semantics when considering eviction; horizon/resource evidence is a
separate retained-data target. No optimization or production GC change made.
Six-spacecraft retained/rule-breakdown and GC smoke runs pass with known result
digests. All three 100/25 comparisons pass. Formatting/whitespace checks pass;
prior 5,480-pass/1,148-excluded suite applies to unchanged production code and
was not rerun for this dev-only script. No agents, rig, commits or pushes;
historical maturity unchanged. Evidence:
docs/mission_planning/planning_memory_attribution.md and
planning_memory_attribution_observation.json.

## Follow-up: shorten path-cache lifetime

Complete. Path-rule memoization is partitioned by asset, preserving the original
cache keys and hits. Final horizon verification drops each asset partition after
its last terminal-path query, including supported/violated/unknown outcomes. The
evaluator releases remaining entries before resource replay, including workflows
without a final horizon. Counters, sessions/provenance and complete report
evidence remain. Reopening a released partition fails instead of silently
spending more budget. Prepared initial caches remain immutable between trials;
no forced production GC, changed numerical controls or lighter report policy.

The complete six-spacecraft/nine-request reports before/after are exactly equal
as terms, without excluding any fields, digest
5ab2dc035d95e848246f95996fafc833916b39da8c548e82b2e10df86bf2735c.
Paired verifier reloads only baseline/current path runner, horizon and evaluator;
baseline copies match a8380c7c exactly, with the other retained/scaling changes
held equal. The six-asset retained diagnostic confirms 74,868 candidate cache
entries and zero entries before/after final resource replay, with unchanged
16,722,768-byte reachable report data. Logical release does not force immediate
reclamation of shared objects, old references or heap capacity.

100 spacecraft/25 requests completes all 25 services with supported planning and
resources. Inputs, controls and compact result digest match the prior run; exact
path count remains 613,893, now exposed separately from the summary digest.
Sampled peak VM memory 1.880 -> 0.722 GB (61.6% lower). Planning time is
191.44 vs prior 167.05 seconds; unchanged opportunity generation also slowed
146.87 vs 129.79 seconds. These are individual local observations, not a
controlled CPU attribution or speed-improvement claim.

Two new tests verify other-asset cache hits at an exhausted budget, unchanged
provenance/counters, release idempotence, disabled checking, reopening rejection
and final supported/violated/unknown evidence and budget-error behavior. Focused
path/resource/horizon tests: 27 passed. Full fast suite: 5,482 passed/1,148
excluded in 329.9 s. Formatting/whitespace checks pass. Local review covered final
path ownership, resource replay's lack of path queries, per-trial isolation,
exact keys/work accounting, snapshots and logical/physical memory distinctions.
No agents, rig, commit or push used; historical maturity acceptance unchanged.
Evidence: docs/mission_planning/path_cache_lifetime.md and
path_cache_lifetime_observation.json.

## Follow-up: native path/resource computation results

Complete first native-result slice. Built-in path/resource callbacks now build
CheckResult structs with atom outcomes, margins/units and native details. Result
admission validates each fresh callback without JSON normalization or rebuilding
its contents. Native structs/tuples/atoms can remain in metrics and resource
state; internal cache hits are reused without reconstructing results. Domain
invariants and conservative bounded native-data guards remain, with fresh forged
or modified values rejected. The optional eager new! constructor still admits;
built-in callbacks use raw native construction to avoid duplicate admission.

ReportData projects only at output/evidence ownership boundaries. Final terminal
and resource evidence is projected per asset and marked as completed output for
reuse at whole-report assembly; callback admission rejects these internal markers,
including forged/nested values. Finalization phases and the horizon loop use
tail-called ownership scopes/continuation so old cache versions are not retained
across subsequent phases. No forced production GC, validation trust flag, global
admission cache, changed physics or reduced-fidelity search was added.

The complete six-asset/nine-request report matches exactly, with every field
retained, digest 5ab2dc035d95e848246f95996fafc833916b39da8c548e82b2e10df86bf2735c.
Same-session planning 6.25 -> 4.89 s and scheduling 3.29 -> 2.01 s, with reachable
report storage 16.72 -> 15.93 MB. The final 100-asset/25-request case delivers
all 25 services with supported planning/resources, identical inputs/controls and
compact result digest, and the same 613,893 path evaluations. Observed planning
191.44 -> 155.53 s, scheduling 44.00 -> 25.85 s; unchanged opportunity generation
also varied 146.87 -> 128.34 s, preventing controlled total-CPU attribution.
Sampled peak VM memory 0.722 -> 0.881 GB is an explicit ~160 MB tradeoff. Earlier
monolithic/ownership variants reached 1.88–2.23 GB and prompted the final changes;
they are not the delivered measurement. Single local observations, not guarantees.

Eight new tests cover native payload preservation, report projection, forged
results, unknown margins, bounded/unsupported data, reserved output markers,
actual callback zero-JSON-normalization tracing, native resource state and
failure explanations. Focused checks: 77 passed. Final fast suite: 5,490 passed/
1,148 excluded in 241.8 s. Formatting/whitespace checks pass. Local review covered
fresh admission versus cache reuse, marker rejection, per-asset evidence closure,
error/budget propagation, output alias collisions and exact report/counter scope.

Mission Evaluation, event metadata, environment preparation and some outer
report maps remain for later migration. The user asked whether structs require
the same validation; generic recursive payload/text guards remain conservative
and can move toward output, while domain invariants stay at meaningful admission
or construction boundaries. Internal values do not need repeated validation.
No agents, rig, commits or pushes; historical maturity unchanged. Evidence:
docs/mission_planning/native_results.md and
native_results_observation.json.

## Follow-up: focused domain admission, deferred diagnostic checks

Complete. Fresh path/resource result admission now checks computational shape,
a proper nonempty list of up to 2,048 checks, unique valid-text IDs (1–256 bytes),
three-valued outcomes, finite bounded margins and valid paired units (1–64 bytes).
Reserved domain-field collisions are checked with fixed field lookups. The
resource model owns its state-domain invariants; generic state admission is a
map/struct container check. Existing physical frame/state/model checks remain.
No recursive diagnostic traversal runs at callback admission.

Raw metrics and captured resource states enter report evidence through internal
Pending payload references without traversal. Output projection recursively
validates those raw values, including payload limits, text and unsupported data.
Check details receive the same deferred output validation. Raw payload checks
reject nested Pending/Completed markers, and container checks reject either at
the root, preventing callback-controlled export bypass. State comparison runs
before report capture wrappers; no normalization cache or trusted result flag.
Reported malformed diagnostics fail report construction rather than becoming
physical infeasibility or a supported returned report. Discarded optional data
need not be scanned; model contracts/capture policies own diagnostic generation.

Whole six-asset reports remain exactly equal, digest
5ab2dc035d95e848246f95996fafc833916b39da8c548e82b2e10df86bf2735c.
Same-session planning 4.89 -> 4.78 s and scheduling 1.93 -> 1.85 s; identical
15,934,424-byte reachable report storage. The 100/25 case preserves inputs,
controls, compact result identity, 613,893 path evaluations and all 25 selected
services with supported planning/resources. Observed planning 155.53 -> 147.79 s,
scheduling 25.85 -> 24.28 s, sampled VM peak 0.881 -> 1.108 GB. This explicit
~227 MB memory tradeoff accompanies deferred capture references; exact peak
attribution was not profiled. Unchanged opportunity time also varied, so total
CPU changes are not controlled attribution or performance guarantees.

Two additional tests verify deferred payload rejection/marker isolation and
bounded domain lists/identifier/unit text. The existing actual-runner trace now
checks both JSON normalization and NativeData.validate!: zero calls during path
admission after preparation. Focused checks: 79 passed. Final fast suite:
5,492 passed/1,148 excluded in 258.0 s. Formatting/whitespace checks pass. Local
review covered raw-versus-owned output paths, all metric/state capture sites,
state-comparison ordering, immediate domain errors and deferred export failure.
No agents, rig, commits or pushes; historical maturity acceptance unchanged.
Evidence: docs/mission_planning/domain_admission.md and
domain_admission_observation.json.

## Commit follow-up

The user requested committing the accumulated 100-spacecraft scaling, diagnostic
retention, memory attribution, path-cache lifetime, native-result and focused
admission work on main. Final production source hashes match the saved domain-
admission observation; the 5,492-pass/1,148-excluded fast-suite result applies.
Formatting checks pass for all 44 changed Elixir files, and whitespace checks
pass. No additional source changes or remote push were requested.
