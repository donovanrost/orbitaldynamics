# V1: Campaign Plan Generation

LEO Constellation Campaign Planner V1 generates ranked, reproducible campaign
plans for a fixed planning horizon.

It answers:

> Given these spacecraft, targets, ground stations, model assumptions, and
> constraints, what should the constellation do over the next planning window?

## Inputs

- `campaign.spacecraft`: multiple spacecraft with metadata and initial states.
- `ground_stations`: surface stations and minimum elevation constraints.
- `campaign.ground_network`: optional station availability/capacity intervals
  that annotate affected contacts and feed `station_calendar_report.v1`.
  Entries may use `status` or `availability`; numeric `availability` is treated
  as a capacity-fraction alias. File-backed campaign and candidate-refresh
  manifests preserve reservation metadata and row provenance for downstream
  refresh/filter semantics.
- `campaign.targets`: surface targets, minimum elevation constraints, and
  priorities.
- `campaign.planning_horizon`: optional positive fixed duration and output
  cadence, with cadence requiring and not exceeding duration. File-backed
  propagation manifests require both; direct planning over an existing result
  set may omit both because the source result need not carry its propagation
  horizon. When duration is declared, the emitted V1 plan uses the zero-based
  horizon as the executable envelope for candidate, selected, ranked,
  proposed-contact, and contact-intent rows.
- `propagator` and `propagator_opts`: backend and model options.
- `campaign.constraints`: V1 activity filters such as minimum duration, eclipse
  avoidance, and maximum timeline activity count.
- `campaign.scoring_policy`: deterministic weights, rank limit, and optional
  `contact_activity_types` for deriving downlink, command, tracking, and
  health-check candidates from ground-station access windows; optional
  `downlink_completion_weight` for selecting and ranking downlink throughput
  against declared downlink-completion demand; optional
  `timeline_precondition_weight` for ranking selected activities with blocked or
  review-required timeline activity preconditions below otherwise comparable
  clear activities; optional `resource_projection_weight` for ranking selected
  activities with projected storage overflow, downlink shortfall, battery
  depletion, or resource availability pressure below otherwise comparable clear
  activities.
- Seeds for reproducible search or Monte Carlo studies.

## Core Capabilities

- Propagate one or more LEO spacecraft with declared assumptions.
- Generate ground-station access windows.
- Generate eclipse intervals.
- Generate target visibility windows.
- Represent candidate activities such as coast, observe, slew, downlink,
  command window, and impulsive maneuver.
- Rank candidate timelines against simple objectives and constraints.
- Emit plan artifacts with assumptions, backend choices, seeds, timing, and
  validation level.
- Derive reproducible plan identity as
  `campaign_plan:<study_id>:<generated_at>` from the encoded study ID and ISO
  8601 generation time.

## Outputs

- `campaign_plan.candidate_activities`.
- `campaign_plan.ranked_timelines`.
- `campaign_plan.objective_tradeoff_report` with per-ranked-timeline score-term
  deltas for operator review.
- `campaign_plan.activities` for the highest-ranked timeline.
- Selected, candidate, and ranked-timeline activities carry required numeric
  non-negative `duration_s` evidence. Executable validation reconciles each
  value to `ends_at_s - starts_at_s`; JSON Schema exposes the required type and
  non-negative boundary while runtime validation owns the arithmetic check.
- Those activity rows also carry required numeric `score` values and numeric
  `score_terms` maps. Runtime validation requires each score to equal its term
  sum; JSON Schema constrains every term value to a number.
- Runtime validation also treats activity rows as immutable snapshots: every
  ranked row must exactly match its candidate row by ID, and top-level selected
  rows must exactly match the first ranked timeline. JSON Schema remains the
  structural layer for these arrays; cross-array equality is executable behavior.
- Every activity preserves its producer window through required stable
  `source_window_id` and nested `source_window.id` evidence. Runtime validation
  requires those IDs to match before the activity is accepted for handoff.
- Current activity kinds also pin nested source-window family: observations use
  `target_visibility`; downlink, command, tracking, and health-check activities
  use `ground_station_access`. Future activity kinds remain open until their
  producer provenance contract is declared.
- Activity `type` is a required nonblank string across selected, candidate, and
  ranked rows. The vocabulary remains open so later planners can add richer
  activity kinds without silently accepting malformed tokens.
- Every activity also carries a required `cadence_import` envelope with a stable
  external ID equal to the activity ID and a nonblank Cadence activity type.
  Current dispatch mapping is exact: observe becomes `observation`, command
  becomes `command`, and downlink/tracking/health-check become `contact`. This
  remains artifact-only identity evidence, not import authority.
- Downlink, command, tracking, and health-check activities require stable ground-
  station identity plus a `direction` equal to the activity type. Observation
  and compatible future non-contact activity tokens do not inherit that contact
  routing requirement.
- Those contact-family activity envelopes also declare the exact
  `proposed_contact.v1` Cadence adapter schema. Observation and future non-contact
  envelopes do not claim that contact shape.
- `campaign_plan.proposed_contacts` with stable external IDs for later Cadence
  import.
- `campaign_plan.contact_intents` as artifact-only `contact_intent.v1` rows for
  proposed downlink/contact activities, preserving campaign approval-policy
  requirements, rule matches, and policy decisions when supplied. Reviewable
  contact intents are also lifted into `contact_intent_review` operator-review
  rows and `review_contact_intent` Cadence import rows before schedule handoff;
  station-calendar entry IDs are flattened from nested provider source evidence
  when needed while preserving the full source entry and overlap context. V2
  repair and V3 branch-repair artifacts perform the same lift for
  refresh-sourced `source_contact_intents`. V3 branch replay keeps ordinary
  approval-required intents review-only, but direct standalone or wrapped
  blocked-by-policy and missing/invalid Cadence-import downlink intents become
  branch-local pressure events with provider-calendar and reservation-match
  evidence preserved.
- `campaign_plan.contact_allocation_report` as artifact-only
  `contact_allocation_report.v1` rows over proposed contact candidates, with
  allocated/deferred/blocked status for review-gated handoff; duplicate contact
  IDs are blocked before contention allocation to preserve deterministic contact
  identity joins, and overlapping contacts for the same spacecraft across
  multiple stations are deferred through the same review-only contention path.
- `campaign_plan.link_capacity_report` as artifact-only fixed-rate throughput
  review over candidate and selected downlinks. A downlink-completion objective
  with `required_downlink_mb` feeds selected-capacity shortfall review unless an
  explicit link-capacity policy requirement overrides it.
- Access and eclipse summaries.
- Target visibility summaries.
- `station_calendar_report.v1` when manifest `campaign.ground_network`
  intervals annotate generated contacts; duplicate contact IDs on affected rows
  are preserved with deterministic suffixed row IDs.
- Unique non-empty warning strings, assumptions, provenance, ranking score, and
  ranking explanation.
- Planning assumptions pin the candidate builder, timeline selector, resource
  and contact filters, artifact-only Cadence boundary, and the constraint /
  scoring-policy maps used for the plan.
- Provenance always exposes run, manifest, revision, propagator, and propagator-
  option keys. Direct plans may carry null values; file-backed manifest evidence
  carries a typed path and lowercase SHA-256 digest when available.
- Reproducible study archive with manifest hash when run from disk.

## Cadence Integration

V1 should hand Cadence proposed operational products, not hidden numerical
state. A useful import boundary is:

- planned activities,
- scheduled contacts,
- command windows,
- downlink windows,
- maneuver table,
- assumptions and plan provenance,
- human-readable warnings.

Cadence should keep approval in the loop. A generated plan should be reviewable
before it becomes an operational schedule.
