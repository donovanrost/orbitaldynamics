# Repeated service planning workload

This is a separate workload for comparing planning quality when spacecraft can
perform multiple services. The original single-token constellation benchmark
and its input files are preserved.

```sh
MIX_ENV=test mix orbital_dynamics.mission.workload --output-dir tmp/repeated_service
```

Each successful strategy run writes its physical report and summary checkpoint
before the next strategy begins, so a later failure retains completed evidence.
The input/output checks resolve directory aliases and reject linked output files.

The task now compares greedy, bounded reassignment and bounded replacement using
the same reference study. Historical two-strategy observations below are preserved;
see [protected_replacement.md](protected_replacement.md) for the new comparison.
`--max-trials 4` is the default and includes the reassignment baseline; greedy
always evaluates one proposal. `--study PATH` selects another reference attitude
study and resolves its mission manifest relative to that file. Each asset must
have the standard battery resource named `battery` for the diagnostics. The task
sets strategy/trial controls for each compared strategy and preserves the study's
optional protected activity declarations for all orbital runs.
The small quality cases have their own fixed configurations and do not change
when a custom orbital study is supplied.

Outputs are `README.md`, `summary.json`, per-strategy summary checkpoints, and complete compressed reports named
`report-greedy.json.gz`, `report-bounded_reassignment.json.gz`, and
`report-bounded_replacement.json.gz`. Compilation,
quality cases, diagnostic extraction, and artifact writing are excluded from the
reported orbital runtime. Each run regenerates opportunities independently;
within a search, opportunities are generated once and reused across trials.
There is no discarded warm-up or timing acceptance threshold.

## Orbital workload

`studies/repeated_service.json` declares three synthetic spacecraft in nearby
600 km sun-synchronous orbits. A ten-minute horizon contains twelve twenty-second
illumination requests, split into three overlapping waves at different latitudes.
Static resource budgets and costs are empty. Repeated service is constrained by
physical visibility, pointing/acquisition, transitions, path checks, and battery
reserve rather than a one-observation token.

`studies/repeated_service_planning.json` declares the following assumptions:

- J2 integration anchors at 1 s and output samples at 2 s.
- Opportunity checks at most 5 s apart, 0.01 s root timing tolerance, and 0.5 s
  inward entry/exit margins. Finite discovery can leave unknown spans.
- Tracking profiles at 2 s; candidate starts at 20 s spacing, at most 8 per
  opportunity; the same declared angular rate/acceleration and 2 s settling
  assumptions as the earlier reference spacecraft.
- Path checks at 5 s and 1 s, including reflected-beam and angular constraints.
- Complete battery replay at 5 s and 1 s, initially 24 Wh, capacity 30 Wh,
  reserve 8 Wh, with 2,000 W service load, declared maneuver/standby loads and
  charging/discharging efficiencies. Path/resource budgets are 100,000 per trial.
- Six synthetic body-face panels, each 0.4 m² and efficiency 0.3, with finite-Sun
  shadow contacts and attitude-dependent incidence. This invented panel layout
  provides recovery opportunities across orientations; it is not a spacecraft
  design or a Reflect Orbital hardware estimate.
- Explicit initial/terminal orientations and full idle/terminal coverage.

This is one clustered service pass, not global coverage, a multi-orbit campaign,
or operational validation. The settings differ from the original benchmark and
should not be used to infer a scaling law by comparing their runtimes.

The summary reports fulfilled value, activity counts per asset, minimum battery
reserve, full pipeline timing, model/trial evaluation counts, maneuver margins,
and unfulfilled request reasons. `placement_rejection_reasons` counts the tested
start failures in the **selected proposal**. It excludes other proposals' rejected
physical traces; search counters separately include all evaluated proposals.

`inter_service_energy` reports signed stored-energy change from the end of one
activity to the start of the next, including intervening maneuver/hold costs.
Every tested resource cadence has its own measurement and the summary retains
the range. A positive value is net recovery; a negative value is net depletion,
not missing data. Missing boundary states or uncovered resource intervals produce
an explicit unknown rather than a numeric claim. A resource report without
model rows (for example, unknown initial attitude) preserves its reason and null
battery/inter-service diagnostics. A study without event-based opportunity search
reports a null opportunity evaluation count rather than inventing a comparable count. These observations describe
modeled energy changes, not a convergence bound or flight battery prediction.

## Independently checkable fixed-time cases

`RepeatedServiceQualityCases` supplies four small synthetic cases through the
same production attitude, path, terminal and battery components. Each activity's
allowed interval exactly equals its ten-second duration, so start times are fixed.
There are one or two assets, no static tokens, fixed pointing about a common axis,
10 deg/s rate, 5 deg/s² acceleration, and 1 s settling. Initial and terminal
angular velocity are zero. The synthetic path guard declares the path clear.

The reference calculation enumerates every skip/allowed-asset assignment. It
checks overlap and rest-to-rest slew time using independent scalar arithmetic:
`2*sqrt(angle/acceleration)` for a triangular maneuver, otherwise
`angle/rate + rate/acceleration`, then adds settling. A 90° transition therefore
requires 12 s, exceeding a 10 s inter-service gap. It includes initial acquisition
and terminal return at the 100 s horizon.

The ideal battery starts at 4 Wh, has capacity 5.5 Wh and reserve 2 Wh. Constant
360 W generation and zero non-service loads give 0.1 Wh/s recovery; a 1,080 W
service load gives a 0.2 Wh/s deficit. Both efficiencies are exactly one, and all
motion-phase extra loads are zero. The independent calculation integrates these
piecewise constant rates with capacity clipping. Its validation rejects an
initial reserve/capacity violation before any recovery. Angles are restricted to
0–90° about the same axis, so scalar differences are shortest rotations. The
oracle is bounded to six requests and three assets.

| Case | Independently best value | What it exercises |
| --- | --- | --- |
| repeated_assignment | 27 | Put the flexible request on B, then serve two requests on A; all three requests fit. |
| maneuver_gap | 15 | Two outer requests beat the central request, whose 90° transitions do not fit the adjacent gaps. |
| battery_limited | 18 | Three closely spaced services would end at 1.5 Wh, below the 2 Wh reserve; the best pair is worth 18. |
| battery_recovery | 25 | Moving the last slot later allows enough recovery to serve all three requests. |

The oracle returns its optimal witness, assignment count, feasible count and
rejection reasons. Tests replay every optimal witness through production
planning and check the declared physical evidence. The oracle does not call the
production feasibility evaluator, numerical motion planner or battery integrator.
Its claim is exactness for this finite fixed-time ideal model, not independent
spacecraft validation or an optimality bound for the orbital workload.

These cases deliberately retain a known search limitation: greedy obtains 18 in
the repeated assignment case and bounded reassignment obtains 27. Both obtain 10
in the maneuver-gap case even though 15 is possible. The current reassignment
strategy preserves already-served requests and cannot replace the central request
with the two outer requests. The battery cases yield 18 and 25 under both planners.

## Initial observation

One run per strategy on Apple M1 / Elixir 1.20.4 / OTP 29, eight online schedulers,
MIX_ENV=test, without simultaneous heavy test work. These are timing observations,
not speed requirements. The complete compact measurements and configurations are
in [repeated_service_observation.json](repeated_service_observation.json); local
raw evidence is in `tmp/repeated_service_v1/`.

| Strategy | Fulfilled | Value | Activities per asset | Schedule trials | Total |
| --- | --- | --- | --- | --- | --- |
| Greedy | 5 / 12 | 130 | 1 / 2 / 2 | 1 | 18.53 s |
| Bounded reassignment | 5 / 12 | 130 | 1 / 2 / 2 | 4 | 70.13 s |

Both final plans had supported configured physical checks. The activities,
requests, opportunities, selection decisions and complete selected
attitude/path/horizon/resource evidence were identical between strategies.
Reassignment hit its four-trial limit with no accepted improvement. This does not
establish optimality: the orbital workload has no independent global oracle.
The unchanged value is a measured limitation of this bounded neighborhood on this
scenario, not evidence that additional search is always unhelpful.

The lowest reserve margin over all assets and tested cadences was 1.1733 Wh.
Between their first and second services, demo-2 recovered 11.4278 Wh net and
demo-3 recovered 8.4937 Wh net. Greedy's selected proposal recorded 45 start
rejections for resource feasibility, 15 for path constraints, and six for
incoming/outgoing transition feasibility. Thus the workload exercises sequence
and energy pressure even when the two strategies return the same plan.

Opportunity generation used 57,014 source/function evaluations per strategy.
Greedy used 4,591 attitude and 38,945 resource model evaluations; reassignment's
four-proposal totals were 19,396 and 158,702. Subsystem budgets reset per trial,
so an aggregate count above 100,000 does not mean a per-trial budget was exceeded.
The initial 10 s / 16-start trial exhausted a path budget during an alternative.
The recorded study uses a declared 20 s / 8-start grid covering the full candidate
interval, keeping the physical-check cadences and the per-trial budgets fixed.
This coarser placement search can miss feasible timing choices; its rejections
remain relative to the tested starts.

Validation: 158 focused mission-planning/CLI tests passed; the separate orbital
workload regression passed in 18.9 s; frozen mission numerical baseline passed;
independent read-only review found no remaining blocker. The full fast suite with
`mix test.fast --max-cases 8` passed **5,292 tests**, with 1,148 excluded (202.3 s).
The orbital workload remains an opt-in integration test.
