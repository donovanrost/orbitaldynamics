# OrbitalDynamics

OrbitalDynamics is a small Elixir foundation for mission analysis on the BEAM.
The current slice answers one concrete question: can Elixir orchestrate many
deterministic orbital scenarios while keeping astrodynamics assumptions explicit?

## Current Slice

- Cartesian orbital states carry position in kilometers, velocity in kilometers
  per second, an epoch, and a reference frame.
- `OrbitalDynamics.orbital_elements/2` and
  `OrbitalDynamics.state_from_orbital_elements/3` expose two-body osculating
  classical element conversions without performing frame or time-system
  transformations.
- `OrbitalDynamics.units_policy/0` documents the canonical suffix-based unit
  contract used by public structs, manifests, and artifacts.
- Mission scenarios bind a spacecraft, initial state, central body, duration,
  and output cadence.
- `OrbitalDynamics.Propagators.TwoBody` and `OrbitalDynamics.Propagators.J2`
  propagate scenarios with fixed-step RK4 force models;
  `OrbitalDynamics.Propagators.TwoBodyDrag` is an opt-in programmatic path that
  combines point-mass gravity with validated provider-backed atmospheric drag;
  `OrbitalDynamics.Propagators.J2Drag` is a separate opt-in, programmatic-only
  scalar LEO path that sums point-mass, J2, and drag acceleration in each RK4
  stage under one captured offline environment policy.
- `OrbitalDynamics.ScenarioRunner` evaluates batches concurrently through a
  supervised task boundary while preserving input order in the results.
- `OrbitalDynamics.StudyRunner` composes propagation with sample-based
  ground-station access windows and cylindrical central-body eclipse intervals.
- `OrbitalDynamics.Maneuver.ImpulsiveBurn` models instantaneous velocity
  changes for scalar propagation studies by segmenting integration at burn
  epochs.
- `OrbitalDynamics.MissionPlan` models a spacecraft activity timeline and
  compiles dynamics-relevant activities into propagation scenarios.
- `OrbitalDynamics.Search.MonteCarlo` expands a base scenario into seeded
  Cartesian initial-state dispersions for reproducible uncertainty studies.
- Study artifacts can rank search candidates and evaluate simple mission
  constraints over final orbit, access, eclipse, and delta-v metrics.

The propagator intentionally exposes its assumptions in each trajectory:
`force_model`, `numerical_method`, `max_step_s`, units, frame, epoch scale, and
central-body `mu_km3_s2`.

## Example

```elixir
alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector}

earth = CentralBody.earth()
radius_km = 7_000.0
speed_km_s = :math.sqrt(earth.mu_km3_s2 / radius_km)

state =
  StateVector.new!(
    {radius_km, 0.0, 0.0},
    {0.0, speed_km_s, 0.0},
    Epoch.new!(0.0, :tdb),
    Frame.earth_inertial_j2000()
  )

spacecraft = Spacecraft.new!(:demo_sat, 250.0)

scenario =
  Scenario.new!(:leo_demo, spacecraft, state,
    duration_s: 600.0,
    output_step_s: 60.0,
    central_body: earth
  )

{:ok, trajectory} = OrbitalDynamics.propagate(scenario, max_step_s: 10.0)
```

Mission plans can describe both dynamics and operations activities before
compiling to the scenario layer. Operational activities carry typed status,
approval, lock, dependency, provenance, and source-window metadata for later
planner and Cadence-import artifacts:

```elixir
alias OrbitalDynamics.MissionPlan
alias OrbitalDynamics.MissionPlan.Activity

plan =
  MissionPlan.new!(:ops_checkout, spacecraft, state,
    horizon_s: 600.0,
    output_step_s: 60.0,
    central_body: earth,
    activities: [
      Activity.coast!(:initial_coast, 0.0, 120.0),
      Activity.impulsive_burn!(:trim_burn, 180.0, {0.0, 0.01, 0.0}),
      Activity.observe!(:target_pass, 240.0, 360.0, :target_a),
      Activity.downlink!(:downlink_pass, 420.0, 540.0, :dss_14,
        status: :approved,
        approval_status: :approved,
        locked?: true,
        dependencies: [:target_pass],
        source_window_id: :dss_14_pass_1
      ),
      Activity.command!(:cmd_window, 545.0, 555.0, ground_station_id: :dss_14),
      Activity.health_check!(:health_poll, 560.0, 570.0),
      Activity.planned_contact!(:uplink_contact, 580.0, 595.0, :dss_14, :uplink)
    ],
    metadata: %{objective: :checkout}
  )

{:ok, scenario} = OrbitalDynamics.compile_plan(plan)
{:ok, trajectory} = OrbitalDynamics.propagate(scenario, max_step_s: 10.0)
```

Those activities can also be summarized without compiling or mutating a
schedule:

```elixir
report = OrbitalDynamics.operational_timeline_report(plan.activities)
diff = OrbitalDynamics.timeline_diff_report(old_activities, plan.activities)
command_windows = OrbitalDynamics.command_window_report(plan.activities)
feedback = OrbitalDynamics.reconcile_timeline_feedback(plan.activities, realized_activities)
```

The report is an artifact-only `operational_timeline_report.v1` summary with
contact and command counts, approval/lock status, source-window lineage, Cadence
import presence plus adapter external ID/contract when declared, required
operator action, import-readiness status, execution boundary, and derived
timeline identity. Dependency and exclusivity metadata is checked inside the
artifact when referenced rows are present, with optional missing-dependency
validation for closed-world imports; review rows preserve missing dependencies,
out-of-order dependencies, explicit exclusivity overlaps, and shared
exclusivity-group overlaps without mutating the schedule. Missed, failed,
canceled/cancelled, and rejected terminal statuses are counted as terminal
exceptions and routed to review rather than being treated as executed no-action
rows. Duplicate timeline identities are counted and routed to review with the
colliding activity IDs and source rows preserved.
`diff` is a `timeline_diff_report.v1` artifact that compares source and
replacement activity lists by timeline identity and records added, removed,
changed, and unchanged rows with timing deltas, changed fields, and required
operator actions without mutating either schedule. If a source or replacement
list contains duplicate timeline identities, the diff preserves the colliding
activities in a review-required row instead of overwriting them.
`command_windows` is a narrower `command_window_report.v1` artifact for
command, tracking, health-check, and uplink contact windows. It carries stable
window IDs, timing, direction, approval status, required operator action,
Cadence import status, source-window lineage, station-calendar provider and
reservation evidence, optional approval-policy classification evidence for
review rows, timeline identity, and reusable activity context without
scheduling or executing commands.
`feedback` is a `timeline_feedback_report.v1` artifact for planned-versus-realized
activity reconciliation. Contact and command rows carry direction, ground
station, source-window lineage, Cadence import status and adapter identity,
typed planned-to-realized status transitions, command success/result, contact
success, throughput deltas, source/realized activity-context maps, and planned
timeline protection decisions for operator review without mutating the
timeline. Realized feedback accepts completed, executed, partial, missed,
failed, delayed, canceled/cancelled, and rejected provider statuses; executed
contact, command, and generic activity rows record completion, while cancelled
and rejected rows route to status-specific exception review.
Realized activity contexts carry provider-declared planned IDs, reconciled
planned IDs, match strategy, and provider/import provenance such as source,
provider, adapter, external ID, schema contract, trust boundary, received time,
provenance, and metadata for adapter correlation. Realized rows that identify
a duplicate planned timeline identity are routed to ambiguity review with the
possible planned activity IDs preserved.
The report also emits normalized `operational_feedback` maps for V3
strategy/candidate-refresh handoff, deriving contact success, station
throughput, observation success, command success, and maneuver success from the
realized feedback rows without mutating the source plan.
`OrbitalDynamics.timeline_operational_feedback/1` derives the same maps from
either string-keyed JSON artifacts or atom-keyed Elixir report maps.
Standalone `realized_activity.v1` rows type the same execution feedback and
provider/import provenance fields for import-gate validation; provider-shaped
rows that declare a provider or adapter must also declare external identity and
a trust boundary.

Study result artifacts that contain `maneuver_recommendation.v1` rows also emit
`maneuver_review_report.v1`, a review/import table with ranked maneuver rows,
delta-v totals, approval status, required operator action, source
recommendation, declared/missing execution-uncertainty metadata, and an explicit
no-command-execution boundary. When supplied an approval policy, maneuver review
rows carry approval requirements,
approval-rule matches, and `policy_decision.v1` evidence, allowing the
artifact-only `maneuver_authority_v1` bundle to classify burn authority review
without approving or commanding maneuvers.

## Numerical Scope

This is not a precision flight dynamics tool yet. The default propagator assumes:

- one central point mass
- inertial frame input
- no drag, J2, third-body gravity, SRP, finite burns, or adaptive event finding
- deterministic fixed-step RK4 integration by default; scalar two-body can opt
  into educational adaptive step-doubling with explicit tolerances, but this is
  not a root-solved event finder

These limits are deliberate so tests can pin down behavior before adding more
force models or native numerical kernels.

The opt-in `OrbitalDynamics.propagate_j2_drag/2` facade does not change that
default. It accepts Earth/J2000/TDB LEO scenarios for at most 24 hours, uses a
10 s fixed-step default with a 30 s hard maximum, rejects maneuvers, and records
spacecraft ballistic inputs plus atmosphere/rotation source, revision, and
coverage provenance. Its explicit arithmetic-safety envelope accepts Earth
`mu` from 350,000 to 450,000 km^3/s^2, radius from 6,000 to 7,000 km, J2 from
zero to 0.002, total mass from 0.1 to 10,000,000 kg, drag area up to 1,000,000
m^2, drag coefficient up to 5, and density up to 0.001 kg/m^3; unsupported
finite values return typed errors. Those are computability guards, not the
external accuracy envelope. The externally checked D3 state-error envelope is
the content-bound eight-case Orekit 13.1.7 corpus: fixed Earth constants and
the built-in exponential-atmosphere/constant-rotation path, initial altitude
250--800 km, duration 1--24 hours, fixed RK4 step 5--30 s, total mass
100--500 kg, area 1--8 m^2, coefficient 2.0--2.4, reference density
0--2e-11 kg/m^3 at 400 km, and scale height 50--70 km. Six combined J2-drag
cases plus zero-density J2 and zero-J2 drag branches compare 200 full-horizon
states to 0.01 m position and 0.00001 m/s velocity maximum-component
tolerances. Unsampled continuous combinations and the broader computability
guards are not promoted. The separate 24-hour 10 s versus 5 s fixture remains
internal convergence evidence only.

## Roadmap

Project docs live under [`docs/`](docs/README.md) as a navigable document base.

- Toolkit thesis, capability levels, backend evaluation plan, and the first
  useful mission-planning slice live in
  [`docs/mission_planning/toolkit_spec.md`](docs/mission_planning/toolkit_spec.md).
- The product arc for turning this toolkit into a Cadence-facing LEO
  constellation campaign planner lives in
  [`docs/mission_planning/leo_campaign_planner/`](docs/mission_planning/leo_campaign_planner/README.md).
- The broader feature-completeness map and phased maturity definition live in
  [`docs/feature_set/`](docs/feature_set/README.md).
- The checked machine-readable V1/V2/V3 Level 5 command path lives in
  [`docs/feature_set/level5_workflow.md`](docs/feature_set/level5_workflow.md).
- Canonical artifact examples, public field families, and lint commands live
  in [`docs/artifacts/`](docs/artifacts/README.md).
- The high-fidelity mission-planning feature set (longer, forward-looking)
  lives in
  [`docs/mission_planning/high_fidelity/`](docs/mission_planning/high_fidelity/README.md).

1. Distributed Monte Carlo: partition scenario batches across local and
   connected-node `Task.Supervisor` processes while preserving deterministic
   result ordering and random seeds.
2. Trajectory search: introduce explicit search spaces over initial states,
   durations, and maneuver parameters; keep objective evaluation pure so it can
   run locally, across nodes, or in native kernels.
3. Maneuver planning: add impulsive maneuvers with units, epochs, and frame
   transforms before modeling finite burns.
4. Optimization: layer deterministic optimizers over the scenario runner, then
   add stochastic optimizers with seed manifests and reproducible trial records.
5. Higher-fidelity propagation: add named force-model structs and validation for
   perturbations such as J2 and drag without hiding model assumptions behind a
   generic engine abstraction.

## Verification

Run:

```bash
mix test
```

### Duration-weighted test shards

Opt-in profiling records cumulative ExUnit runtime and test counts for every
loaded test file without changing the default test configuration:

```bash
ORBITAL_DYNAMICS_TEST_PROFILE_PATH=tmp/test-suite-profile/partition-1.json \
  MIX_TEST_PARTITION=1 mix test --partitions 4 --seed 0
```

Do not pass `--formatter` during an opt-in profile run: Mix command-line
formatters replace the configured profiling formatter, so no profile would be
written.

After profiling every built-in partition, build a deterministic shard manifest
or run one duration-weighted shard. Repeat `--profile` for every profile artifact:

```bash
mix orbital_dynamics.test.shard \
  --profile tmp/test-suite-profile/partition-1.json \
  --profile tmp/test-suite-profile/partition-2.json \
  --profile tmp/test-suite-profile/partition-3.json \
  --profile tmp/test-suite-profile/partition-4.json \
  --shards 4 --manifest tmp/test-suite-profile/shards.json

mix orbital_dynamics.test.shard \
  --profile tmp/test-suite-profile/partition-1.json \
  --profile tmp/test-suite-profile/partition-2.json \
  --profile tmp/test-suite-profile/partition-3.json \
  --profile tmp/test-suite-profile/partition-4.json \
  --shards 4 --shard 1 -- --seed 0 --timeout 120000
```

The task rejects missing, unexpected, or multiply owned test files before
running a shard. It accepts only `--seed` and `--timeout` after `--`; all test
selection remains owned by the manifest. Files are assigned longest-runtime
first with stable path and shard-index tie breakers, then listed lexically within
each shard. Profiles capture measured runtime rather than source identity, so
regenerate them when code or tests change materially.

## Benchmarks

Run the scalar and BEAM-concurrent baseline benchmark:

```bash
mix orbital_dynamics.benchmark --counts 1,10,100 --duration-s 3600 --output-step-s 60 --max-step-s 10
```

Include the experimental Nx batched backend:

```bash
mix orbital_dynamics.benchmark --counts 1,10,100 --include-nx
```

Include the compiled Nx batched backend:

```bash
mix orbital_dynamics.benchmark --counts 1,10,100 --include-nx-compiled
```

Include the EXLA host CPU backend:

```bash
mix orbital_dynamics.benchmark --counts 100,1000 --duration-s 3600 --include-exla-cpu --warmup-runs 1 --repetitions 3
```

Write a JSON artifact for backend comparisons:

```bash
mix orbital_dynamics.benchmark --counts 1,10,100 --include-nx --include-nx-compiled --include-exla-cpu --output benchmark_results/baseline.json
```

Report a saved benchmark artifact, optionally comparing rows with an
operational scale target:

```bash
mix orbital_dynamics.benchmark.report benchmark_results/baseline.json --scale-target v1_campaign
```

## Demo Study

Run a small J2 LEO access-window and eclipse study and write a compact JSON
artifact:

```bash
mix orbital_dynamics.study.demo --output study_results/leo_access_demo.json
```

Run the same workflow from a reproducible JSON manifest:

```bash
mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output study_results/leo_access_demo_manifest.json
```

Use both `--run-id` and `--generated-at` when refreshing checked-in artifacts
that downstream campaign or golden-artifact tests identify by stable IDs:

```bash
mix orbital_dynamics.study.demo --output study_results/leo_access_demo.json --run-id leo_access_demo-20260514 --generated-at 2026-05-14T00:00:00Z
mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output study_results/leo_access_demo_manifest.json --run-id leo_access_demo-20260514 --generated-at 2026-05-14T00:00:00Z
mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output /tmp/leo_access_demo_manifest.json --run-id leo_access_demo-20260514 --generated-at 2026-05-14T00:00:00Z --format json
```

When resuming an operator or CI run, add `--resume` to reuse an existing output
only when it validates as `result_artifact.v1`, matches the manifest SHA, and
matches the requested `--run-id` if one is supplied:

```bash
mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output study_results/leo_access_demo_manifest.json --run-id leo_access_demo-20260514 --resume --format json
```

The same guard is available to Elixir callers as
`OrbitalDynamics.ResultSet.Artifact.resume_check/2`.

Long local runs can opt into between-scenario checkpointing. Use `--checkpoint`
for a new checkpoint and repeat the run with `--resume-checkpoint` after an
interruption:

```bash
mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output /tmp/leo_access_demo.json --checkpoint /tmp/leo_access_demo.checkpoint.json --format json
mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output /tmp/leo_access_demo.json --resume-checkpoint /tmp/leo_access_demo.checkpoint.json --format json
```

Checkpoint recovery is local and opt-in. It validates the checkpoint contract,
manifest/study/model/run-option identities, the complete ordered scenario
manifest, the checkpoint content hash, and every completed-scenario payload
hash before reuse. It runs only missing scenario indexes, then emits exact
reused/run counts and provenance in the JSON summary and execution report.
Checkpoint and output paths must not alias. This mode does not support batch or
distributed execution, within-scenario recovery, persistent queues, or
automatic retry, and remains separate from whole-artifact `--resume` and
explicit `--retry-failed-from`. Checkpoint file contents are synced before
atomic publication or replacement, but the portable implementation does not
sync containing-directory metadata and therefore does not claim survival of a
sudden power loss.

Summarize or compare saved study artifacts:

```bash
mix orbital_dynamics.study.report --input study_results/leo_access_demo_manifest.json
mix orbital_dynamics.study.report --input study_results/leo_access_demo.json --compare study_results/leo_access_demo_manifest.json
```

Run and rank a deterministic maneuver search:

```bash
mix orbital_dynamics.study.run --manifest studies/raise_apogee_search.json --output study_results/raise_apogee_search.json --run-id raise_apogee_search-20260514 --generated-at 2026-05-14T00:00:00Z
mix orbital_dynamics.study.report --input study_results/raise_apogee_search.json
mix orbital_dynamics.study.report --input study_results/raise_apogee_search.json --rank final_radius_km --limit 3
```

Run a seeded Monte Carlo dispersion study with minimum-altitude constraint
statistics:

```bash
mix orbital_dynamics.study.run --manifest studies/leo_dispersion_monte_carlo.json --output study_results/leo_dispersion_monte_carlo.json --run-id leo_dispersion_monte_carlo-20260514 --generated-at 2026-05-14T00:00:00Z
mix orbital_dynamics.study.report --input study_results/leo_dispersion_monte_carlo.json
```

Run a mission-plan activity timeline that compiles into a propagation scenario
and archives plan metadata in the result artifact:

```bash
mix orbital_dynamics.study.run --manifest studies/mission_plan_checkout.json --output study_results/mission_plan_checkout.json --run-id mission_plan_checkout-20260514 --generated-at 2026-05-14T00:00:00Z
mix orbital_dynamics.study.report --input study_results/mission_plan_checkout.json
```

Run the opt-in point-mass plus atmospheric-drag propagator from a checked-in
manifest:

```bash
mix orbital_dynamics.manifest.lint --manifest studies/two_body_drag_demo.json
mix orbital_dynamics.study.run --manifest studies/two_body_drag_demo.json --output study_results/two_body_drag_demo.json --run-id two_body_drag_demo-20260720 --generated-at 2026-07-20T00:00:00Z
```

The JSON manifest accepts only the built-in, network-free
`exponential_reference` atmosphere provider. Its reference altitude, density,
and scale height are preserved in result provenance. Custom provider modules
remain available only through the programmatic `Study` API. Generated
`circular_leo` scenarios accept `propellant_mass_kg`, `area_m2`, and
`drag_coefficient` alongside `dry_mass_kg`.

Validate a study manifest without running propagation:

```bash
mix orbital_dynamics.manifest.lint --manifest studies/mission_plan_checkout.json
mix orbital_dynamics.manifest.lint --manifest studies/mission_plan_checkout.json --format json
mix orbital_dynamics.manifest.lint --manifest studies/mission_plan_checkout.json --output study_results/manifest_lint_report.json
```

Print a compact field reference derived from the exported manifest schema:

```bash
mix orbital_dynamics.manifest.reference
mix orbital_dynamics.manifest.reference --format json
mix orbital_dynamics.manifest.reference --output study_results/manifest_field_reference.json
```

The JSON reference includes each field path with its parent path, top-level
manifest section, array-item marker, required flag, required child fields,
`anyOf` required alternatives, and supported enum/const values when the schema
declares them.

Export the study-manifest JSON Schema used by editor and integration tooling.
The export remains backed by the executable manifest loader, and now includes
nested field coverage for candidate-refresh inputs such as accepted planning
state, simple orbit-data rows, ground-network entries, resource summaries, and
prior candidates:

```bash
mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json
```

Run a LEO constellation campaign plan. The manifest expands multiple spacecraft
into scenarios, generates ground-station access, eclipse, and target-visibility
windows, builds candidate observation/contact activities, ranks candidate
timelines, and writes a reproducible `campaign_plan` artifact shaped for later
Cadence import, including `contact_intent.v1` rows for proposed downlinks and
an `operator_review_package.v1` for station-contention recommendations and
campaign warnings. `TimelineFeedback` can also reconcile planned activity rows
against `realized_activity.v1` feedback and embed realized completion,
variance, exception, missing-feedback, unplanned-feedback, and duplicate
provider-feedback review rows in an `operator_review_package.v1` without
mutating schedules. Realized observation data volume is also summarized as
default downlink-demand feedback for later candidate refresh or V3 strategy
handoff:

```bash
mix orbital_dynamics.study.run --manifest studies/leo_constellation_campaign.json --output study_results/leo_constellation_campaign.json --run-id leo_constellation_campaign-1778976392512956 --generated-at 2026-05-14T00:00:00Z
```

The V2 rolling planner repairs a prior `campaign_plan` against realized
operations state. It accepts a prior plan artifact, realized activity/contact
outcomes, a current epoch, a remaining horizon, repair/scoring/approval policy,
and optionally a `candidate_refresh.v1` artifact whose refreshed candidates
replace the prior candidate set during repair. When a prebuilt refresh artifact
is not supplied, repair can run an executable `candidate_refresh_request` before
selecting replacements. Repair can also take `ground_network` or
`station_calendar` availability/capacity intervals to annotate source contact
candidates and emit a `source_station_calendar_report`. It emits deltas, a
repaired activity list, candidate-source provenance,
refreshed contact/resource rows when present, source contact allocation reports
when the refresh supplies allocated/deferred contact semantics and reservation
evidence, thin resource
projection reports when resource summaries are available, refresh diff/freshness reports when
present, a `source_timeline_feedback_report` over planned-vs-realized activity
feedback when realized activities are supplied, an
`operational_timeline_report.v1` over repaired activities,
churn-aware scoring, durable source/replacement timeline identity metadata,
warnings, operator approval requirements, a `constraint_report.v1` over
inherited planner-local constraints, and a `policy_decision.v1`.
Duplicate realized activity rows for one planned activity are treated as
ambiguous feedback: repair preserves the planned item, records
`review_realized_feedback` evidence in the delta, and requires operator review
instead of choosing one provider status. Sparse realized feedback can borrow
prior-plan context for derived contact/observation feedback only when the
activity ID resolves to one unique prior row; completed/executed contact,
observation, and maneuver rows count as successful feedback, while
canceled/cancelled/rejected rows count as failed terminal feedback for derived
strategy factors and refresh demand. Branch events that synthesize missed or
delayed realized rows preserve conflicts with provider realized feedback as
duplicate evidence for review instead of overwriting it.
It also emits an artifact-only `operator_review_package.v1` that normalizes
approval requirements, repaired plan deltas, timeline-protection decisions, and
source contact allocation/filter decisions plus warnings into rows with stable
IDs, required operator actions, reasons, reservation evidence, and provenance for downstream
review/import tooling.
See the example request and artifact:

```bash
studies/leo_constellation_campaign_repair_v2.json
study_results/leo_constellation_campaign_repair_v2.json
```

JSON repair requests that carry `source_plan_ref` can be executed directly:

```elixir
OrbitalDynamics.campaign_repair_from_file!("studies/leo_constellation_campaign_repair_v2.json")
```

or from the command line:

```bash
mix orbital_dynamics.campaign.lint --type repair --request studies/leo_constellation_campaign_repair_v2.json
mix orbital_dynamics.campaign.lint --type repair --request studies/leo_constellation_campaign_repair_v2.json --output study_results/campaign_request_lint_v1.json
mix orbital_dynamics.campaign.run --type repair --request studies/leo_constellation_campaign_repair_v2.json --output study_results/leo_constellation_campaign_repair_v2.json
mix orbital_dynamics.campaign.run --type repair --request studies/leo_constellation_campaign_repair_v2.json --output /tmp/repair.json --format json
```

The V3 strategy planner compares explicit and mission-state-derived what-if
branches from a shared mission-state snapshot. It reuses V2 repair inside each
branch, optionally lets individual branches supply their own
`candidate_refresh.v1` candidate set or executable `candidate_refresh_request`,
and can derive a branch refresh from rich mission-state planning data,
including station reservation overlays, station-throughput feedback, and
observation-success feedback effects on generated contact and observation
candidates. Mission-state target revisit objectives can also derive
branch-local refreshes when the current plan has fewer observations than the
objective requires. Sparse realized observation/downlink rows only borrow
target, station, type, and throughput context from the prior plan when the
planned activity ID is unique, so duplicate planned IDs do not trigger derived
revisit or downlink-completion branches through an arbitrary lookup.
When a V2 repair artifact is used as the V3 source plan, the strategy planner
also consumes the repair artifact's
`source_timeline_feedback_report.operational_feedback` maps before applying any
explicit request-level feedback overrides. V3 also accepts a mission-state
`timeline_feedback_report` or `source_timeline_feedback_report`, so Cadence can
hand the strategy planner a realized-feedback artifact directly without first
wrapping it in a repair artifact. The resulting strategy artifact
includes `operational_feedback_provenance` so import/review tooling can inspect
the merge order, source input keys, source counts, and trust-boundary status
behind the feedback maps. Timeline-feedback report sources keep their nested
feedback provenance, so declared provider trust boundaries survive the V3
handoff. The strategy recommendation review row and selected
Cadence import row carry the same feedback provenance context for adapter
routing, including downlink-demand feedback derived from realized observation
data volume. When branch derivation is enabled, that source-derived downlink
demand can create a branch-local candidate refresh with required-downlink
evidence before candidate-budget selection.
Downlink-completion objectives can require a contact count
or a data volume in MB, and branch-local refresh stages enough non-overlapping
downlink candidates to close the declared gap when candidates exist; strategy
risk and recommendation explanations preserve whether the gap was contact-count
or MB-volume driven. Recommendation explanations also preserve first
resource-pressure direction, ground-station, station-calendar entry, provider,
and provider-entry evidence when projected resource pressure starts in a contact
row, and the selected review/import rows flatten resource-pressure status/type
and first-pressure-kind lists for adapter routing. Branch
target catalogs require unique target IDs within a source so duplicate target
definitions do not choose one coordinate or priority arbitrarily; branch station
catalogs apply the same rule to ground-station geometry. Branch generation can
also optionally synthesize a combined mission-state branch from the individual
derived what-ifs for joint-case review. It scores resource and feedback
tradeoffs, classifies action-specific approval boundaries through
`OrbitalDynamics.Policy`, records `policy_decision.v1` branch artifacts and
urgent-target feasibility, and emits probability-explicit branch comparison rows
with raw score, branch probability, expected score, and projected
storage/downlink margins when branch resource summaries are available, promoting
projection overflow/shortfall into branch risks for approval classification.
Branch comparison rows also aggregate branch-event station IDs, directions,
station-calendar entry/provider IDs, calendar statuses, reservation identities,
owners, and match statuses so review/import queues can route ground-network
pressure without reopening raw branch events. It
also embeds branch-level `score_term_report.v1` and
`objective_tradeoff_report.v1` surfaces plus a
`ranking_comparison_report.v1` comparing normalized branch order with
score-ranked branches. It emits a recommended strategy with structured
explanations plus an artifact-only
`operator_review_package.v1` for the recommendation, score-term and
objective-tradeoff review, ranking comparison, approvals, remaining risks, and
branch warnings. Branch repair timeline-feedback rows are surfaced as
realized-feedback review/import rows when a branch carries realized activity
exceptions:

```bash
studies/leo_constellation_campaign_strategy_v3.json
study_results/leo_constellation_campaign_strategy_v3.json
```

Strategy requests use the same file-backed boundary and resolve
`source_plan_ref` before branch evaluation:

```elixir
OrbitalDynamics.campaign_strategy_from_file!("studies/leo_constellation_campaign_strategy_v3.json")
```

or from the command line:

```bash
mix orbital_dynamics.campaign.lint --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --format json
mix orbital_dynamics.campaign.lint --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --output study_results/campaign_request_lint_v1.json
mix orbital_dynamics.campaign.run --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --output study_results/leo_constellation_campaign_strategy_v3.json
mix orbital_dynamics.campaign.run --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --output /tmp/strategy.json --format json
```

Built-in policy bundles are artifact-only approval classifiers. The current
set includes `default_v1`, `contact_command_review_v1`,
`conservative_ops_v1`, `timeline_protection_v1`, and
`degraded_payload_guard_v1`, `mission_ops_escalation_v1`,
`ground_network_allocation_v1`, `maneuver_authority_v1`,
`resource_projection_authority_v1`, and
`operator_review_queue_authority_v1`; the
degraded-payload guard blocks degraded or payload-unavailable observation
changes plus antenna-unavailable contact/downlink/tracking changes while
preserving command and health review exemptions. The mission-ops
bundle adds artifact-only escalation metadata such as escalation queue, role,
required authority, and SLA seconds to policy rule matches and decisions; it
does not execute the escalation workflow. The maneuver-authority bundle applies
the same artifact-only escalation pattern to maneuver timing and impulsive-burn
approval boundaries, and the timeline-protection bundle routes locked or
approved source activity changes to mission-planning authority while blocking
executed activity changes with flight-director authority metadata. Policy rules can also match contact direction and
ground-station context when approval requirements include those fields.
V3 operational feedback can also carry `resource_margin_overrides`; low
feedback margins derive branch-local resource-margin-pressure refreshes and
flow into source resource summaries plus branch resource-projection rows.
Policy bundle fixtures can be refreshed without hand-written scripts:

```bash
mix orbital_dynamics.policy.export --bundle operator_review_queue_authority_v1 --output study_results/policy_bundle_operator_review_queue_authority_v1.json
mix orbital_dynamics.policy.export --all --directory study_results
```

Candidate refresh V1 starts from either an `accepted_planning_state.v1` snapshot
or a `candidate_refresh.orbit_data` simple Cartesian state-estimate batch,
propagates the accepted spacecraft states across the remaining horizon, rebuilds
access, target-visibility, and eclipse windows, emits refreshed candidate
activities, emits Cadence-facing `contact_intent.v1` rows and
`resource_summary.v1` rows when supplied, filters candidates with unavailable
payload, antenna, ground-network resources, or configured fuel/power/storage/
downlink margin thresholds, and records both stale prior candidates and a
`candidate_diff_report.v1` comparing the refreshed candidate set to the prior
set. The diff report and its promoted `candidate_diff_row.v1` fixtures preserve
ID-set counts while also
recording semantic timing/source-window changes and replacement links for
matching observation or contact opportunities whose IDs changed across refresh.
Blocked or missing downlink contact-intent review/import rows can replay into V3
branch-local downlink-completion pressure while preserving provider-calendar
and station-reservation evidence for review routing.
Resource summaries preserve declared or provenance-supplied trust boundaries as
schema-visible `trust_boundary` fields while remaining planning-grade external
summaries rather than subsystem simulations. Resource filter and projection
reports carry the same resource trust boundary/provenance onto suppressed rows,
projection rows, and review/import contexts.
Duplicate candidate IDs are matched by row occurrence, so the diff does not
collapse duplicate prior or refreshed rows into one retained set member.
Semantic replacement links are emitted only when the semantic key has a single
candidate match; ambiguous prior or replacement matches are flagged with
candidate IDs/counts instead of selecting an arbitrary row.
Repair and strategy handoff preserve those candidate-diff ambiguity markers
instead of collapsing duplicate invalidated or replacement rows by ID, and lift
the key ambiguity fields onto operator-review and Cadence import rows.
Refresh filtering reuses the standalone contact/resource filter modules, so an
`approval_policy` on the refresh request carries the same row-level policy
evidence into embedded `contact_filter_report.v1` and
`resource_filter_report.v1` artifacts.
Refresh requests can also set
`candidate_limit_policy.max_candidate_activities`; the generated
`refresh_budget_report.v1` records the deterministic post-filter candidate
budget, kept IDs, dropped IDs, and selection order without claiming optimizer
search or schedule mutation. When duplicate candidate IDs survive filtering, the
budget accounts for kept and dropped rows by artifact occurrence instead of
collapsing by ID. V2 repair and V3 branch repair preserve that report as
`source_refresh_budget_report`, and V3 branch-generated refresh requests inherit
`candidate_refresh_defaults.candidate_limit_policy`.
`OrbitalDynamics.Communications.ContactFilter`,
`OrbitalDynamics.filter_contact_candidates/3`, and
`OrbitalDynamics.contact_filter_report/3` expose the same artifact-only
ground-network availability filter for standalone contact lists. It consumes
declared station windows and can suppress unavailable, reserved, or zero-capacity
downlink and tracking contacts, including direction-only station rows, while preserving the
no-provider-reservation and no-schedule-mutation boundary. Suppressed candidate
IDs are disambiguated when duplicate contact IDs are suppressed, preserving the
original candidate ID in `base_candidate_id` while preventing review/import row
identity collisions. The report also exposes row-derived
`station_reservation_match_status_counts` so consumers can route reserved-station
matches and overlaps without scanning every suppressed row. Supplying an
`approval_policy` classifies suppressed contact rows with
`approval_requirements`, `approval_rule_matches`, and `policy_decision.v1`
evidence so Cadence-facing review/import artifacts can distinguish blocked
station outages from operator-review station reservations or severe capacity
reductions. Contact allocation also accepts direction-only command/tracking
station rows and blocks any contact direction when declared station availability
is unavailable, maintenance, or zero-capacity.
`OrbitalDynamics.ResourceFilter`, `OrbitalDynamics.filter_resource_candidates/3`,
and `OrbitalDynamics.resource_filter_report/3` expose the same thin
resource-summary availability/margin filter for standalone candidate lists.
Suppressed resource candidate IDs are also disambiguated when duplicate IDs are
suppressed, preserving the original candidate ID in `base_candidate_id` for
review/import traceability.
Supplying an `approval_policy` classifies payload/degraded-resource
suppressions and margin-pressure suppressions with the same policy-decision
evidence used by downstream review/import rows; V1 campaign and candidate
refresh artifacts pass their approval policy into embedded resource-filter
reports.
`OrbitalDynamics.ResourceProjection` and
`OrbitalDynamics.resource_projection_report/3` expose the same selected-activity
storage/downlink projection report outside a campaign build while preserving
the planning-only resource model boundary. Single spacecraft-specific summaries
stay scoped to matching spacecraft or scenario IDs; only ID-less single summaries
project all selected activities, using `all_spacecraft` as the stable projection
row ID. Projection rows distinguish planned downlink capacity from
storage-limited data relief and warn when downlink capacity exceeds stored data
available in the roll-forward. The roll-forward is status-aware: canceled,
missed, failed, completed/executed/partial, and approval-rejected activities
remain in `activity_resource_flow` for audit with zero projected resource
effect, so inactive work cannot create false storage pressure or downlink
relief. Supplying an `approval_policy`
classifies projected storage overflow or downlink shortfall rows with
`policy_decision.v1` evidence and source rows expose the first activity that
creates storage overflow or downlink shortfall pressure so review/import queues
do not need to unpack nested flow rows to identify the trigger; V1/V2/V3
embedded projection reports pass their approval policy into that row-level
classification. V3 strategy branch
evaluation also promotes projected storage overflow and downlink shortfall into
branch-level risks so approval policy can block or route resource-pressure
futures before recommendation selection. Strategy operator-review packages lift
branch-local resource projection reports into `resource_projection_review` rows
so the same pressure evidence reaches Cadence-facing review/import queues.
It also emits `freshness_report.v1` so downstream repair can see
accepted-snapshot age, remaining-horizon alignment, and accepted-state quality
policy status. Candidate-refresh artifacts now include a nested
`contact_allocation_report.v1` over refreshed contact candidates so
branch-local refreshes preserve allocated/deferred contact semantics for
review-gated repair and strategy handoff. The checked-in
`candidate_refresh_v1` manifest also declares `operational_feedback` downlink
demand, producing required-downlink evidence and a deterministic
`downlink_completion_value` score term in the refreshed downlink row:

```bash
mix orbital_dynamics.study.run --manifest studies/candidate_refresh_v1.json --output study_results/candidate_refresh_v1.json --run-id candidate_refresh_v1-20260514 --generated-at 2026-05-14T00:00:00Z
mix orbital_dynamics.schema.lint --input study_results/candidate_refresh_v1.json --contract candidate_refresh.v1
mix orbital_dynamics.study.run --manifest studies/candidate_refresh_orbit_data_v1.json --output study_results/candidate_refresh_orbit_data_v1.json --run-id candidate_refresh_orbit_data_v1-20260514 --generated-at 2026-05-14T00:00:00Z
mix orbital_dynamics.schema.lint --input study_results/candidate_refresh_orbit_data_v1.json --contract candidate_refresh.v1
```

Simple external Cartesian state-estimate batches can be normalized into the same
accepted planning-state contract through `OrbitalDynamics.OrbitData`. Orbit-data
imports stamp adapter provenance with the input format, import adapter,
external trust boundary, and explicit no-network-access marker so downstream
planning artifacts can distinguish accepted state content from import context:

```bash
studies/accepted_planning_state_simple.json
study_results/accepted_planning_state_simple.json
mix orbital_dynamics.schema.lint --input study_results/accepted_planning_state_simple.json --contract accepted_planning_state.v1
```

`OrbitalDynamics.OrbitData` also has deliberately narrow CCSDS OPM and OEM KVN
adapters for single-object Earth-centered `EME2000`/`J2000`/`ICRF` Cartesian
state handoff. The OPM adapter imports OPM text into
`accepted_planning_state.v1`, preserves object/reference-frame metadata and
`COV_REF_FRAME` provenance, preserves a single declared `MAN_*` maneuver block
as metadata-only `maneuver_execution_delta` evidence, and can export a single
accepted state back to deterministic OPM KVN for compatibility tests. The OEM
adapter imports a single-object Cartesian ephemeris by selecting one declared
sample without interpolation and recording the sample-selection policy in
provenance, and can export a single accepted state as a single-sample OEM KVN
handoff with explicit `INTERPOLATION = NONE`. Both adapters stamp the same
adapter trust-boundary provenance used by simple JSON imports, reject duplicate
single-value KVN fields instead of silently overwriting them, and preserve
covariance matrix terms as metadata-only planning evidence instead of applying
covariance-aware propagation.

TLEs are intentionally handled as a separate preflight boundary:
`OrbitalDynamics.inspect_tle/2` validates line checksums and catalog-number
consistency, rejects multi-object drops as ambiguous metadata preflight input,
derives mean-element period, altitude, and coarse altitude-regime metadata for
triage, and returns metadata marked as requiring `sgp4`. Those mean-element
altitudes are preflight estimates, not propagated Cartesian state. TLE wrappers
are not accepted by `OrbitalDynamics.import_orbit_data/2` because they cannot be
converted into this project's Cartesian accepted-state contract without a
separate SGP4 propagation regime. TLE metadata still carries the same external
orbit-data trust-boundary provenance.
CCSDS OMM KVN follows that same mean-element preflight rule:
`OrbitalDynamics.inspect_ccsds_omm/2` parses object/catalog/frame/time-system
and declared `MEAN_ELEMENT_THEORY` metadata, rejects duplicate single-value
fields, derives mean-element period and altitude-regime triage, and marks the
record as not compatible with `accepted_planning_state.v1`. OMM wrappers are
likewise rejected by `OrbitalDynamics.import_orbit_data/2` with parsed metadata
attached for review.

```bash
study_results/accepted_planning_state_opm.json
mix orbital_dynamics.schema.lint --input study_results/accepted_planning_state_opm.json --contract accepted_planning_state.v1
study_results/accepted_planning_state_oem.json
mix orbital_dynamics.schema.lint --input study_results/accepted_planning_state_oem.json --contract accepted_planning_state.v1
```

Validation records and curated internal reference fixtures are also executable
artifact contracts. The checked-in report currently covers two-body and J2
propagation fixtures, sampled access-window, eclipse, and target-visibility
event fixtures, a sampled ground-track crossing fixture, plus product-level
campaign V1, repair V2, and strategy V3 artifact contract fixtures:

```bash
study_results/validation_reference_fixtures.json
mix orbital_dynamics.schema.lint --input study_results/validation_reference_fixtures.json --contract validation_reference_fixture_report.v1
study_results/campaign_request_lint_v1.json
mix orbital_dynamics.campaign.lint --type repair --request studies/leo_constellation_campaign_repair_v2.json --output study_results/campaign_request_lint_v1.json
mix orbital_dynamics.schema.lint --input study_results/campaign_request_lint_v1.json --contract campaign_request_lint.v1
```

Result artifacts include `payload_metrics` with compact JSON byte counts and
row counts by top-level section so benchmark and distribution work can reason
about result-transfer costs without decoding every payload by hand. They also
include `execution_report.v1`, a compact run review record with execution mode,
task settings, deterministic execution-plan metadata, adaptive chunk-size
recommendations for task-supervisor runs, phase timings, node distribution, and
per-scenario failure rows. It is audit metadata; opt-in interrupted execution
uses the separate `study_checkpoint.v1` file, while `--resume` continues to
reuse only an already validated complete output. Study run assumptions and run
metadata also include `external_provider_policy`, which defaults to
offline-only and records any explicitly configured provider boundaries; explicit
external provider rows must carry a direct or provenance-supplied
`trust_boundary`. They
also include `backend_selection_policy`, which keeps scalar Elixir as the
reference default and labels Nx/EXLA-style batch backends as experimental
accelerators unless benchmark artifacts justify stronger claims.
Campaign plan artifacts also carry `contact_contention_report.v1` for
same-station overlapping downlink candidates; the report is advisory and does
not reserve station time or suppress contacts. Conflict groups carry station
IDs, timing bounds, downlink direction, source-window IDs, required operator
action, approval status, optional approval-policy evidence, and provenance for
review/import queues. Duplicate contact IDs inside a conflict group are counted
as ambiguous contact identity, and resolution reports with duplicate candidate
IDs route to operator review without emitting a deterministic selected contact.
`OrbitalDynamics.Communications.ContactContention` and the public
`OrbitalDynamics.contact_contention_report/2`,
`OrbitalDynamics.annotate_contact_contention/2`, and
`OrbitalDynamics.contact_contention_resolution_report/3` facades expose the same
artifact-only behavior for standalone contact candidate lists.
V1 campaign plans also emit `objective_tradeoff_report.v1`, which turns ranked
timeline score terms into deterministic per-scenario tradeoff rows without
changing the selected plan.
Planner-local V1/V2 constraints are summarized by
`OrbitalDynamics.Constraints.CampaignLocal` as `constraint_report.v1` rows for
active max-timeline-activity, minimum-duration, eclipse-avoidance,
resource-projection margin, and fixed-rate link-capacity constraints. The
top-level `OrbitalDynamics.campaign_local_constraint_report/6` facade exposes
the same row model for callers that already have candidate activities, ranked
timelines, and optional resource/link reports. V3 branch-comparison rows
preserve the nested V2 repair constraint counts/statuses so strategy review can
scan inherited planner-local constraint outcomes without unpacking each branch
repair artifact.
They also flatten resource-projection availability pressure, including
unavailable spacecraft, payload-unavailable, degraded-payload, and
antenna-unavailable spacecraft IDs/counts, so review queues can scan branch
resource risk without reopening nested projection flow rows.
Search and what-if ranking comparisons can be promoted to
`ranking_comparison_report.v1`, which records pairwise rank/value deltas and
winner-change metadata without claiming solver optimization. Those reports can
also be normalized into `operator_review_package.v1` ranking-comparison review
rows for approval/import gates. Study artifact comparisons emit the same ranking
comparison report when both inputs carry compatible declared rankings.
Multi-objective alternatives can also be summarized with
`pareto_frontier_report.v1`, an explainable dominance report over supplied
objective vectors. It records frontier/dominated IDs and objective directions
without performing local search or invoking an external solver. V3 strategy
artifacts embed the same report over branch comparison objectives and normalize
the rows into operator-review/Cadence-import handoff records.
Strategy branch score terms are also normalized into `score_term_report.v1`
rows keyed by branch ID, so operator-review and Cadence-import handoff can
inspect expected score, mission value, resource, feedback, risk, approval-load,
and schedule-stability terms through the same report shape used by V1/V2.
Branch score deltas from the recommended branch are also emitted as
`objective_tradeoff_report.v1` rows with the same branch identity.
When contention exists, `contact_contention_resolution_report.v1` recommends a
preferred contact using deterministic score, priority, and tie-breaker policy
while leaving the candidate set unchanged for operator review. Each
recommendation carries the effective selection rule, priority fields, tie
breakers, and any unsupported requested policy evidence through operator-review
and Cadence-import rows, so review queues can explain the recommendation without
reopening the report-level policy object. Supplying an `approval_policy`
classifies both contention groups and resolution recommendations with
`policy_decision.v1` evidence. `OrbitalDynamics.organization_policy_bundle/3`
can build schema-valid organization-specific policy bundles with adapter
provenance; those bundles can be passed inline to the same decision path without
executing approval workflows.
`OrbitalDynamics.Communications.LinkCapacity` and
`OrbitalDynamics.link_capacity_report/3` expose the same fixed-rate
`link_capacity_report.v1` summary for standalone contact lists, including
station-capacity-adjusted throughput from declared capacity fractions and
optional declared downlink requirements. Selected capacity now requires a
selected contact ID to match exactly one candidate row; duplicate candidate IDs
and unmatched selected IDs are reported explicitly and excluded from
selected-throughput totals. Terminal or approval-rejected downlinks remain in
the report with `ignored_contact_ids` / `ignored_selected_contact_ids`, but do
not contribute available or selected capacity. When `policy.required_downlink_mb` or
`policy.required_downlink_mb_by_ground_station` is supplied, the report records
selected downlink shortfall and requirement status for review/import. Supplying an `approval_policy`
classifies reduced-capacity station rows with
`policy_decision.v1` evidence, and V1 campaign plus V2 repair artifacts pass
their approval policy into embedded link-capacity reports. This is a planning
artifact, not a link-budget or reservation model.
`OrbitalDynamics.Communications.ContactAllocation`,
`OrbitalDynamics.allocate_contacts/3`, and
`OrbitalDynamics.contact_allocation_report/3` compose the declared
ground-network filter and same-station contention recommendations into
artifact-only allocated, deferred, and blocked contact rows. These rows are for
review and planning handoff; they do not reserve provider time, approve
contacts, or mutate schedules. Duplicate contact IDs are blocked as explicit
operator-review rows before station filtering or contention allocation, keeping
identity joins deterministic and preventing exported allocation-row ID
collisions. Supplying an `approval_policy` classifies
reviewable allocation rows with `policy_decision.v1` evidence, preserving the
rule matches and escalation metadata behind blocked or operator-review contact
allocation outcomes. The embedded station-calendar affected-contact rows
receive that same policy evidence, so outage, reservation, and reduced-capacity
context remains reviewable before allocation rows are flattened. Embedded
contact-filter suppressions receive the same policy evidence, so source
suppression rows do not lose the rule match that produced a blocked allocation
row. Terminal or source approval-rejected contacts are kept as blocked
allocation rows with contact-status evidence, but they are not passed into
station filtering, contention resolution, or the returned allocated-contact
list. Status-blocked realized contacts preserve actual-throughput and
completed-fraction evidence through allocation, review, and import surfaces,
while the remaining model limit is explicit: no full realized-provider contact
reconciliation. Supplying `resource_summaries` to allocation runs the same
planning-grade resource filter before station allocation, embedding a
`resource_filter_report.v1`
and preserving antenna, spacecraft, power, fuel, storage, payload, and
downlink-margin suppressions as blocked allocation rows for review/import
handoff. Allocation rows also preserve station-calendar overlap IDs/counts and
reservation overlap evidence for downstream review/import adapters. V1 campaign
plans and candidate refresh artifacts pass
their approval policy into embedded allocation reports, and candidate refresh
keeps raw refreshed contacts visible there as blocked rows even when contact
filtering suppresses them from the usable candidate set. V1 campaign plans embed the same
`contact_allocation_report.v1` over campaign contact candidates, and V2 repair
artifacts emit it over repaired contact activities so repaired-plan allocation
rows remain separate from source refresh allocation rows. Allocation reports
normalize into `operator_review_package.v1`
`contact_allocation_review` rows and `cadence_import_manifest.v1`
`review_contact_allocation` rows for review-gated Cadence adapter handoff.
When a campaign includes `ground_network` availability or capacity intervals,
V1 artifacts also emit `station_calendar_report.v1` and annotate affected
contacts without making provider reservations.
Campaign manifests declare those intervals under `campaign.ground_network`.
`OrbitalDynamics.station_calendar_report/3` can build the same artifact-only
overlay from contact candidates and a declared `station_calendar_provider.v1`
or ground-network interval list for downstream station-availability review.
Declared station-calendar provider inputs must include a trust boundary either
as `trust_boundary` or `provenance.trust_boundary` before they pass schema
validation, and that boundary is preserved on normalized station-calendar
review rows.
Affected-contact row IDs are disambiguated when duplicate contact IDs overlap
the same calendar entry, preserving every candidate row while preventing
review/import row ID collisions.
Supplying an `approval_policy` classifies affected contacts with
`policy_decision.v1` evidence, so unavailable station time, reserved overlaps,
and severe capacity reductions can be routed through the same review/import
surface without reserving provider time. V1 campaign and repair-time
station-calendar reports use that same classification path.

Executable artifact contracts can also be exported as top-level JSON Schema
documents for compatibility checks and downstream tooling. Nested semantic
validation still lives in `OrbitalDynamics.Schema`, and the schema bundle embeds
the compatibility policy that treats required-field removals, exported type
changes, and schema contract/version changes as breaking. It also declares the
stable identity policy used by schema linting for public artifact IDs.
Schema lint can emit machine-readable `schema_validation_report.v1` and
`schema_validation_batch_report.v1` wrappers for artifact-import gates. Failing
reports include remediation rows with the invalid path, issue category, and
suggested action:

```bash
mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign.json --format json
mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign.json --output study_results/schema_validation_report_v1.json
mix orbital_dynamics.schema.lint --all --input-dir study_results
```

`approval_requirement.v1` rows include a machine-readable `requirement_type`
such as `contact_schedule_change`, `maneuver_timing_change`, or
`strategic_addition` so Cadence-facing review queues do not have to infer the
operator boundary from free-text reasons:

```bash
mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json
mix orbital_dynamics.capabilities --format json
mix orbital_dynamics.schema.lint --input study_results/capability_catalog_v1.json --contract capability_catalog.v1
```

Sampled event detectors annotate access, eclipse, and target-visibility windows
with `event_timing_policy`, `event_time_tolerance_s`, and `max_sample_step_s`
metadata so downstream planning artifacts keep timing assumptions visible.
Observation candidates also carry sampled eclipse-overlap lighting summaries:
the stable coarse `lighting_condition`, a finer overlap-fraction band, the
numeric eclipse-overlap fraction, and confidence text that keeps the sampled
cylindrical-shadow limit explicit.
Station calendar provider artifacts can mark declared maintenance,
capacity-reduction, unavailable, or reserved intervals; the resulting
`station_calendar_report.v1` remains artifact-only and exposes reserved-overlap
contention metadata plus optional approval-policy evidence without reserving
station time.
`OrbitalDynamics.Validation.tolerance_policy/0` documents the comparison model,
validation-level vocabulary, and the current rule that sampled event timing is
bounded by maximum adjacent trajectory sample spacing rather than by a refined
root solve. `OrbitalDynamics.Validation.backend_acceptance_policy/0` documents
reference-default and experimental-accelerator backend acceptance tiers.
`OrbitalDynamics.dependency_policy/0` records that Nx is required while
Nx-backed modules compile unconditionally, while EXLA remains optional for
experimental accelerator backends. The validation and backend policies have
executable schema contracts and checked-in lintable examples.
`OrbitalDynamics.latitude_crossings/3` and
`OrbitalDynamics.longitude_crossings/3` expose sampled geocentric crossing
detectors for standalone event analysis; longitude crossings default to the
inertial trajectory frame and can opt into the same constant-rotation
`frame: :body_fixed` approximation used by access geometry. Body-fixed requests
may declare a constant `rotation_rate_rad_s`, `rotation_epoch_s`, and
`rotation_angle_offset_rad`; `OrbitalDynamics.refine_ground_track_crossing_boundary/3`
exposes the same linear bracketed-sample interpolation for coarse timing
handoffs. This is still an explicit approximation, not an
Earth-orientation provider. Study manifests can also request
`ground_track_crossings` with `ground_track_crossings` request rows, and result
artifacts emit `ground_track_crossings` rows with timing and coordinate-model
assumptions.

```bash
mix orbital_dynamics.study.run --manifest studies/ground_track_crossings.json --output study_results/ground_track_crossings.json --run-id ground_track_crossings-20260514 --generated-at 2026-05-14T00:00:00Z
```

Result artifacts also archive `environment_models` capability records for
simplified fixed-Sun and constant-Earth-rotation assumptions, so downstream
consumers can tell which environmental approximations were used without
treating them as authoritative ephemeris or Earth-orientation providers.

To run scenarios on another connected BEAM node, start the worker with the same
cookie and application code path, then add `task_supervisor_node` to manifest
`run_options`:

```bash
elixir --sname worker --cookie orbital_dynamics -S mix run --no-halt
```

```json
"run_options": {
  "max_concurrency": 8,
  "task_supervisor_node": "worker@127.0.0.1"
}
```

The worker node must be running `OrbitalDynamics.Application`; the study artifact
records `execution_mode`, `task_supervisor_node`, and the node that evaluated
each trajectory.

Benchmark complete study execution modes:

```bash
mix orbital_dynamics.study.benchmark --manifest studies/raise_apogee_search.json --mode local --repetitions 3 --output study_results/study_benchmark.json
mix orbital_dynamics.study.benchmark --manifest studies/raise_apogee_search.json --mode local --mode remote --task-supervisor-node worker@127.0.0.1 --repetitions 3
```

Benchmark Monte Carlo scaling by overriding the manifest sample count:

```bash
mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --repetitions 3 --monte-carlo-counts 20,200,2000 --output study_results/monte_carlo_scaling.json
mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode remote --task-supervisor-node worker@127.0.0.1 --repetitions 3 --monte-carlo-counts 20,200,2000
mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode distributed --task-supervisor-node worker@127.0.0.1 --repetitions 3 --monte-carlo-counts 200,2000,20000
mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode distributed --task-supervisor-node worker@127.0.0.1 --task-chunk-size 100 --repetitions 3 --monte-carlo-counts 200,2000,20000 --output study_results/distributed_monte_carlo_chunked.json
mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode distributed --task-supervisor-node worker@127.0.0.1 --task-chunk-sizes 1,10,50,100,250,500 --repetitions 3 --monte-carlo-counts 2000,20000 --output study_results/distributed_chunk_sweep.json
mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode distributed --task-supervisor-node worker@127.0.0.1 --task-chunk-sizes 50,100,250,500 --max-concurrencies 4,8,16 --repetitions 3 --monte-carlo-counts 2000,20000 --output study_results/distributed_concurrency_sweep.json
mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --propagators two_body,two_body_nx_compiled,two_body_exla_cpu --max-concurrency 8 --repetitions 2 --monte-carlo-counts 200,2000 --output study_results/nx_study_benchmark.json
```

Report a saved study benchmark artifact:

```bash
mix orbital_dynamics.study.benchmark.report study_results/monte_carlo_scaling.json
mix orbital_dynamics.study.benchmark.report study_results/distributed_chunk_sweep.json --scale-target v2_repair
mix orbital_dynamics.study.benchmark.report study_results/distributed_chunk_sweep.json study_results/distributed_concurrency_sweep.json --scale-target v2_repair
mix orbital_dynamics.study.benchmark.report study_results/distributed_chunk_sweep.json study_results/distributed_concurrency_sweep.json --scale-target v2_repair --format json
```

The study benchmark report prints median timings, local speedup, scheduler
utilization, per-node trajectory counts, and a node-balance ratio for
distributed runs. Each summary group also carries backend-acceptance evidence
from `backend_acceptance_policy.v1`, separating reference-backend acceptance
from experimental accelerator speedup claims. When multiple benchmark artifacts
are provided, the report prints a trend summary that matches benchmark groups by
mode, propagator, count, chunk size, and concurrency, then reports median-runtime
deltas in `generated_at` order. With `--scale-target`, trend output also carries
the aggregate operational-scale trend status. Use `--format json` for
machine-readable single-artifact or trend summaries.
