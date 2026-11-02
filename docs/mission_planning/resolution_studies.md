# Resolution and service-window studies

`MissionAnalysis.ResolutionStudy` compares explicit sampling and integration
levels against the finest tested level. The example holds the mission inputs
fixed while varying one numerical control at a time. It reports changes in
physical duration support, scheduling, asset selection, and window/activity
endpoint timing. Agreement is evidence about the tested resolutions, not a
convergence proof, physical uncertainty bound or operational approval.

## Run and inspect

```sh
mix orbital_dynamics.mission.resolution --study studies/illumination_resolution.json --output-dir tmp/illumination_resolution
mix test test/orbital_dynamics/mission_analysis
```

Open `tmp/illumination_resolution/README.md` for the comparison table.
`comparison.csv` contains the level controls and service/scheduling totals.
`report.json` contains exact study/baseline inputs, per-level provenance,
comparisons, transition brackets, activity endpoint evidence and sampled margins.
The standalone `mission_resolution_study.v1` format is an experimental report,
not a registered campaign artifact or executable plan.

The CLI resolves `baseline_manifest` relative to the study file. It writes errors
to the report and returns a failure if any level fails. Evaluation errors are
never converted into zero service or a stable result. Only the narrow Earth/J2
reference adapter is selected by this CLI; other missions can use the generic
`ResolutionStudy.run!/3` evaluator contract directly.

## Independent numerical controls

The existing propagator advances to every requested output epoch. Merely
reducing its output cadence would also reduce its integration steps. The new
reference adapter instead propagates fixed integration anchors, then uses
`J2Sampler` to evaluate requested epochs from the preceding anchor with local
RK4 propagation. Queries do not advance or change the anchors; there is no
Cartesian linear interpolation. This is a piecewise numerical approximation,
with its own error, not an analytic ephemeris or independently validated dense
output scheme.

The example uses these controls:

| Level | Observation cadence | Integration anchor step |
| --- | --- | --- |
| Reference | 1 s | 1 s |
| Sampling comparisons | 20, 10, 5 s | 1 s |
| Integration comparisons | 1 s | 10, 5 s |

Every level uses the same **one-second tracking lookback**, 0.01-second transition
bracket tolerance, and 0.1-second window/schedule comparison tolerances. Holding
the tracking lookback fixed avoids redefining the secant-rate constraint at each
sample or bisection iteration. It remains a finite-lookback estimate, not an
instantaneous angular-rate bound. The source anchor coverage must include both
states used by that estimate. Early samples lacking a predecessor fail the
models' rate-known checks.

The generic runner requires 2–16 distinct numerical level combinations and one
named reference using the smallest tested sampling and integration steps.
Sampling levels must retain the reference integration step; integration levels
must retain the reference observation cadence. The evaluator must return sampled,
refined `MissionAnalysis` reports for the same mission and fixed model assumptions.
The reference adapter inherits the reference mission's finite environment,
propagation, sample-count and evaluation limits. Overlarge levels remain explicit
errors; the CLI does not silently coarsen them.

## Transition refinement

`WindowRefinement` is opt-in through `MissionAnalysis.run/4`'s
`window_refinement` option. A caller supplies a state sampler, fixed tracking
lookback, epoch tolerance, and transition-evaluation budget. The sampler receives
an asset and an absolute epoch in its declared time scale; returned states must
preserve the requested epoch, frame and scale. It must represent one consistent,
deterministic trajectory throughout the analysis.

The runner evaluates the full requested grid, includes clipped request/trajectory
endpoints, groups eligible runs without bridging explicit gaps, and bisects
adjacent eligible/ineligible samples at observed run boundaries. An entry bracket
keeps its eligible endpoint on the inside; an exit bracket does the same. Those
inside endpoints determine the window used by the ordinary duration filter and
scheduler. A single eligible seed can therefore support a refined window after
both neighboring transitions have been examined. Short windows are retained in
`window_evidence` even when they cannot support the request duration.

Each edge records one of:

- `observed_transition_bracket`: inside/outside epochs, actual bracket width and
  checks failing at the outside endpoint.
- `request_or_coverage_clip`: no transition was located beyond the analysis domain.
- `sample_gap_clip`: no evidence bridges the neighboring sample gap.

A clip's zero `width_s` is not a zero-uncertainty physical boundary; its kind and
limits state that no transition was located there. Bracket widths describe
numerical epoch resolution only. They do not include model, orbit or environment
uncertainty, and outside check names do not establish a unique causal constraint.

Bisection refines **observed** transitions. It can miss multiple crossings, short
windows between ineligible seeds, and ineligible islands between eligible seeds.
It does not certify continuous feasibility. Full-horizon finer-grid comparisons
are retained specifically to reveal some of these failures. A synthetic regression
demonstrates a missed dip that becomes visible on the finer grid, changes duration
support and causes the stability report to flag the schedule.

The `max_extra_evaluations` setting bounds transition/clipping probes per
asset/request pair; `transition_refinement_evaluation_count` records those calls.
Scheduled start/end evaluations are additional, explicitly counted as
`endpoint_evaluation_count: 2` on each selected activity. Ordinary grid evaluations
remain subject to the existing core cap. Budget exhaustion, precision exhaustion,
provider failures and invalid sampler output abort that analysis instead of
returning a partial refined plan.

After scheduling, the runner evaluates each actual selected start and end under
the **same captured model session** used for the windows. A failed endpoint or
provider error aborts the refined result. Passing endpoints do not establish
feasibility between them. Reported activity samples include these endpoints,
tested sample count, and the largest remaining interval between tested points.

## Signed margins and duration evidence

Illumination and imaging numeric checks now carry optional `margin`,
`margin_unit` and `margin_comparison` fields. Positive margin is headroom, negative
margin is a violation, and zero is a boundary. For minimum requirements, margin
is actual minus threshold; for maximum limits it is threshold minus actual.
The check's `passed` boolean remains authoritative, including strict inequalities.

The report summarizes margins only from evaluated points on the selected asset
inside the selected activity, including its checked endpoints. It records the
minimum sampled margin, units, numeric sample count, and unknown/categorical count
for each check. Missing rates and categorical checks such as sunlight retain no
invented numeric headroom. Units are never combined into one minimum score.

`margin_thresholds` optionally declares a per-check `unit` and
`minimum_headroom`. The assessment is `near_declared_limit` if sampled headroom
falls below that declared amount, or `meets_declared_sampled_headroom` otherwise.
Without a threshold, no robustness threshold is invented. Unknown margins,
inconsistent units, and threshold-unit mismatches are labeled explicitly. These
flags describe sampled headroom; they are not probabilities or error allowances.

Each selected activity also reports its supporting refined window and
`duration_headroom_s`: that window's inside-endpoint span minus requested duration.
This excludes intervals outside the window and does not aggregate assets. Neither
this headroom nor sampled margins guarantee service throughout the activity.

## Stability and example result

Per-request comparisons check physical opportunity counts, scheduling status and
reasons, matched window counts/assets, selected asset counts, and endpoint timing.
Timing deltas use the declared tolerances. Missing requests or failed levels are
unknown comparisons. Aggregate `stable_across_tested_levels` means every other
successful comparison agrees with the declared finest level, with no unknown
comparisons. It is not a statement that still finer resolutions would agree.

For the checked-in synthetic illumination case, all six levels schedule the
40-second request and agree within the configured 0.1 seconds. The reference
refined window is approximately **1.000 to 166.797 seconds after the initial
epoch**. The exit's outside sample fails minimum elevation. The entry's outside
sample lacks the required one-second tracking predecessor; this is an evidence
availability boundary, not a prediction of acquisition time.

The reference activity runs from approximately 1 to 41 seconds, with about
125.8 seconds of sampled-window duration headroom. Its minimum sampled headrooms
are about 9.99° elevation, 0.0003075 W/m² nominal irradiance, and 1.577°/s tracking
rate. The reference's largest interval between tested activity points is 1 second;
the 20-second sampling level still has a 20-second unresolved interval. Agreement
on the endpoints does not erase that difference in internal evidence.

The earlier reference command uses preceding-grid tracking samples and no window
refinement, so it scheduled from 20 seconds. Comparing that start directly with
this study would conflate sampling, lookback and refinement policies. The study
therefore holds its own lookback policy fixed across levels and records it.
There is still no achieved attitude, acquisition/settling, transition slew, cloud,
thermal/power dynamics or continuous physical-service certification.

## Optional acquisition and slew checks

The [attitude-planning path](attitude_planning.md) now consumes the same reference
state sampler and refined windows to add full-orientation profiles and declared
kinematic transition checks. The resolution command keeps its own policy; its
agreement alone still says nothing about acquisition or slew feasibility.

## Verification boundary

Focused tests cover analytic fractional crossings and short windows, clipping,
integer/float epoch identity, bounded refinement, provider/sampler failures,
original-session reuse, endpoint rejection, explicit gaps, hidden dips,
independent sampling/integration controls, signed real-model margins, unit and
categorical handling, changed/stable/unknown comparisons, and CLI success/failure
artifacts. The existing pinned Orekit baseline comparison still passes; it checks
its original matched-input trajectory/geometry, not this new refinement method,
continuous service, or operational readiness.

Validation for this slice: all 5,128 fast-suite tests passed (1,133 integration/
exhaustive tests excluded), and all 46 focused analysis/mission CLI tests passed.
The six-level example completed without errors. Independent review findings about
numeric epoch identity, anchor admission and captured-session reuse were resolved
and regression tested; the final review found no remaining blocker. Formatting
and diff whitespace checks passed. Full integration/exhaustive suites were not rerun.
