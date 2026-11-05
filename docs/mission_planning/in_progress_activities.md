# Replanning during an activity

A common-epoch update can now confirm an already running activity with
`in_progress_request_ids`. The activity keeps its original asset, request,
parameters, model clock and planned end. Its remaining interval becomes an exact
protected reservation; the executed prefix is not moved or executed again.
This is successful, non-abortive continuation of the declared profile. Abort,
partial-success credit and controller recovery are separate policy contracts.

An activity is running when `starts_at_s < as_of_s < ends_at_s`. An exact start
boundary is treated as not yet started, and an exact end as completed. Updates
must explicitly identify every running activity. Missing confirmation produces
`in_progress_state_incomplete`; completed and skipped declarations remain required
for ended work. A previously started activity cannot later be declared unexecuted.

## Original identity and resource accounting

The study's content-bound `continuations` records retain the original request,
full activity placement and source snapshot identity. The current request describes
only the remaining interval. Its model is prepared with the original request,
so changing the allocation interval cannot restart a model clock or alter a
request-duration-dependent pointing law. Original model/configuration context
must remain unchanged. Activity and request reports label their segment role,
original timing, utility and static costs.

Declared static costs are reserved once, when execution first crosses the start.
The remaining request has zero additional static cost. Battery, wheel and other
dynamic resource states come from the explicit boundary packet and evolve only
over the remaining interval. Completion is credited once, after the original end;
closed history restores the original full request and placement, rather than
archiving a shortened request as a second service.

The initial join permits zero-duration continuity only for the declared running
activity at its exact boundary. Orientation and angular-rate residuals must each
be at most 1e-8 in degrees/degrees per second, and rate limits still apply.
Ordinary acquisition and settling remain required for new work. A pose/rate
mismatch or a new outage blocking the reserved tail requires review; continuation
does not infer corrective control, waive constraints or silently abort the task.
Accepted observation-quality bounds alone do not establish this continuity.

## Execution replay and physical windows

Synthetic replay includes ended services and the executed portion of running
ones. A running prefix has zero completion credit. At a checkpoint inside an
activity, or exactly at its end, an explicit `activity_boundary` terminal carries
the profile's attitude/rate without forcing an early return to the idle terminal.
That terminal is usable only as a zero-duration matching endpoint; it is not a
free maneuver or a future hold at nonzero angular velocity. Replay retains prior
history and derives a new state packet, visibly marked synthetic when a quality
policy is enabled.

Segments inherit physical discovery windows and timing margins from the original
request, then intersect them with their exact allocation interval. Reapplying
acquisition margins to a short prefix could erase a valid existing reservation.
The full segment profile, endpoints, path, resources and future terminal remain
checked. Source-window evidence is preserved, and sample counts refer to that
physical source window. Synthetic checkpoints require an exact saved attitude
sample and supported resource sample; interpolation is not inferred. Explicit
observed packets can provide a common-epoch state, subject to continuity checks.

An independent checker reconstructs original identity, costs, reservations,
prefixes, remaining demand and completion history without producer continuation
helpers. A coherently rehashed original-cost change can pass a snapshot alone but
fails parent-derived chain checking. Its existing physical-accounting scope still
applies: moving wheel dynamics remain unsupported there.

## Numerical boundary correction

Testing continued services after a return exposed a floating-point terminal-hold
residual that could create a fictitious tiny slew on the next plan. A terminal
hold now canonicalizes an already reached orientation to its declared target
only within 1e-12 degrees, recording the correction. It does not snap genuine
tiny requested targets to identity. Mission-epoch queries select the right-hand
phase and clamp translated boundaries, avoiding cancellation at large J2000 UTC
epochs; one-sided phase evaluation remains available for motor/torque checks.
Roundoff diagnostic fields can therefore differ from older reports. The frozen
independent motion and wheel numerical comparisons remain separate checks.

## Run and test

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/in_progress_operations.json --output-dir tmp/in_progress
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/in_progress --output-dir tmp/in_progress_check
mix test.fast test/orbital_dynamics/mission_analysis/plan_revision/continuation_test.exs \
  test/orbital_dynamics/mission_analysis/activity_segment_test.exs
```

The synthetic example checkpoints unloading twice, completes it at its original
end, then checkpoints and completes service. Both static tokens are charged once,
and the closed ledger contains two original activities. Additional tests cover
nonzero-rate illumination tracking, a rotating acquisition prefix, an original
request-clock-dependent model, pose/availability conflicts, rejected skips,
semantic lineage corruption and tiny-target numerical preservation.

## Motion between activities

[Checkpoint-faithful replay](checkpoint_replay.md) now also preserves incoming,
inter-activity and terminal motion. A planning checkpoint no longer forces an
idle return. Contiguous motion blocks already underway are retained; acquisition
can create a mandatory destination reservation before service has started.
