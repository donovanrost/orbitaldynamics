# Time bounded activity availability

The optional `scheduling.availability` calendar excludes whole activities from
declared outage intervals while retaining the spacecraft, its trajectory and
full-horizon idle/resource evolution. Outages can cover all activities, selected
activity types or selected activity modes. A payload outage can therefore leave
unloading available, and an unloading-mode outage can leave services available.
These are activity eligibility rules, not bus-failure or safe-mode physics.

```json
"availability": {
  "time_scale": "utc",
  "outages": [{
    "id": "unloading_unavailable",
    "asset_id": "demo-3",
    "starts_at_s": 820497620,
    "ends_at_s": 820497630,
    "scope": {"kind": "modes", "ids": ["desaturate"]}
  }]
}
```

Times use the mission's explicit time scale and J2000 origin. Intervals are
half open: an activity may end exactly at outage start or begin exactly at
restoration. Matching overlapping outages form a union. Whole activity duration
must fit an available piece; an activity cannot span an outage. A calendar may
contain at most 128 uniquely identified finite positive intervals. Unknown assets,
unknown mode references, invalid scopes and mismatched time scales are rejected.
Activity-type filters may refer to types not currently requested.

Supported scopes are `{"kind":"all_activities"}`,
`{"kind":"activity_types","ids":["service"]}` and
`{"kind":"modes","ids":["desaturate"]}`. Mode scopes refer to selected activity
modes, not idle/transition modes. Rules do not infer how a hardware failure changes
power, attitude or disturbance; those require an explicit state/model update.

The planner subtracts the calendar from physically supported opportunities before
placement. Changed opportunities carry their source identity and excluded outage
IDs. Their sample count describes the original physical opportunity, explicitly
labeled in availability evidence. The original opportunities remain in the pair
analysis for audit. Full activity, transition, terminal and resource checks still
apply to the clipped choices; this does not improve the physical window's sampled
or conservative numerical guarantees.

Revisions and advances inherit the calendar. A scheduling update can replace it,
including `outages: []` for restoration. A new outage intersecting protected work
produces `commitment_conflict` and no adopted child. Execution replay retains the
eligibility calendar. The independent checker implements its own outage/schema
and overlap checks and rejects coherent rehashed activity-calendar conflicts.

Run the example with fresh directories:

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/availability_operations.json --output-dir tmp/availability
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/availability --output-dir tmp/availability_check
```

The synthetic four-step scenario advances to 10 s, declares an unloading-mode
outage at 20–30 s, moves the tentative unload to 30–50 s, then executes unloading
and service in later cycles. Unloading is not repeated; wheel state, energy,
remaining budgets and closed history remain consistent.

Focused development check:

```sh
mix test.fast test/orbital_dynamics/mission_analysis/scheduling/availability_test.exs
```

Recorded results: [interval_availability_observation.json](interval_availability_observation.json).
