# Configurable reference mission development queue

This is the ordered implementation queue for the generic mission-analysis and
Reflect-like reference-mission work, starting 2026-11-04. The user authorized
working through the queue until a material mission decision or missing input
requires feedback. Synthetic assumptions remain configurable and identified.
This queue complements the broader artifact/platform roadmap; it does not replace
its acceptance decisions or activate a new product maturity level.

| Slice | Outcome | Completion evidence | Status |
| --- | --- | --- | --- |
| 1 | Independent wheel numerical reference | Frozen independently integrated momentum/motor-torque cases; production comparisons at multiple cadences; corruption and conservation checks | Complete |
| 2 | Independent saved-plan wheel checks | Offline checker verifies supported wheel histories and limits, rejects semantic mutations and remains partial outside its explicit scope | Complete |
| 3 | Maintenance search work accounting | Whole-search budgets and evaluation counts include rejected trials; small-constellation benchmark exposes cost and stops deterministically | Complete |
| 4 | Time-bounded availability | Service and maintenance eligibility respect declared outages and restorations inside a horizon; idle/resource evolution continues | Complete |
| 5 | Observed-state quality | State source, measurement epoch, freshness policy and declared error bounds survive revision; stale/missing coverage cannot silently become usable state | Complete |
| 6 | Replanning during an activity | Preserve an immutable executed prefix and reserved completion of an in-progress activity; charge resources once and prevent duplicate completion | Complete |
| 7 | Extend the rolling horizon | Advance and extend beyond the original end using explicit trajectory/environment coverage and new demand; overlapping predictions remain consistent | Complete |
| 8 | Command delivery feasibility | A service requiring a command cannot be accepted without a declared eligible contact before its deadline; shared station contention is checked | Complete |
| 9 | Basic thermal resource | One configurable lumped thermal state evolves through modes, checks temperature limits, supports cooldown activities and carries state through replanning | Complete |
| 10 | Integrated constellation assessment | Reproducible multi-cycle, multi-spacecraft Reflect-like and non-illumination examples exercise failures, recovery, budgets and sensitivity with an operator-readable report | Complete |

## Slice boundaries

1. **Wheel reference.** Use separately implemented equations and an independent
   numerical integrator, without importing production attitude/resource math.
   Include non-principal-axis rotation, unequal inertia, signed wheel axes,
   external disturbance, unloading, saturation and motor limits. Pin inputs,
   generator, output bytes and numerical tolerances. Verification of a declared
   model does not establish engineering truth.
2. **Saved-plan checking.** Start with an explicitly supportable motion/resource
   envelope and expand only with evidence. Do not trust the producer's status,
   capacity checks or aggregate state as the oracle. Mutation tests must include
   coherent rehashed artifacts, false wheel states and missed saturation.
3. **Search accounting.** Preserve distinct service-order and maintenance-set
   trial identities. Count work even when a candidate fails before a report is
   returned. Budget exhaustion must be reviewable and must not turn an unknown
   candidate into a feasible one. Keep the fast development tests small.
4. **Availability.** Add interval-scoped eligibility, not spacecraft removal.
   Require whole activities to fit supported intervals; distinguish a payload
   outage from a maintenance-mode outage. Use existing opportunity and contact
   concepts rather than another time-window representation where practical.
5. **State quality.** Accept source-bound offline observation packets first;
   live telemetry ingestion is outside this slice. Treat configured error bounds
   as assumptions, not statistical guarantees. Keep synthetic predictions visibly
   distinct from observations and reject incomplete required state.
6. **In-progress execution.** Initially support successful completion of an
   already-started activity under its original profile. Abort/recovery policy
   requires an explicit future contract. Resource forecasts cannot charge the
   executed prefix twice or move already executed work.
7. **Horizon extension.** Preserve lineage, completed-request history and physical
   state; obtain future trajectories from an explicit provider. This slice does
   not infer maneuvers or silently extrapolate beyond declared coverage.
8. **Communications.** Reuse the repository's existing contact, station-calendar,
   command-window and allocation contracts. Bridge them into this mission-analysis
   path rather than rebuilding a ground-network planner. This proves feasibility
   against declared contact assumptions, not actual command delivery.
9. **Thermal.** Use explicit heat capacity, dissipation/input and heat-rejection
   assumptions with known-answer cases. Start with a planning model whose scope
   can be explained and independently checked. Do not invent flight thresholds.
10. **Assessment.** Exercise the integrated behavior with finite, documented
    horizon lengths and constellation sizes. Report delivered service, constraint
    margins, maintenance/contact costs, rejected demand and planning work. Include
    a second mission type so the generic framework is exercised. Identify which
    conclusions change with assumptions and which need company engineering data.

## Execution and acceptance

Each slice adds one usable behavior, focused normal/edge/failure tests, reproducible
evidence and matching documentation. Review locally and record findings before
moving on. Broader tests run when changes touch shared planning or artifact
semantics; numerical reference checks remain available offline. Preserve existing
uncommitted work. Progress is recorded below and linked from the autonomous-loop
status ledger; this instruction does not authorize publishing to a remote.

Feedback is needed when a choice would commit the framework to a spacecraft's
actual actuator, payload, communications, operating policy or calibrated limits.
Proceed with visibly synthetic configurations for reusable mechanisms when that
choice can remain configurable. Queue order may change if an earlier slice
exposes a correctness prerequisite; record the reason instead of hiding the change.

## Progress

- 2026-11-04: Queue established. Starting slice 1 from the existing reaction-wheel
  and automatic-maintenance implementation. Earlier fast-suite evidence was
  5,385 passing tests; the final focused maintenance run had 12 passing tests.

- Slice 1 complete: eight frozen independent body-frame RK4 cases, 16 production
  comparisons at two cadences, conservation and content-corruption checks.
  Local review corrected unknown-status handling so it cannot count as a
  demonstrated violation. Generator regeneration preserves pinned bytes.
  Evidence: [wheel_verification_observation.json](wheel_verification_observation.json).

- Slice 2 complete: independent stationary wheel histories, motor and momentum
  limits, all reported samples and executed-state handoff; 29 focused tests pass.
  A coherent rehashed child-state mutation passes standalone but fails its chain.
  Local review added frame/epoch and wheel-array-count guards. Moving paths remain
  explicitly unsupported by the saved-plan checker. Starting slice 3.

- Slice 3 complete: per-invocation callback budgets/counts include failed trials
  and scheduling endpoint checks. One/two-spacecraft benchmarks pass at 7,568
  and 60,492 callbacks; 1,000-call caps stop exactly. Local review removed a
  redundant endpoint recheck that would escape the search budget. Full fast
  suite: 5,399 passed, 1,148 excluded; final focused check after that fix: 12
  passed. Saved battery-only report remains identical. Starting slice 4.

- Slice 4 complete: scoped half-open outage calendars, restored opportunity
  pieces, protected conflicts, replay retention and independent overlap checks.
  Seven focused tests and the four-step example pass; independent chain checking
  passes. Full fast suite: 5,406 passed/1,148 excluded in 250.6 s. Local review
  confirmed idle resource evolution and explicit source-window evidence survive
  clipping. Starting slice 5, source/freshness/error-bound state quality.

- Slice 5 complete: explicit source kinds, common/measurement epochs, validity
  and complete per-model error bounds; rejected quality never becomes a child.
  Synthetic prediction/execution remain distinct from observations. Seven focused
  tests pass; full fast suite: 5,413 passed/1,148 excluded in 250.5 s. Independent
  saved-state quality arithmetic rejects rehashed stale observations. This gates
  nominal point-state inputs and does not claim robust uncertainty propagation.
  Starting slice 6, non-abortive activity continuation and single-charge history.

- Slice 6 complete: original-clock continuations, immutable prefix/owner/end, exact
  protected tails, one-time cost/completion and independent lineage reconstruction.
  Eleven focused tests and 5,424 fast-suite tests pass (1,148 excluded, 259.9 s).
  Five-cycle example and independent chain checks pass. Numerical motion/wheel
  references pass; local review corrected terminal roundoff and UTC phase-boundary
  cancellation without waiving real maneuvers. Starting slice 7, horizon extension.

- Slice 7 complete: explicit finite J2/environment coverage, frozen overlap
  checkpoints, horizon extension/new demand and actual-deadline expiry. Three
  focused cases, 57 lifecycle/validation tests, and full fast suite 5,427 passed
  (1,148 excluded, 264.4 s). Native three-cycle and independent replay pass through
  195 seconds beyond the original 100-second horizon. Local review added
  independent provider/end guards. Starting slice 8, command-contact feasibility.

- Slice 8 complete: existing station-calendar/allocation/command-window bridge,
  whole-spacecraft contact reservations, deadlines/lead time and explicit receipt
  history. Seven focused tests, native/independent three-cycle example, and
  full fast suite 5,434 passed (1,148 excluded, 258.2 s). Local review prevented
  contact batching without declared capacity and checked original activity start
  for continuation prerequisites. Starting slice 9, scalar thermal resource.

- Slice 9 complete: analytic declared scalar thermal resource, hot/cold gates,
  cooldown search, exact temperature handoff and per-node quality bounds. Eight
  focused thermal tests and full fast suite 5,442 passed (1,148 excluded, 274.9 s);
  final advance/thermal regression 12 passed. Four-cycle native/independent
  example passes. Local review fixed integer/float epoch equivalence in independent
  coverage checks and extended the generic state invariant beyond battery/wheels.
  Starting slice 10, integrated multi-spacecraft assessment and sensitivity.

- Slice 10 complete: bounded assessment command and five reproducible cases: two
  three-spacecraft illumination checkpoint policies, two two-spacecraft thermal
  cases and a hard work-cap stop. All native expectations are met. Fixed-attitude
  independent checks pass; moving-wheel/stopped-operation limitations remain
  explicitly partial. Observed illumination delivery is 5 versus 6 services; the
  hot-limit change withholds service, and the capped replan stops at exactly
  1,000 callbacks without a child. Full fast suite: 5,445 passed/1,148 excluded
  in 275.2 s. Final 11 focused tests cover reporting, failure categories and
  counters. Local review fixed null updates on ordinary revision rows, preserved
  simulated-versus-accepted completion totals, and retained structured failed-work
  evidence. See [constellation_assessment.md](constellation_assessment.md) and
  [constellation_assessment_observation.json](constellation_assessment_observation.json).

All ten queued slices are complete. No company-specific actuator, thermal or
communications assumptions were adopted; no commit, push or maturity-level
promotion was performed. Engineering inputs and remaining validation gaps are
listed in the integrated assessment for the next review.

## Follow-up: checkpoint-faithful execution replay

Complete. Unchanged execution clips saved motion with original phase clocks and
modes; committed acquisition retains its exact destination, while a braking block
separated by idle time does not lock a future service. Explicit motion confirmation
and independent parent-derived interval/boundary reconstruction prevent silent
replacement. Seven new tests cover all motion phases, repeated/non-grid
checkpoints, non-principal-axis motion, unequal inertia and coherent artifact
mutations. Full fast suite: 5,452 passed/1,148 excluded (292.4 s); focused rigid/
motion checks: 18 passed; final motion checks: 7 passed. The frozen motion baseline
passes. Both integrated illumination checkpoint choices now deliver all six
services (value 150); moving-wheel validation remains explicitly partial.

Local parent review corrected block boundaries at idle holds, kept original
clocks for clipped one-sided torque checks, compacted source records to avoid
copying full path samples, and checked source confirmation/committed destinations.
No delegation or publishing was requested. Details: [checkpoint_replay.md](checkpoint_replay.md)
and [checkpoint_replay_observation.json](checkpoint_replay_observation.json).

## Follow-up: execution acceptance independent of planning

Complete. Valid declared state is saved as an immutable parent-bound execution
checkpoint before planning. Failed replans retain accepted outcomes, balances,
receipts, ongoing activities and committed motion; the stored plan is explicitly
stale. Algorithm-only retries use the same checkpoint without replaying execution
or debiting again. Separate accept/plan CLI commands support resuming from disk.
Operations artifacts now use v2 for separate execution/plan acceptance semantics.

Full fast suite: 5,460 passed/1,148 excluded (263.9 s), before final format/schema
refinements; final focused tests: 20 passed (11.6 s). Stationary native and
independent examples pass. The three-spacecraft retry completes six services/value
150; independent checking has no errors and remains partial for moving wheels.
Local parent review covered persistence-before-planning, immutable parent-derived
state, retry controls, stale-plan blocking, source confirmation, receipts and
separate accepted history/epoch reporting. No subagents or publishing used;
historical maturity acceptance remains unchanged. Details:
[execution_checkpoints.md](execution_checkpoints.md) and
[execution_checkpoint_observation.json](execution_checkpoint_observation.json).

## Follow-up: independent moving-resource accounting

Complete. Wheel samples preserve exact resource start/mid/end kinematics. The
independent checker verifies global inertial impulse balance, body/rotor momentum,
Euler motor demand, all sampled limits/margins/extrema and finest-cadence execution
handoff. Original-clock maneuver phases and profile-matching tracking poses bind
the evidence; intermediate tracking kinematics remain declared, without an orbit
or pointing-geometry claim. Battery accounting now independently partitions all
mode/phase loads, including terminal changes and clipped phases, and checks sample
histories, efficiencies, clipping, curtailed/unserved energy and reserve.

Full fast suite: 5,466 passed/1,148 excluded (336.1 s while assessment also ran).
Final focused validation/checkpoint tests: 33 passed; six new mutation/reference
tests also pass after the last frame/quaternion/cadence refinements. Both saved
examples and four completed assessment cases pass independent checking. The hard
work-cap case remains partial solely for stopped operations. Both illumination
cases deliver six services/value 150. Checker equations match all eight frozen
body-frame RK4 references within 1e-5 Nms/Nm at 0.25-second intervals.

Local review covered independent imports, global-versus-recursive momentum
accounting, one-sided phase acceleration, original clocks, mode/phase bindings,
complete cadences/coverage, finite initial frames, quaternion equivalence,
coherent diagnostic mutations and separate execution/forecast state. No subagents,
rig or publishing used; historical maturity acceptance is unchanged. Details:
[moving_resource_validation.md](moving_resource_validation.md) and
[moving_resource_validation_observation.json](moving_resource_validation_observation.json).

## Follow-up: reuse exact validated environment data

Complete on `experiment/environment-validation-reuse`. The user requested resetting
the uncommitted Rust experiment; source, native build outputs, benchmark limit
changes and stale experiment modules were removed, starting again at 78a30e61.
The provider now keeps one successful exact dataset/code-version admission per
process and emits the verified pinned digest without repeated canonicalization.
Changed values still run the original file-evidence and semantic validation; all
request-context and coverage gates remain per query. Local-function code identity
also prevents reuse across validation code upgrades, including old-code calls
already in progress. No global cache or public trusted-field shortcut was added.

The unchanged six-spacecraft/nine-request study was run against the original and
new providers with two alternating-order repeats. Median planning time fell from
19.49 to 6.37 seconds (3.06x); workflow through report persistence fell from
21.15 to 8.04 seconds (2.63x). Independent streamed hashes confirm all four complete
reports are byte-identical, including counters, assignments, windows and margins.
These are local observations on the original study and work controls, separate
from the discarded larger Rust experiment's configurations.

Five trace tests cover one hash per unchanged value, numeric type changes, failed
admission preservation, per-process isolation, bounded single-entry replacement,
current provenance, query gates and actual code reload. Provider/new tests: 14
passed. Full fast suite: 5,471 passed/1,148 excluded (271.8 s). Parent local review
covered every pinned-identity emitter's admission path, immutable/exact matching,
code-version races, bounded retention, trace cleanup and benchmark clock scope.
No delegation, rig, commit or push. Historical maturity acceptance unchanged.
Details: [environment_validation_reuse.md](environment_validation_reuse.md) and
[environment_validation_reuse_observation.json](environment_validation_reuse_observation.json).

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
[constellation_scaling.md](constellation_scaling.md) and
[constellation_scaling_observation.json](constellation_scaling_observation.json).

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
[opportunity_retention.md](opportunity_retention.md) and
[opportunity_retention_observation.json](opportunity_retention_observation.json).

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
[planning_memory_attribution.md](planning_memory_attribution.md) and
[planning_memory_attribution_observation.json](planning_memory_attribution_observation.json).

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
Evidence: [path_cache_lifetime.md](path_cache_lifetime.md) and
[path_cache_lifetime_observation.json](path_cache_lifetime_observation.json).

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
[native_results.md](native_results.md) and
[native_results_observation.json](native_results_observation.json).

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
Evidence: [domain_admission.md](domain_admission.md) and
[domain_admission_observation.json](domain_admission_observation.json).

## Commit follow-up

The user requested committing the accumulated 100-spacecraft scaling, diagnostic
retention, memory attribution, path-cache lifetime, native-result and focused
admission work on main. Final production source hashes match the saved domain-
admission observation; the 5,492-pass/1,148-excluded fast-suite result applies.
Formatting checks pass for all 44 changed Elixir files, and whitespace checks
pass. No additional source changes or remote push were requested.
