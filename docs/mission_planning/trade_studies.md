# Mission trade studies

The generic `MissionAnalysis.TradeStudy` runner evaluates a bounded Cartesian grid
of explicit configuration changes. It answers how a declared reference mission
responds to different inputs; it does not estimate Reflect Orbital's capabilities.
The CLI uses the existing Earth/SSO reference adapter. Other mission models can
use the same sweep API with their own configuration evaluator.

## Run

```sh
mix orbital_dynamics.mission.check_baseline --output tmp/baseline_check.json
mix orbital_dynamics.mission.sweep --study studies/illumination_trade.json --output-dir tmp/illumination_trade
mix test test/orbital_dynamics/mission_analysis
```

Open `tmp/illumination_trade/README.md` for the comparison table. Generated files:

| File | Contents |
| --- | --- |
| `comparison.csv` | Baseline and case labels, physical support counts, scheduled requests, scheduled duration, opportunities, errors |
| `metrics.csv` | Per-request numeric metric ranges and sample counts for eligible samples and sampled selected intervals |
| `checks.csv` | Per-request evaluated, failed, and sole-failure sample counts for each check |
| `report.json` | Exact baseline configuration, all axis updates, per-case assumptions/provenance, errors, and detailed summaries |

The standalone `mission_trade_study.v1` and `mission_baseline_check.v1` formats
are experimental reports, separate from the registered campaign artifact schemas.
They are not command sequences or approved plans.

## Configure a grid

A study contains `study_id`, `baseline_manifest`, `max_cases`, and `axes`.
The baseline path resolves relative to the study file. Each axis contains an `id`
and named `cases`. Each case contains an `id` and explicit `updates`, for example:

```json
{
  "id": "mirror",
  "cases": [
    {
      "id": "100m2",
      "updates": [
        {"path": ["assets", 0, "payloads", "illumination", "mirror_area_m2"], "value": 100},
        {"path": ["assets", 0, "payloads", "illumination", "mirror_max_dimension_m"], "value": 10}
      ]
    }
  ]
}
```

String path components select existing map keys; integer components select
existing list indices. Paths cannot create keys or overlap other updates. All
cases within an axis must update the same paths. A case can update correlated
inputs, such as mirror area and dimension or target latitude and longitude.
This prevents an area sweep from accidentally retaining an inconsistent mirror
size. The baseline is always evaluated separately, even if a grid point repeats it.

The full grid is validated before evaluation. The runner accepts 1–12 axes,
1–256 cases per axis, and at most 256 total combinations, excluding the baseline;
`max_cases` may set a smaller upper bound on grid size. It never silently truncates
a grid. Cases run sequentially in declared order, with deterministic IDs and no
randomness or runtime timestamps. Each case currently reruns propagation; there
is no hidden trajectory cache. Reduce the grid for quick experiments.

The evaluator contract is `configuration -> {:ok, mission_analysis_report} |
{:error, reason}`. It must retain samples (`include_samples: true`) so the summary
can compute diagnostics. Tagged evaluator errors remain explicit case errors,
with no zero-filled performance summary. The reference CLI converts input/model
validation failures to case errors. Unexpected evaluator exceptions propagate.

## Interpret the results

Physical support means that a request has at least one sampled eligible window
long enough for its requested duration, on one asset. Scheduling then applies
asset conflicts, separation, declared budgets and greedy selection. A physically
supported request can remain unscheduled. The JSON preserves both statuses and
scheduling reasons. `longest_eligible_run_span_s` also exposes an eligible window
that was too short for the request; spans are not added across assets or gaps.
Missing asset capabilities are preserved as pair statuses.

Metrics retain their model-defined unit suffixes. Eligible ranges summarize all
eligible samples for that request across assets. Selected-interval ranges use
only samples on the selected asset within the selected activity's endpoints.
They are not time-integrated delivery, minima guaranteed between samples, or
resolution/irradiance bounds over a physical footprint. A selected interval can
contain few samples. Boolean, missing, and vector metrics are not numeric ranges.

Failed checks are nonexclusive: one sample can fail several constraints. A
sole-failure count means exactly one check failed at those samples. It does not
prove that relaxing that constraint would create a long enough service window.
Counts include all evaluated asset/request sample pairs; pair counts can grow
when adding assets and must not be interpreted as a service percentage.

All comparisons inherit the same short horizon, synthetic target choice,
initial orbital phase, and analytic model limits. Changing duration does not
recompute the example's declared activity energy cost: costs are explicit totals,
not rates. Update costs in the same axis when studying a duration-dependent cost.
Do not compare scheduled seconds as though configurations requested identical
service when the duration axis itself changes that request.

## Example observations

The checked-in illumination grid contains 128 cases: two values each for altitude,
ascending-node time, mirror area, tracking limit, target latitude, service duration,
and minimum irradiance. In the current model, 9 of 128 combinations support and
schedule the single request, and the baseline schedules 40 seconds.

Within this exact grid, all nine scheduled cases use the 2°/s tracking limit,
18-hour node, and 0.0001 W/m² requirement. Eight use the 400 m² mirror; one uses
100 m². These are counts over a deliberately chosen grid, not probabilities,
independent causal effects, orbit recommendations, or constellation coverage.
The JSON and diagnostic CSVs show which checks fail in each configuration.

## Check numerical sensitivity

The separate [resolution study](resolution_studies.md) compares sampling and
integration controls independently, refines observed transition brackets, and
reports sampled margins and schedule stability. The trade grid retains its
original preceding-grid tracking and unrefined-window policy; its results should
not be directly equated with a refined study that changes those policies.

## Independently checked baseline

`BaselineCheck` compares the baseline against a newly generated Orekit 13.1.7 /
Hipparchus 4.0.3 reference. The Java generator receives circular elements and
matched environmental inputs, not Elixir-computed Cartesian states or geometry.
It uses Orekit element conversion, adaptive Dormand–Prince integration, J2 force,
spherical topocentric geometry, and cylindrical-shadow routines.

The checked-in reference covers 301 epochs at 20-second intervals over 6,000
seconds for the baseline 600 km orbit. Against production RK4 with maximum
10-second steps, the observed maximum errors are approximately:

| Quantity | Observed maximum absolute difference | Acceptance tolerance |
| --- | --- | --- |
| Cartesian position norm | 0.015 m | 1 m |
| Cartesian velocity norm | 0.0000163 m/s | 0.002 m/s |
| Target slant range | 0.0106 m | 1 m |
| Target elevation | 0.0000000523° | 0.0001° |
| Off-nadir angle | 0.0000000530° | 0.0001° |
| Target solar elevation | 0.00000000000362° | 0.000000001° |

All 301 samples agree as sunlit. This baseline has no shadowed samples, so it
provides no eclipse entry/exit validation. The comparison imports inclination,
RAAN, Sun directions and rotation angles. It does not independently validate SSO
design, ephemeris accuracy, Earth orientation, frame or time conversion, mirror
optics, imaging GSD, tracking, scheduling, or other grid configurations. It uses
an explicit matched-axis assumption and a dummy TAI epoch with elapsed seconds.
It does not change the propagator's declared validation level.

The generator, physical inputs, locked dependency digests, output CSV and checksum
manifest are checked in under
[`priv/validation/mission_analysis_orekit`](../../priv/validation/mission_analysis_orekit/README.md).
The offline checker pins the manifest digest in code and verifies every listed
file before comparing results. Regeneration requires Docker/network access;
ordinary tests and comparisons do not. A second generator run produced identical
output bytes.

## Development evidence

Focused tests cover Cartesian expansion and deterministic replay, correlated
updates, preflight path/grid rejection, explicit case errors, physical versus
resource rejection, duration-limited windows, asset-specific metric ranges,
nonexclusive and sole-failure counts, omitted-sample rejection, independent
baseline tolerances, tamper rejection, and both new CLI paths. The existing
illumination/imaging reference tests also exercise the `ReferenceMission.prepare!`
refactor without changing its output contract.

Validation for this slice: all 5,111 fast-suite tests passed (1,131 integration/
exhaustive tests excluded). The focused analysis and mission CLI checks passed
all 27 tests in 1.7 seconds after compilation. The full 128-case example and
offline baseline CLI were exercised, and the Orekit output was regenerated with
identical bytes. Independent review findings about omitted samples were resolved
and tested; the final review found no blocking issues.
