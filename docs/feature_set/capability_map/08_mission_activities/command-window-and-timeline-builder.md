# Command-Window Reports and Operational Timeline Builder

## Command-window report builders

`CommandWindow.report/2` and `OrbitalDynamics.command_window_report/2` produce schema-validated `command_window_report.v1` rows for command, tracking, health-check, and uplink contact windows. This includes provider-shaped `planned_contact` rows that declare `direction: health_check`.

Each row carries:

- Stable IDs, timing, direction, approval status, and required operator action.
- Cadence import status and source-window lineage.
- Optional approval-policy classification evidence for review rows.
- Derived timeline identity.
- Dependency/exclusivity stable-ID arrays from the source activity.
- Schema-validated `model_limits` copied from `CommandWindow.capabilities/0`.

## Reusable activity context

The reusable `activity_context` is carried by operational timeline, policy, review, and import artifacts. It includes:

- Top-level or metadata-supplied contact result, command result/success, and command-success feedback factors.
  - List- or map-valued provider result labels advertised by `Timeline.capabilities/0` are flattened to schema-safe strings in rows and activity context.
- Station reservation identity/match context, with clean numeric-string timing aliases, command/contact success factors, source labels, and declared capacity-fraction evidence parsed before schema validation.

## Provider-calendar and station-calendar evidence

Command-window rows also preserve:

- Provider-calendar entry/provider IDs.
- Normalized `station_calendar_directions`.
- Trust-boundary/provenance evidence.
- Source station-calendar overlays carried through approval context, operator-review rows, and Cadence-import rows.

Direct `availability` / `station_calendar_status` outage or maintenance evidence is canonicalized into unavailable station context before operator-action and approval-policy classification.

Command-window reports can now consume declared station-calendar overlays directly, including singular or list-valued `station_calendar_provider.v1` artifacts, and emit the nested `station_calendar_report.v1`. They promote otherwise monitor-only command/tracking/uplink/health windows to `review_command_window_station_calendar` when unavailable, maintenance, reserved, or reduced-capacity station time affects the window.

That station-calendar review also supersedes generic missing Cadence-import preparation, while preserving the superseded action and reason for adapters.

## Reviewable terminal exceptions and resolve actions

- Provider contact-result failures on completed/executed uplink or command-window rows remain reviewable terminal exceptions in command-window review/import rows.
- Rejected or status- or approval-level policy-blocked command-window rows retain resolve actions through the same review/import handoff.

## Timeline activity normalization and review gating

Command-window reports consume the shared timeline activity normalization. As a result, the following are review-gated on command-window rows before operator-review and Cadence-import handoff:

- Dependency cycles.
- Dependency ordering.
- Exclusivity integrity issues.
- Malformed command/tracking/uplink activity inputs with usable window timing.

This preserves, for invalid command-window inputs:

- Concrete cycle ID arrays.
- `invalid_activity_input` reason.
- Source activity evidence.
- Optional policy-decision/rule-match evidence.

Provider-shaped command/tracking rows that use `station_id` still produce canonical `ground_station_id` review/import context.

## Operator-review packaging and Cadence import routing

Command-window reports can be normalized into `operator_review_package.v1` `command_window_review` rows for windows that require operator review/import action, while preserving:

- Source policy decisions.
- Dependency/exclusivity context.
- Timeline-integrity evidence.
- Nested provider-calendar reservation overlap lists for approval, review, and Cadence import routing.

Direct operator-review and Cadence-import builders flatten list- or map-valued provider result fields into schema-safe review/import strings.

## Embedding in V1, V2, and V3 artifacts

- V1 campaign plus V2 repair artifacts now embed command-window reports over selected/repaired activities, so V3 strategy packages can lift branch-local command-window review rows into Cadence import manifests.
- Embedded repair results in V3 strategy branch schemas expose typed nested command-window rows, timeline identities, command-success evidence, and counts instead of opaque objects.
- Executable validation now cross-checks command-window type counts, invalid activity IDs, review-required totals, and source-window lineage totals against emitted rows.

## Operational timeline report builder

`OrbitalDynamics.Timeline` provides a reusable artifact-only `operational_timeline_report.v1` builder, public facade, and `normalize_activity/2` and `normalize_activities/2` typed activity normalizers for planned activities.

It includes:

- Duplicate timeline identity review markers on normalized activity lists.
- Dependency/exclusivity integrity review markers using the same deterministic checks as operational timeline reports.

It preserves, as invalid-input operator-review/import rows with schema-stable review IDs (instead of failing list normalization or inventing valid operational semantics), activity inputs that are:

- Missing stable identity.
- Carrying malformed activity IDs.
- Declaring malformed scenario/station/target/source-window, explicit timeline, product/payload/instrument, or scalar station-overlay identity.
- Missing activity type.

It classifies command- and uplink-directed planned contacts with command boundary semantics while preserving contact context, with `Timeline.capabilities/0` advertising the command-contact direction set.

## Standalone operational timeline review and import routing

Standalone operational timeline reports can now normalize rows that require command review, activity approval review, conflict resolution, or missing Cadence import preparation into:

- `operator_review_package.v1` `operational_timeline_review` rows.
- `cadence_import_manifest.v1` `review_operational_timeline` rows.

This happens **without executing approvals or schedule writes**.

Those Cadence rows are typed adapter gates that preserve the full `source_operational_timeline` row plus dependency/exclusivity evidence, source approval state, and Cadence import presence including adapter external ID and schema contract when declared.

**Malformed import handling:**

- Malformed non-object `cadence_import` values are preserved as `review_invalid_cadence_import` rows with invalid import-shape evidence instead of crashing timeline normalization.
- Cadence import maps that declare adapter/provider context without a trust boundary, or malformed external IDs, now follow the same invalid-import review path instead of emitting schema-invalid operational timeline rows.

## Duplicate identities and embedded package lifting

- Duplicate operational timeline identities are counted and routed to review rows with colliding activity IDs and normalized source rows, instead of being treated as unique identities.
- V1 campaign and V2 repair embedded operator-review packages now lift their embedded operational-timeline rows into the same `operational_timeline_review` surface, and V1 campaign Cadence manifests include those rows as `review_operational_timeline` adapter gates.

## Reusable activity context on timeline rows

Operational timeline rows now carry reusable activity context directly, so review/import adapters do not need to reconstruct:

- Timeline identity, dependency, timing, and target.
- Resource identity and station availability.
- Schedule-conflict, contact success, command result/success, and maneuver execution-uncertainty context.

## V3 branch derivation replay

V3 branch derivation also replays usable `operational_timeline_review` and flattened `review_operational_timeline` Cadence import rows as row-local contact, throughput, observation, command, or maneuver feedback branches, while leaving monitor/no-op timeline rows as review-only audit evidence.

Duplicate replay branch IDs from operator review and Cadence import rows are disambiguated, so same-activity command, maneuver, realized-feedback, operational-timeline, candidate-diff, freshness, refresh-budget, and contact-intent evidence is not collapsed before branch comparison.

## Dependency-cycle integrity checks

Dependency-cycle integrity checks now run over both activity-ID and timeline-ID dependency graphs. They flatten `dependency_cycle_activity_ids` and `dependency_cycle_timeline_ids` into operational-timeline, operator-review, and Cadence-import rows, so cyclic handoff payloads are review-gated even when timing alone does not expose the problem.
