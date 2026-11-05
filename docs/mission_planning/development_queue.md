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
