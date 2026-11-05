# Command delivery feasibility

`scheduling.command_delivery` adds explicit command prerequisites to service
planning. It uses the existing `StationCalendar.overlay_contacts`,
`ContactAllocation.allocate_contacts` and `CommandWindow.report` contracts.
Their original reports are retained under `scheduling_search.command_delivery`.
No provider reservation, approval, radio transmission or command execution occurs.

The configuration declares `time_scale`, `source_id`, `contacts`,
`station_calendar`, `requirements` and `receipts`. Contact rows use the repository
fields `id`, `type: "command"`, `scenario_id` (the mission asset),
`ground_station_id`, `starts_at_s`, `ends_at_s`, `source_window_id` and `score`.
At most 128 contacts and calendar intervals are accepted. Calendar rows declare
station, positive start/end and `available`, `unavailable` or `maintenance` status.
The input contacts are declared access assumptions, not computed radio visibility.

Each prerequisite declares `request_id`, `minimum_contact_duration_s`,
`lead_time_s`, absolute `deadline_s` and eligible `contact_ids`. A suitable
allocated contact must name the correct spacecraft, last long enough, finish by
the deadline, and finish at least the lead time before activity start. Physical
opportunities are clipped before shared scheduling, so every strategy uses the
same gate. Allocated contacts also reserve their spacecraft interval against
service/maintenance. Contact pointing, radio power and link reliability are not
modeled by this bridge.

Contacts are allocated before service search using the existing deterministic
priority/contention policy. This is deliberately conservative: an unused command
contact can consume capacity, and the bridge does not jointly optimize service
and network allocation or resize a contact. One contact belongs to at most one
prerequisite; batching multiple commands into undeclared capacity is not inferred.
Half-open contact intervals permit adjacent reservations.

A planned contact before the current boundary requires a receipt with
`request_id`, `asset_id`, `contact_id`, `source_id`, `delivered_at_s` and `kind`.
Delivery time must equal the eligible allocated contact's end and be no later
than the common boundary. `observed` is a declared fact, not authenticated
telemetry. Synthetic prediction and execution use visibly different kinds;
neither is promoted to an observation. Existing receipts cannot be edited or
dropped by an update. Closed requests leave current prerequisites while the
source-bound snapshot chain and execution update retain their history.

`command_receipts` on an advance supplies these facts. Prediction and scripted
execution generate labeled synthetic receipts only from accepted parent contacts
and scheduled work. A past contact without a receipt cannot authorize future
service. Tentative service may consequently be withheld; exact protected work
cannot silently lose its prerequisite. A running segment uses the original full
activity start for lead-time checks and carries its receipt through completion.

Independent checks compare contact identities/times, station outages, shared
station/spacecraft conflicts, service overlap, deadline/lead-time feasibility,
receipt timing and parent-derived synthetic receipt history. They do not call the
allocator, prove allocation optimality, validate RF physics or establish delivery
truth. Rehashed missing-receipt and original-start/deadline mutations are rejected.

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/command_delivery_operations.json --output-dir tmp/commands
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/commands --output-dir tmp/commands_check
```

The synthetic case reserves a five-second command contact, checkpoints its
simulated delivery, continues the originally planned service and completes it.
Station IDs, contact durations, deadlines and lead times are examples, not
Reflect Orbital requirements.
