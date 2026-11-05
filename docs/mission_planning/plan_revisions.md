# Same-horizon plan revisions

Save a supported baseline, select exact activity commitments, and replan after
adding requests or declaring spacecraft service unavailable. This is a review
workflow for analysis; it does not approve work or produce executable commands.

## Run the reference examples

```sh
MIX_ENV=test mix orbital_dynamics.mission.revision baseline \
  --study studies/repeated_service_planning.json --output-dir tmp/revision_baseline

MIX_ENV=test mix orbital_dynamics.mission.revision revise \
  --baseline tmp/revision_baseline/baseline_snapshot.json \
  --changes studies/revision_urgent.json --output-dir tmp/revision_urgent

MIX_ENV=test mix orbital_dynamics.mission.revision revise \
  --baseline tmp/revision_baseline/baseline_snapshot.json \
  --changes studies/revision_outage.json --output-dir tmp/revision_outage

MIX_ENV=test mix orbital_dynamics.mission.revision revise \
  --baseline tmp/revision_baseline/baseline_snapshot.json \
  --changes studies/revision_commitment_conflict.json --output-dir tmp/revision_conflict
```

Use fresh output filenames in each directory. Existing outputs and output symlinks
are rejected. The baseline is never rewritten. Revisions use the inputs embedded
in the snapshot, so the original manifest and study files are no longer needed.
A successful child snapshot can itself become the next baseline.

## Changes and commitments

Each change declares `revision_id`, `protect_request_ids`, `add_requests`,
`unavailable_asset_ids`, and `scheduling` (`strategy` and `max_trials`). An optional
`expected_baseline_id` detects selection of the wrong baseline.

Protection selects scheduled baseline request IDs. Their spacecraft, start, and
end times must remain exactly equal. Commitments inherited from a parent remain
protected; this version has no commitment-release operation. Tentative work may
move or disappear according to the selected search policy.

Each added request contains a complete reference-mission `request` and an
`activity_modes` map naming an existing mode for every spacecraft. Existing
requests cannot be edited. The change cannot edit the horizon, initial attitudes,
resources, trajectories, physical models, or feasibility policies.

`unavailable_asset_ids` is the complete revised set of spacecraft barred from
service throughout the horizon. An empty set restores previously unavailable
service. Attitude trajectories, idle modes, terminal acquisition, generation and
resource accounting still apply to these spacecraft. This is not a spacecraft
power failure, an interval outage, or an advanced-time operational state update.

## Review artifacts

`revision.json` and `README.md` report one of:

- `ready_for_review`: supported configured evidence and intact commitments; a
  `revised_snapshot.json` is written, with its parent identity and full evidence.
- `commitment_conflict`: a protected placement cannot be retained. A protected
  spacecraft outage is detected before planning. No child snapshot is written.
- `unsupported_revision`: candidate evidence is unknown or violated; no child.
- `planning_failed`: the planner returned an error; no child. A general failure
  does not prove the planning problem infeasible.

Unsuccessful revisions exit nonzero after writing their review. Where a candidate
report exists it is retained as `failed_candidate.json.gz`. Malformed changes are
rejected before a review is produced.

The diff matches requests by identity and reports added, removed, moved, and
unchanged activities, exact protections, value changes, and unfulfilled reasons.
Removed and newly served requests are grouped without claiming causal replacement
pairs. Search remains bounded and heuristic: a ready plan can leave even a
high-value request unfulfilled. It does not certify optimality or impose a
separate penalty for disruption.

## Snapshot boundary

Snapshots contain the exact JSON inputs and full mission-analysis report, a
version, a parent ID, and SHA-256 content identity using sorted JSON object keys.
Array order is retained. Duplicate keys, altered content, unsupported versions,
and files larger than 64 MiB are rejected. Input bounds still apply separately.
This is content integrity, not authentication, approval, or an independent check
of the physical evidence. Snapshots do not pin the solver implementation or make
replanning reproducible across software changes.

The snapshot and diff primitives accept generic mission-analysis reports. The
current command and change schema deliberately use the configurable reference
adapter. [Advancing the planning boundary](rolling_state.md) is available through the
separate `advance` command with explicit state and execution declarations.
Telemetry ingestion, work in progress, partial outages, operator approval and
execution remain future work.

Recorded example outcomes are in [plan_revision_observation.json](plan_revision_observation.json).

Use [request scheduling evidence](scheduling_explanations.md) to inspect an
unfulfilled request from a saved snapshot without rerunning the planner.
