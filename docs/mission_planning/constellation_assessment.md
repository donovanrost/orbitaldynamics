# Integrated reference constellation assessment

Current validation follow-up: [moving resource validation](moving_resource_validation.md)
now covers saved moving-wheel histories and changing phase power. Earlier partial
results below remain historical; current regenerated examples pass the declared
resource-accounting scope. Orbit/pointing geometry and continuous feasibility
remain outside that scope.


The ten-slice queue ends with a reproducible portfolio of synthetic operations
cases. Run it with:

```sh
MIX_ENV=test mix orbital_dynamics.mission.assessment \
  --assessment studies/constellation_assessment.json \
  --output-dir tmp/constellation_assessment
```

Use a fresh output directory. The command saves every baseline, execution prefix,
revision and independent validation, plus a top-level `README.md` and
`assessment.json`. Configuration accepts at most eight cases and uses the existing
bounded operations-script format. Expectation checks preserve `partial` as
partial; `expectations_met` does not mean every physical model has independently
passed. Existing output/input files are protected from accidental overwrite.

## Cases and observed behavior

| Case | Mission and change | Completed service | Independent result |
| --- | --- | --- | --- |
| `reflect_outage_recovery` | Three illumination spacecraft; extend 300 to 600 seconds, declare a payload outage, restore it, checkpoint at 350 seconds | 6 services, value 150 | Partial: moving wheel dynamics unsupported |
| `reflect_earlier_checkpoint` | Same mission and recovery, checkpoint at 330 seconds | 6 services, value 150 | Partial: moving wheel dynamics unsupported |
| `fixed_repeated_service` | Two fixed-attitude spacecraft, ten steps, two service/cooldown cycles, extend 100 to 200 seconds | 4 services, value 40; 4 cooldowns totaling 80 spacecraft-seconds | Passed within stated checker scope |
| `fixed_hot_limit` | Same two-spacecraft mission; hot limit reduced from 310 to 304.2 K | 0 services selected; demand eventually expires | Passed within stated checker scope |
| `reflect_work_cap` | A 1,000-callback limit on the extension/replan | 3 early services accepted in the execution checkpoint; no replacement plan adopted | Partial: stopped operations and moving wheels |

The illumination model has three spacecraft in the same synthetic dusk orbit at
600 km altitude, separated by 2 degrees in initial argument of latitude. It uses
the existing spherical surface illumination model, configurable mirror parameters,
pointing/path checks, body/wheel limits, battery and thermal state. Targets and
request windows come from the earlier rolling-state example; duplicate target
locations represent competing requests, not coverage of a real customer region.

All three early services complete. A declared payload outage removes `late-1`
from the extended tentative plan while `late-2`/`late-3` remain available. A
same-horizon restoration recovers all three. With [checkpoint-faithful replay](checkpoint_replay.md), both subsequent
checkpoint choices preserve the saved motion and retain all six services. The
original observation lost one service at 350 seconds because replay inserted an
idle return; that result remains recorded in the historical observation JSON.
It identified a replay-policy artifact rather than a physical twenty-second
operational lead-time requirement. Bounded search and finite sampling remain
explicit limitations.

The fixed-attitude example demonstrates generic operation outside illumination.
Each spacecraft needs cooldown before each heating service, carries wheel/battery/
temperature state, and uses separate adjacent command contacts on a shared station.
Checkpoints occur inside cooldown and service, as well as beyond the original
planning horizon. The original four service identities and four cooldowns close
once; tails do not create duplicate credit or static charges. Tightening the hot
limit withholds service in the configured search. This is not a proof that every
possible sequence is physically infeasible.

The work-cap case stops exactly at 1,000 callbacks during the failed replan and
keeps its fully specified parent accepted plan. Execution state is now accepted independently through
[execution checkpoints](execution_checkpoints.md), so completed early work persists
even though no replacement plan is adopted. The chronology retains separate
accepted-execution and plan epochs and labels the older plan stale. Historical
observations predating this change retained the new state only in the chronology;
regenerated reports use the new acceptance semantics.
Failure review preserves structured callback counts and a budget-exhaustion
category rather than losing them in an error string.

## What the report measures

- Completion counts/value use original closed requests in the accepted ledger;
  separate simulated totals retain executed work when a replan stops. In these
  cases all zero-value requests are explicitly declared maintenance.
- Maintenance cost is original activity duration and declared static consumption;
  contact cost is allocated duration/count, not a monetary or RF-energy estimate.
  Contacts are allocated before service search, so the hot-limit case still
  reserves contact capacity even when no service is delivered.
- Resource margins are minimum forecasts over accepted plans, with their declared
  units. They are not measured hardware margins or uncertainty bounds.
- Every accepted plan retains scheduled IDs, unfulfilled demand and reasons,
  work accounting, trial limits and planning horizon. Callback totals include
  failed trials and captured failed-search work. They exclude input preparation,
  propagation, opportunity generation, independent checking and physical replay.
- Elapsed milliseconds are observations under local machine load. This portfolio
  is not a latency guarantee or a fleet-scale performance benchmark.

The independent fixed-attitude cases verify supported battery, wheel and thermal
accounting and lineage. The moving cases retain an explicit wheel-dynamics gap;
no `partial` result is converted into a complete verification pass. The checker
also does not independently validate trajectories, pointing, beam geometry,
visibility, observation truth or actual command delivery.

## Assumptions that need engineering input

These cases deliberately invent actuator capacities, inertia, disturbances,
thermal coefficients/limits, radio contacts, receipt facts and control policies.
For example, the moving case uses generous 1,000 Nms wheel capacities and 10 Nm
body/motor limits to exercise the integration; these are not spacecraft estimates.
The fixed thermal case uses the illustrative node in
[thermal_resource.md](thermal_resource.md). Both use finite source-bound Earth
environment coverage and the original J2-only reference trajectories.

Before company-specific usefulness can be assessed, the highest-value inputs are:

1. Real attitude modes, slew/settling envelopes, wheel/disturbance/unload models,
   payload constraints and validated state/trajectory sources.
2. Thermal/power operating limits and duty cycles, plus which resource margins
   mission operations must hold under uncertainty.
3. Command-contact capabilities, delivery/acknowledgment semantics, execution
   commitments, abort/recovery policy and service success criteria.

The reusable mechanisms can keep improving with synthetic configurations, but
these examples do not establish a calibrated model, validated mission design,
control-system feasibility or flight readiness.
