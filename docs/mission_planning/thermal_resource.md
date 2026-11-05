# Declared single-node thermal resource

The optional `thermal` resource carries `temperature_k` through the complete
planning timeline, including idle time, activities, transitions and terminal
holds. It screens cold/hot limits and can make an explicit cooldown request useful
in the existing bounded maintenance search. No mission-specific threshold is
embedded in the model.

The declared equation is

```
C dT/dt = Q - K (T - Tsink)
C: heat capacity (J/K)
Q: mode heat + motion-phase heat (W)
K: base conductance + mode rejection (W/K)
T, Tsink: absolute temperature (K)
```

Inputs are constant on each resource interval. For K > 0 the exact solution is
`Teq + (T0 - Teq) exp(-K dt/C)`, with `Teq = Tsink + Q/K`; for K = 0 it is
`T0 + Q dt/C`. A short-interval series avoids subtractive cancellation. Temperature
is monotone on such an interval, so checking both endpoints bounds its entire
modeled temperature range. Missing state, heat or rejection parameters remain
unknown. An out-of-limit initial temperature is still a violation even if the
node later cools into range.

This is an effective linear planning approximation, not an orbital thermal
analysis. NASA's [thermal-control overview](https://www.nasa.gov/smallsat-institute/sst-soa/thermal-control/)
describes the fuller balance of absorbed environmental heat, internal generation,
storage and radiative loss. This model deliberately uses declared heat and a
fixed effective sink/rejection coefficient instead of calculating those terms.
It does not model view factors, T^4 radiation, multiple coupled nodes, internal
gradients, optical distortion, eclipse-dependent heating, heaters or degradation.
The linear loss is not vacuum convection. Electrical loads do not automatically
become heat in this node; their relationship must be supplied explicitly.

Configuration fields are `initial_temperature_k`, `heat_capacity_j_k`,
`sink_temperature_k`, `conductance_w_k`, `minimum_temperature_k`,
`maximum_temperature_k` and `phase_heat_w`. Mode parameters independently declare
`thermal_heat_w` and `thermal_rejection_w_k`. Extra rejection can represent a
declared cooldown configuration; no mechanism or hardware performance is inferred.
The usual static/dynamic resource double-counting checks reserve `temperature_k`.

State packets must supply `thermal_temperature_k` for every configured node.
Prediction and execution use exact supported resource samples, then reset the
child's declared initial temperature at the common epoch. With state-quality
policy enabled, every node also needs `thermal_error_k` in policy and packet
bounds. This screens point-state input quality, not worst-case temperature under
uncertain parameters.

The independent checker implements its own analytic heat balance, sample history,
extrema, margins and state-handoff checks. Its current supported envelope requires
complete, equal phase heat across all motion kinds and matching idle/terminal
thermal inputs (or a zero-duration activity checkpoint). Moving attitudes are allowed when
those declared thermal inputs are independent of attitude; varying phase heat
remains explicitly unsupported. It does not import the production resource model
or certify the declared physical coefficients.

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/thermal_cooldown_operations.json --output-dir tmp/thermal
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/thermal --output-dir tmp/thermal_check
```

The synthetic example uses C = 100 J/K, initial 304 K, sink 290 K, base rejection
0.1 W/K, a 310 K hot limit, 100 W service heat and 5 W/K additional cooldown
rejection. These intentionally small illustrative values are not estimates of
Reflect Orbital hardware. Without cooldown the service is withheld; a declared
20-second cooldown makes it possible. Four cycles continue and complete cooldown
and service without resetting temperature or charging static costs twice.
