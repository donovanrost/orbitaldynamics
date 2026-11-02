# Full planning horizon

The optional attitude `horizon` extends the selected path through a declared end
epoch and assesses every asset, including assets with no scheduled activity.
Existing studies without a horizon retain their initial-through-last-activity
scope. The frozen numerical baseline remains unchanged.

Run the reference example:

```sh
MIX_ENV=test mix orbital_dynamics.mission.attitude \
  --study studies/illumination_horizon.json --output-dir tmp/horizon
```

This synthetic 250-second example schedules the north request and reports a
supported horizon at the tested epochs. The primary request still fails the
incoming limb guard. The terminal strategy returns to the declared identity
attitude in the **reflecting** mode; the checked rules decide whether that path
is supported. Neither identity pointing nor any label such as park, stow or off
is inherently safe.

## Generic API

Pass `horizon:` to `Attitude.Policy.new!/2` alongside the existing controls:

```elixir
%{
  start: Epoch.new!(start_s, :tai),
  stop: Epoch.new!(end_s, :tai),
  terminals: %{
    "asset-1" => %{
      frame: inertial_frame,
      quaternion: {1, 0, 0, 0},
      mode: "declared-mode"
    }
  }
}
```

The generic interface accepts any compatible inertial frame and explicit time
scale supported by the analysis. The reference JSON adapter accepts UTC and
Earth/J2000 and uses a top-level `horizon` with `starts_at_s`, `ends_at_s`,
`time_scale`, and `terminals`. Each terminal specifies `strategy: fixed_inertial`,
`frame`, `quaternion_wxyz`, and `mode`. See the runnable study for exact fields.

A terminal is a fixed inertial orientation with zero angular velocity. Its mode
must resolve in the asset's existing path-mode registry. That same descriptor
is passed to every rule throughout terminal braking, slew, settling and hold.
There is no inferred shutter or payload switch mechanism. Initial state must
be declared exactly at the horizon start, in the asset's frame and time scale;
an earlier attitude is not silently propagated. Trajectory coverage must span
the complete horizon. A missing terminal (or `:unknown`, JSON `null`) stays
unknown, as does an unknown or unregistered terminal mode.

During candidate selection, activity times are clipped to the horizon. A final
activity must leave sufficient time for braking its actual sampled tracking
rate, slewing to the terminal attitude and settling. Spare time is spent at the
terminal attitude after that motion. This tail is checked before accepting the
candidate. Insertion before an existing activity still checks the successor
transition; the final chronological graph and terminal path are checked again.
Idle assets perform the same terminal acquisition and hold from the initial
state. An entirely idle mission may use an empty request list when an explicit
attitude horizon is supplied.

## Evidence and limits

`attitude_planning.horizon_coverage` contains overall and per-asset
`supported`, `violated`, or `unknown` status, exact terminal motion phases,
terminal path evidence at all configured cadences, and `uncovered_intervals`.
The existing activity and transition arrays contain the preceding path evidence.
A full horizon requires all assets to pass. A known failure takes precedence
over unknown evidence. A missing declaration or coverage cannot produce a
supported result, and an empty activity list does not imply a supported idle
path. Terminal violations veto candidate activities; if the resulting idle plan
also violates a rule, the report retains that violation rather than failing to
produce an explanation. Provider failures and exhausted evaluation budgets
remain analysis errors.

An uncovered interval conservatively identifies a whole segment without full
support; it does not assert that every instant in it violates a constraint.
Per-cadence evidence gives the actual evaluated prefix and first observed
failure. Terminal evidence uses the same bounded sample counts, rule-evaluation
budget, captured sessions, phase-boundary samples and normalized pose/mode cache
as other paths.

“Supported” is relative to the declared rules and tested epochs. It is not
continuous certification or spacecraft validation. Mode switches remain
instantaneous assumptions. The construction assumes unlimited jerk and omits
actuator torque, momentum, flexible dynamics, thermal/power evolution and
disturbances. Only the fixed inertial terminal strategy is implemented;
Sun tracking, nadir pointing and other moving terminal profiles require a future
explicit strategy and derivative model.

## Verification of this extension

The fast suite passed all 5,173 tests (1,137 integration/exhaustive tests excluded).
The focused mission-analysis and mission CLI run, including its integration
checks, passed all 95 tests. The frozen independent numerical baseline command
still passes. New regressions cover terminal time reservation, braking from
tracking, the actual terminal hold, late idle-path failures, absent declarations,
coverage limits, idle fleet members, horizon clipping and predecessor insertion.
Independent review found no remaining blocker. Formatting and diff whitespace
checks pass. Full integration/exhaustive suites were not rerun.

## Dynamic resources

Optional [resource feasibility](resource_feasibility.md) replays the complete
horizon for candidate and final plans. Path and resource evidence remain separate;
combined planning support requires both. The first resource model tracks ideal
battery energy under explicitly declared power and charging assumptions.
