# Extending the rolling horizon

An advance can carry `horizon_extension` with an explicit provider, new planning
end, trajectory coverage end and `add_requests` (the same request/mode schema as
ordinary revisions). Execution must first advance strictly inside the parent's
covered horizon. Extension never infers execution through an uncovered gap.
Once extended, subsequent cycles can advance beyond the original plan end.

The reference adapter supports `reference_j2`: it repropagates the original
Earth/J2 orbit recipe from its unchanged global epoch. It does not restart an
orbit at a new planning boundary, infer a maneuver or change spacecraft elements.
The generic core still accepts caller-owned trajectories and environments; this
reference provider is one explicit adapter, not a restriction on mission types.

Opt in before saving the baseline:

```json
"rolling_horizon": {
  "provider": "reference_j2",
  "sample_step_s": 10,
  "max_samples_per_asset": 64
}
```

The report stores position/velocity and Sun/rotation checkpoints across the whole
provider interval, with frame, time scale, orbit recipe digest and content-bound
environment identity. Coverage ends must align with this fixed global checkpoint
grid, with at most 512 samples per asset. The planning end must fit inside actual
trajectory/environment coverage with twice the attitude derivative step as
lookahead. The checked-in environment has finite coverage; requests beyond it
are rejected rather than extrapolated.

An extension must retain the provider, recipe, resolution, frame, scale,
environment identity and all saved overlap checkpoints. Position and velocity
component tolerances are 1e-8 km and 1e-11 km/s; environment checkpoints match
exactly. Unknown providers, missing parent evidence, changed overlap, insufficient
coverage and unaligned/unbounded grids produce `horizon_extension_rejected`,
without adopting a child. This compares finite saved predictions. It does not
establish orbit accuracy, continuous agreement or flight navigation quality.

State, remaining budgets, ongoing reservations, closed identities and parent
lineage remain governed by the advance workflow. Added requests cannot reuse an
active or closed identity. Unselected demand remains open until its actual latest
start (`request.ends_at_s - duration_s`); the current planning end no longer
permanently expires demand that may become plannable after an extension.

The independent artifact checker reconstructs allowed extensions/additions and
compares saved parent/child checkpoints without propagating an orbit. A coherent
single-snapshot checkpoint mutation can pass standalone structure checking but
fails overlap checking. Neither checker treats a content hash as authentication.
Coverage propagation/checkpoint work happens during input preparation and is
bounded by its own sampling limit, outside scheduling callback work counters.

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/horizon_extension_operations.json --output-dir tmp/extended
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/extended --output-dir tmp/extended_check
```

The synthetic battery-only example checkpoints at 60 seconds, extends the
100-second planning horizon to 200 seconds at 90 seconds (provider coverage
120 to 220 seconds), adds demand, and executes through 195 seconds. Wheel
capacity was removed explicitly to isolate coverage/lifecycle behavior; this
example does not imply unlimited momentum capacity in a longer mission.
