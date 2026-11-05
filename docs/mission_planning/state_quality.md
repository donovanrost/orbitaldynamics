# Offline state quality policy

Optional `state_quality_policy` in a planning study gates state updates before
replanning. It distinguishes observed estimates, synthetic predictions and
synthetic execution, and checks declared freshness, validity and error bounds.
Initial baseline values remain declared model inputs; this policy screens updates.
The implementation does not ingest telemetry, estimate state, authenticate a
source or propagate observations to the common epoch.

An update still supplies an explicit common-epoch attitude, rate, battery levels,
wheel momenta and static balances. With the policy configured, every asset also
requires `quality` metadata:

```json
"quality": {
  "kind": "observed",
  "source_id": "offline_estimator_batch",
  "state_epoch_s": 820497660,
  "measurement_epoch_s": 820497658,
  "valid_until_s": 820497665,
  "bounds": {
    "attitude_error_deg": 0.01,
    "rate_error_deg_s": 0.001,
    "battery_error_wh": {"battery": 0.05},
    "wheel_error_nms": {"wheels": [0.005, 0.005, 0.005]}
  }
}
```

These are illustrative values, not flight acceptance thresholds. `state_epoch_s`
must equal the update epoch: the values must already be estimates at that common
epoch, even when they were derived from earlier measurements. Observed measurement
epochs cannot be in the future or older than the explicitly allowed age. Estimate
validity must extend through the epoch plus the configured minimum validity.

The [example policy](../../studies/state_quality_planning.json) explicitly declares
allowed kinds, maximum measurement age, minimum validity and every asset's
accepted upper bounds. It must cover every configured battery and wheel ID.
Missing, negative or excessive bounds, missing provenance, stale measurements and
expired estimates produce `state_quality_rejected`; no child is adopted. Raw
quality metadata requires a policy and cannot bypass screening.

Prediction stamps `synthetic_prediction`; execution replay stamps
`synthetic_execution`. Both have a null measurement epoch and validity at their
exact sample epoch. An observed-only policy rejects them. Relabeling a prediction
as observed without providing a valid measurement epoch is rejected. Synthetic
zero bounds mean no additional estimation error is declared in that simulation;
they do not assert perfect physical accuracy. Source IDs and the entire raw packet
are retained in content-bound history, without an authentication claim.

Accepted bounds are checked against configured limits. Planning still evaluates
the supplied nominal state; bounds are not propagated through the dynamics and
do not establish robust or probabilistic feasibility. Position/velocity estimation
is outside the current attitude/resource update contract. A study without this
policy retains its explicitly declared-state workflow and makes no measurement
freshness claim.

Quality metadata and policy survive same-horizon revisions. Each subsequent
advance requires a new common-epoch packet. Saved-source validation and the
independent checker both verify the declared policy. The independent checker has
its own schema, freshness and bounds arithmetic and rejects rehashed stale state.

Run the synthetic example with fresh directories:

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/state_quality_operations.json --output-dir tmp/state_quality
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/state_quality --output-dir tmp/state_quality_check
```

Focused tests include accepted observations, missing/resource-incomplete metadata,
stale/future/expired/wrong-epoch observations, excessive errors, observed-only
rejection, provenance retention, independent mutation rejection and synthetic
execution continuity.

```sh
mix test.fast test/orbital_dynamics/mission_analysis/plan_revision/state_quality_test.exs
```

Recorded results: [state_quality_observation.json](state_quality_observation.json).
