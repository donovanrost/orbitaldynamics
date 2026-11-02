# Time-dependent resource feasibility

Dynamic resources are optional and require an explicit full attitude horizon.
The scheduler replays a candidate's entire asset timeline from its declared
initial resource state, including earlier and later activities, transition
phases, terminal acquisition and terminal hold. It accepts that candidate only
when every declared resource model supports every tested integration cadence.
The final report assesses all assets, including idle assets.

The first built-in model is ideal battery energy. Configuration is synthetic;
no Reflect Orbital hardware specifications or validated power model are implied.

## Run the reference example

```sh
MIX_ENV=test mix orbital_dynamics.mission.attitude \
  --study studies/illumination_energy.json --output-dir tmp/energy
```

The 250-second example starts with 20 Wh, a 30 Wh usable capacity and an 8 Wh
reserve. Declared loads are 500 W in the activity mode, 100 W in the transition
mode and 20 W in terminal standby. Named moving phases add 200 W. Charge and
discharge efficiencies are both 0.9. Generation is an explicit 60/0/60 W time
profile with boundaries at 120 and 180 seconds. This profile is **not** calculated
from spacecraft sunlight, panel pointing or eclipses. Standby keeps the declared
reflecting optical behavior; the existing path checks still apply to that mode.

The north request is selected at +61 through +81 seconds. Both 10-second and
2-second resource cadences give approximately 9.21825 Wh minimum stored energy,
1.21825 Wh minimum reserve headroom and 9.91825 Wh final energy. The primary
request still fails its incoming path guard. These figures are reproducible
results of declared inputs, not spacecraft performance estimates.

`report.json` contains the resource trajectories. The Markdown report summarizes
minimum/final battery energy, reserve headroom and the first issue interval for
each cadence. The CLI integration tests also lower initial energy and constrain
the north request to that same 20-second slot: it is rejected for resource
feasibility, while the resulting idle plan is separately evaluated.

## Battery model

All loads and generation are electrical bus power in watts. Time is in seconds;
stored energy, usable capacity and reserve are battery-side watt-hours. At each
interval, with mode load plus additional phase load subtracted from generation:

```
net_w = generation_w - mode_load_w - phase_load_w
battery_w = net_w * charge_efficiency       when net_w >= 0
battery_w = net_w / discharge_efficiency    when net_w < 0
raw_wh = previous_wh + battery_w * duration_s / 3600
next_wh = clamp(raw_wh, 0, capacity_wh)
```

Surplus can supply the load directly. Charge/discharge efficiency applies to the
remaining flow into or out of storage. Energy that cannot be stored is curtailed;
demand that cannot be supplied is unserved. `curtailed_wh` and `unserved_wh` are
**bus-side** counters, accounting for the respective efficiencies. Storage stays
within zero and capacity. Both reserve breaches and unserved energy veto support,
including the case where a declared zero reserve would otherwise hide unmet
load at an empty battery. An initial state below reserve fails at horizon start.

The shared path-mode registry supplies `parameters.power_load_w`; the resource
model and path checks see the same descriptor. Battery configuration supplies:

- `initial_wh`, `capacity_wh`, `reserve_wh`;
- `charge_efficiency`, `discharge_efficiency` in `(0, 1]`;
- `phase_load_w`, with explicit values for the phases that occur;
- `generation`, either constant `power_w` or ordered, nonoverlapping
  `piecewise_constant` intervals with `starts_at_s`, `ends_at_s`, `power_w`.

Phase names are `activity`, `brake`, `hold`, `slew_accelerate`, `slew_cruise`,
`slew_decelerate`, `settle`, `ramp_to_tracking`. Phase demand is additional to the
mode's base load, including when a rest hold occurs inside a transition.
Generation intervals use the horizon's absolute epoch seconds and time scale.
Their boundaries are included exactly in every integration grid. Gaps in their
coverage, missing mode/phase loads and explicit JSON `null` power inputs remain
unknown. Required configuration fields must be present; explicit `null` battery
parameters also produce unknown evidence, without numeric defaults.

Within each declared mode/phase/generation interval the battery's frozen-power
balance is analytic. A capacity crossing clips surplus before later discharge;
curtailed energy cannot be borrowed by future activities. Reserve-crossing
offsets in per-interval metrics are calculated under that frozen-power
assumption. The report's first issue is an interval, not a certified physical
event time. Numerical rounding near an exact threshold can affect classification;
use physical headroom and the reported margins rather than relying on equality.

This is not a voltage/current, cell-temperature, battery-aging, maximum
charge/discharge-power or regulator model. No solar array or shadow model is
inferred. More detailed models must supply those relationships explicitly.

## Generic extension interface

`Attitude.Policy.new!/2` accepts `resources: %Resource.Policy{}`. The resource
policy maps asset IDs to a bounded list of definitions:

```elixir
%{
  id: "battery",
  module: OrbitalDynamics.MissionAnalysis.Resource.Battery,
  configuration: explicit_json_configuration,
  exclusive_cost_keys: ["energy_wh"]
}
```

It also requires `sample_steps_s`, `max_intervals_per_asset` and
`max_evaluations`. The reference JSON adapter supports only the named `battery`
model, without dynamically loading module names. Programmatic callers may use
any trusted module implementing `Resource.Model`:

1. `prepare(asset, context, configuration)` captures one opaque session and
   JSON-safe assumptions for the whole analysis.
2. `initial(session)` returns the declared JSON-safe resource-state map.
3. `boundaries(session)` returns absolute epochs of required model-input changes.
4. `step(previous_state, input, duration_s, session)` returns the next state and
   `Path.Result` checks with `supported`, `violated` or `unknown` status and optional
   signed, unit-bearing margins.

Step input contains the interval start/end, midpoint epoch, sampled spacecraft
state, full body-to-inertial pointing, shared mode descriptor, scope and phase.
Inputs are frozen at that midpoint over the interval; the model owns its
integration method. A zero-duration step checks the initial state. There is no
interpolation of resource state, implicit frame/time conversion, or universal
interpretation of state-variable units. Models should record those units in
assumptions. Top-level numeric state variables receive extrema summaries;
complete state maps are retained at each propagated endpoint. A regression uses
an opaque-session fuel model to exercise this interface independently of battery
field names and physics.

Models evolve independently. Put coupled quantities in one state/model when
their evolution depends on each other. This slice does not exchange quantities
between different resource models or spacecraft.

`exclusive_cost_keys` prohibits positive static request costs for the same
managed quantities on that asset. The reference battery adapter reserves
`energy_wh`; its reference mission uses separate static observation tokens.
Existing studies without dynamic resources preserve their static budgets.
Dynamic evolution never silently subtracts a request's lump-sum cost as well as
its mode power.

## Evidence and scheduling limits

`attitude_planning.resource_feasibility` reports overall and per-asset/model
status. Each cadence includes `samples`, `state_extrema`, `minimum_margins`,
`first_issue`, `evaluated_through_s`, `uncovered_intervals` and `final_state`.
Initial state, requested/propagated interval counts and the largest requested
interval are explicit; propagated sample epochs are strictly increasing.
Captured assumptions and model callback counts are explicit. Candidate decisions
retain compact evidence; full resource histories are emitted for the final plan.

A known violation on any cadence vetoes the candidate. Unknown evidence is not a
pass. Cadence-dependent classifications remain visible; the finest grid is not
assumed to be truth. Each cadence and each candidate starts from the same
captured initial state. No evolved state is reused from another candidate.
Earlier insertion replays already selected successors, so it cannot consume
energy reserved by a later activity without being checked. There is no global
optimality claim, and rejecting an activity can change both modes and generation
exposure for the remaining plan.

Unknown input stops propagation and leaves an explicit unsupported suffix; the
runner does not invent a final state. Known violations still take precedence in
the summary if an unknown check occurs as well. Interval-count or epoch-resolution
limits are unknown. Callback budget exhaustion and provider failures are analysis
errors; they never return a partially supported plan. The callback budget covers
initial checks, all cadences, candidate replays and final fleet replays. Models
are prepared once; callbacks/state sources must remain consistent under that
captured session. A check ID changing margin units during a replay is invalid.

The report keeps path status separate from resource status. Combined
`planning_status` requires both the full path horizon and resource assessment to
pass, with a known violation taking precedence over unknown evidence. An idle
asset that lacks resource configuration keeps the fleet result unknown. A
rejected request can coexist with a supported final idle plan; request fulfillment
and physical feasibility answer different questions.

The full-horizon requirement and explicit mode registry are the current timeline
adapter for these models. There is no command execution, telemetry assimilation,
rolling repair, continuous certification or actual-spacecraft validation.

## Verification of this extension

All 5,190 fast-suite tests passed (1,140 integration/exhaustive checks excluded).
The focused mission-analysis and mission CLI run, including integration checks,
passed all 115 tests. The 17 new resource unit/scheduler checks cover analytic
energy conversion and efficiencies, storage saturation, bus-side unmet demand,
full terminal maneuver cost, successor replay, idle/fleet failures, explicit
unknowns, independent generic models, cadence disagreement, unit consistency and
budget/provider errors. Trace refinements were rechecked with all 17 resource
checks and all three resource CLI checks. The frozen independent numerical
baseline command still passes, formatting and whitespace checks pass, and
independent review found no remaining blocker. Full integration/exhaustive
suites were not rerun. The battery model has analytic regression checks; the
existing Orekit baseline does not independently validate power inputs or battery
hardware.
