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
- Runtime validation requires that collection to preserve the planner's
  descending score order, using ascending `scenario_id` as the deterministic
  equal-score tie-break. JSON Schema remains the structural layer because this
  comparison spans adjacent rows.
- Runtime validation also preserves the producer's scenario-group boundary:
  scenario IDs are unique across ranked timelines, and every nested activity
  belongs to its enclosing scenario. Empty timelines remain valid. These
  collection and ownership comparisons are executable rather than structural.
- Each ranked timeline requires numeric `activity_score` and
  `activity_count_penalty` terms. Runtime reconciles its score to those terms plus
  present downlink-completion, timeline-precondition-pressure, and resource-
  projection-pressure adjustments; component/count explanations are not summed.
  JSON Schema requires and types the two core aggregate terms.
- Runtime also ties those core terms back to source evidence: `activity_score`
  equals the nested activity-score sum, and `activity_count_penalty` equals the
  negative selected count times the declared scoring-policy penalty (default
  zero). Malformed source values remain owned by their field validators.
- Ranked timelines also require nonnegative integer selected-observation and
  selected-contact counts. Runtime reconciles observations by activity type and
  contacts through the same normalized downlink classifier used by ranking;
  JSON Schema requires and integer-types both terms.
- Numeric `target_value`, `contact_value`, and `eclipse_penalty` component terms
  are likewise required and schema-exported. Runtime sums each matching nested
  activity term with a zero default; these explanations remain excluded from the
  aggregate score to avoid double-counting `activity_score`.
- `campaign_plan.objective_tradeoff_report` with per-ranked-timeline score-term
  deltas for operator review.
- `campaign_plan.activities` for the highest-ranked timeline.
- `campaign_plan.proposed_contacts` is an executable candidate-derived snapshot:
  runtime validation recomputes rows with the producer normalization, requiring
  exact count, order, and producer fields while allowing additional compatible
  handoff metadata. JSON Schema remains the structural row layer.
- `campaign_plan.contact_intents` is reconciled to the policy-independent base
  rows produced from final candidates, including exact count, order, and base
  fields. Compatible additional fields preserve optional approval decisions,
  whose internal consistency remains validated by the contact-intent row
  contract. JSON Schema remains the structural row layer.
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
- Candidate activity IDs are unique across the candidate collection, and
  selected activity IDs are unique within each ranked timeline. Runtime owns
  this property-key uniqueness because structural JSON Schema uniqueness applies
  to whole rows rather than one identity field.
- Candidate rows preserve ascending scenario, start-time, and activity-ID order;
  rows inside each ranked timeline preserve ascending start-time and activity-ID
  order. These adjacent-row comparisons keep optimizer handoffs deterministic
  and remain executable rather than structural.
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
