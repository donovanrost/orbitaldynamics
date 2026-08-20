# 15. Policy, Safety, and Authority Boundaries

> Artifact-level reference for `policy_bundle.v1`, built-in bundles, selectors,
> and the review/import contracts that consume policy decisions lives in
> [artifacts/field_families/policy_bundles/](../../artifacts/field_families/policy_bundles/).
> This file is the cross-cutting capability framing.

The planner may recommend and explain; Cadence and operators authorize. That
boundary should stay visible in every artifact.

## Status overview

- **implemented** — see [Implemented](#implemented).
- **partial** — see [Partial](#partial).
- **near-term** — see [Near-term](#near-term).
- **later** — see [Later](#later).
- **out of scope** — see [Out of scope](#out-of-scope).

## Implemented

Status: **implemented**.

### Classification engine

- `OrbitalDynamics.Policy` normalizes approval policy maps and classifies branch
  decisions as `auto_approvable`, `operator_review_required`, or
  `blocked_by_policy`.
- V3 branch artifacts carry executable `policy_decision.v1` records with rule
  matches, approval/risk counts, fallback limits, and explicit
  no-command-execution assumptions.
- V2 repair artifacts now carry the same `policy_decision.v1` contract for repair
  approval requirements.

### Versioned authority context

- `OrbitalDynamics.AuthorityContext` builds and validates immutable
  `authority_context.v1` evidence with a content-derived stable identity,
  authority source, immutable source revision, effective-from and valid-until
  bounds, and a caller-supplied evaluation time.
- Authority-context validation is deterministic and does not read the wall
  clock, process state, application configuration, or an external authority
  service. A changed source revision changes the authority-context identity and
  the identity of a V3 strategy produced from it.
- `Policy.decide/6` adds an explicit authority-context mode while preserving the
  existing `Policy.decide/5` path only when both mode and context are absent.
  Exact explicit mode validates the supplied context. A context without mode,
  an unsupported mode, or a missing, malformed, not-yet-effective, or stale
  explicit context produces typed fail-closed evidence with the reason and
  caller-supplied input preserved; it never falls back to ambient configuration.
- Authority evidence validity and substantive policy eligibility remain
  independent. A valid authority context has an `eligible` evidence evaluation,
  but cannot change an existing `blocked_by_policy` decision: the decision,
  recommendation, review package, and import manifest remain `non_eligible`,
  and the selected import row remains review-required.
- Boundary validators recompute authority-context evaluations from canonical
  typed caller evidence. They reject context/evaluation revision substitution
  even when copied fields and enclosing strategy, review, and manifest identity
  links are otherwise coherent. Rejected input maps retain structural evidence
  for ambiguous atom/string keys and unsupported term types.
- The bounded V3 representative path preserves valid context and every typed
  evaluation through `policy_decision.v1`, `strategy_recommendation.v1`,
  `campaign_strategy.v3`, its `operator_review_package.v1`, and the existing
  selected-strategy row and provenance in `cadence_import_manifest.v1`.
- Authority evidence remains optional. Only callers supplying neither mode nor
  context retain the prior policy and campaign-strategy artifact shape and
  behavior.

### Approval requirements

- `approval_requirement.v1` rows carry explicit `requirement_type` values for:
  - contact schedule changes,
  - observation reassignment,
  - maneuver timing changes,
  - downstream-window review,
  - strategic additions,
  - cancellations,
  - and command/health review.
- Standalone approval requirements now expose and validate activity context,
  policy bundle/rule IDs, policy classification, required authority,
  approval-rule matches, and embedded policy-decision evidence for Cadence review
  routing.

### Policy action rule match dimensions

Policy action rules can now match by:

- `requirement_type` / `requirement_types`.
- grouped `risk_types`.
- grouped `event_types`.
- timeline `status` / `statuses`.
- event and requirement `approval_status` / `approval_statuses`.
- approval-requirement and branch-event `policy_classification` /
  `policy_classifications`.
- `allocation_status` / `effective_allocation_status` / `allocation_reason`
  selectors.
- `locked` state.
- action and activity type.

They can also target deterministic operator-review routing with `review_queue` /
`review_queues` and `review_queue_key` / `review_queue_keys` selectors,
including concrete resource-filter, resource-projection, ground-network,
timeline-integrity, command-window, maneuver, invalid maneuver-recommendation,
and policy-escalation queue families in `operator_review_queue_authority_v1`.

**Enum constraint** — `policy_classification` and `policy_classifications`
selectors are runtime- and schema-constrained to the policy classification enum
(`auto_approvable`, `operator_review_required`, `blocked_by_policy`).

**Scalar or list context** — status, approval-status, policy-classification,
review-queue, review-queue-key, and Cadence-import-status selectors consume
either scalar requirement context or list-valued requirement context, so
aggregated review/import rows do not need to collapse multiple routing labels
before policy classification.

**Direction alias normalization** — contact-direction and provider-calendar
direction selectors normalize provider-style case, whitespace, hyphen, command,
tracking, and health-check aliases such as `cmd`, `commanding`, `Track-ing`, and
`healthcheck` across rule definitions and runtime requirement, risk,
branch-event, and candidate-plan evidence before matching, while preserving
non-direction identifiers verbatim.

### Built-in policy bundles

`OrbitalDynamics.Policy` exposes executable/exported `policy_bundle.v1` rows for
versioned built-in approval policy bundles:

- `default_v1`
- `command_contact_authority_v1`
- `contact_command_review_v1`
- `conservative_ops_v1`
- `timeline_protection_v1`
- `degraded_payload_guard_v1`
- `mission_ops_escalation_v1`
- `ground_network_allocation_v1`
- `maneuver_authority_v1`
- `operator_review_queue_authority_v1`
- `resource_projection_authority_v1`

These rows carry schema-validated `model_limits` copied from
`Policy.capabilities/0`, and the selected `policy_bundle_id` is carried on
`policy_decision.v1` rows.

`OrbitalDynamics.Policy.capabilities/0` declares the supported classifications,
match dimensions, adapter hooks, fallback fields, policy bundle IDs, and
artifact-only limits.

### Facades

Top-level facades expose reusable policy bundles, organization-specific bundle
construction, normalization, and classification for application callers without
executing approvals or workflow:

- `OrbitalDynamics.policy_bundles/0`
- `OrbitalDynamics.policy_bundle!/1`
- `OrbitalDynamics.policy_bundle_artifact!/1`
- `OrbitalDynamics.policy_bundle_artifacts/0`
- `OrbitalDynamics.organization_policy_bundle/3`
- `OrbitalDynamics.normalize_approval_policy/1`
- `OrbitalDynamics.policy_decision/5`

### Organization-specific bundles

- Inline organization-specific `policy_bundle.v1` rows can carry adapter
  provenance and participate in the same deterministic decision path as built-in
  bundles.
- Adapter-shaped organization policy provenance must declare
  `provenance.trust_boundary` before schema validation accepts the bundle.

### Degraded mode, availability, and direction matching

- Policy action rules can match degraded mode and payload or antenna
  availability booleans while preserving explicit `false` values.
- Policy action rules can match contact `direction` or direction-list evidence
  from requirement context, and explicit `station_calendar_direction` /
  `station_calendar_directions` evidence separately from the contact direction.

### Identity, scope, and capacity selectors

Policy action rules can match:

- `ground_station_id` (including provider-shaped `station_id` in either rule or
  requirement context, plus aggregated `ground_station_ids` / `station_ids`
  lists).
- `spacecraft_id` (including planner-native `scenario_id` in requirement context
  plus `spacecraft_ids` / `scenario_ids` lists).
- `target_id` / `target_ids`.
- `station_availability`, aggregated `station_availabilities`.
- `station_contention_status` / `station_contention_statuses`.
- station-reservation context.
- reduced `capacity_fraction` thresholds for command/contact and ground-network
  allocation boundaries.

**Trust-boundary routing** — inline policy rules can also match
`station_calendar_trust_boundary_status` evidence from allocation activity
context, so missing provider-calendar trust boundaries can be routed through
policy instead of only preserved for downstream review. The built-in
ground-network allocation policy now routes command-direction station-calendar
evidence through that same review authority surface.

### Timeline transition and protection selectors

Rules can now match:

- single-activity timeline transition outcomes with `transition_decision` /
  `transition_decisions` and `application_status` / `application_statuses`.
- planned timeline-feedback/import protection evidence with
  `planned_protection_decision` and `planned_protection_category` selectors and
  plural-list variants.

Scalar and list-valued requirement context feed the same executable policy
matcher.

### Cadence-facing review, allocation, and suppression selectors

Rules can match:

- Cadence-facing review action/reason codes with `required_operator_action` and
  `operator_action_reason` selectors plus plural-list variants.
- contact-allocation status/reason evidence with `allocation_status`,
  `effective_allocation_status`, and `allocation_reason` selectors plus
  plural-list variants.
- resource suppression routing evidence with `suppressed_reason` and
  `resource_blocking_dimension` selectors plus plural-list variants.

Aggregated allocation and suppression context preserves the matched lists in
rule-match evidence.

### Resource and provenance requirement context

Rules can match resource/provenance requirement context with:

- `resource_pressure_statuses`
- `resource_source_qualities`
- `resource_trust_boundaries`
- `resource_trust_boundary_statuses`
- `first_resource_pressure_kinds`
- `feedback_sources`
- `feedback_scopes`
- `trust_boundaries`
- `source_event_types`

Plus station availability/contention list evidence.

### Station-calendar and reservation selectors

- **Entry/provider/status and reservation identity** — station-calendar
  entry/provider/status and reservation identity/owner/match evidence with
  `station_calendar_entry_id`, `station_calendar_provider_id`,
  `station_calendar_provider_entry_id`, `station_calendar_direction`,
  `station_calendar_trust_boundary_status`, and plural-list variants.
- **Aggregated lists** — including aggregated
  `station_calendar_provider_ids`, `station_calendar_provider_entry_ids`,
  `station_calendar_directions`, `station_calendar_statuses`,
  `station_calendar_trust_boundary_statuses`, and
  `station_calendar_reservation_ids` lists from risk, branch-event,
  contention/allocation, and requirement context.
- **Branch risk/event reservation aliasing** — branch risk/event matching
  treats direct `station_reservation_id` / `reservation_id`, `station_reserved_by`
  / `reserved_by`, and `station_reservation_status` / `reservation_status`
  evidence as station-calendar reservation ID/owner/status context for
  provider-calendar rules.
- **Reservation identity/owner/match** — plus station reservation
  identity/owner/match evidence with `station_reservation_id`,
  `station_reserved_by`, `station_reservation_match_status`, and plural-list
  variants, including aggregated `station_reserved_bys`,
  `station_reservation_statuses`, and `station_reservation_match_statuses` lists
  from contention/allocation approval context.
- **Provider ambiguity and reservation owner/status** — provider
  station-calendar ambiguity and reservation owner/status list evidence with
  `station_calendar_entry_ambiguous`, `station_calendar_ambiguous_entry_id`,
  `station_calendar_ambiguous_entry_count_min` /
  `station_calendar_ambiguous_entry_count_max`, `station_calendar_reserved_by`,
  `station_calendar_reservation_status`, `station_calendar_reservation_id`, and
  plural-list variants, with rule-match rows preserving scalar and plural
  reservation owner/status/ID evidence when available.

### Timeline-integrity selectors

- timeline-integrity status and issue-type evidence with
  `timeline_integrity_status`, `timeline_integrity_issue_type`,
  source/replacement-prefixed timeline-integrity selectors, and plural-list
  variants.
- nested source/replacement protection-decision evidence with
  `source_protection_decision`, `source_protection_category`,
  `replacement_protection_decision`, and `replacement_protection_category`
  selectors and plural-list variants.

Rule-match evidence preserves the matched scalar and list-valued selector
context for review queues.

### Scoped risk, event, and feasibility matching

- **Branch-event rules** honor direction, station, spacecraft, and target scopes
  when matching branch events.
- **Direction- and station-scoped risk rules** also honor provider-shaped
  `station_id` when matching risk indicators and export canonical
  `ground_station_id` evidence.
- **Spacecraft-scoped risk rules** can match resource and availability risk
  indicators by `spacecraft_id` without crossing spacecraft.
- **Resource-filter suppression risks** now preserve spacecraft, scenario,
  station, target, direction, and applied station-calendar direction evidence
  from the suppressed row through policy, operator-review, and Cadence-import
  handoff rows. Policy action rules can also target that applied station-calendar
  direction evidence without conflating it with the contact's requested
  direction.
- **Target-scoped risk rules** can match target feedback and urgent-target risk
  indicators by `target_id` without crossing targets.
- **Feasibility-status rules** honor direction, station, spacecraft, and target
  scopes when matching strategic additions.
- **Deterministic ordering** — approval-rule matches use canonical ordering
  across activity, risk/event/feasibility, scope ID, and reason fields so
  repeated scoped matches remain deterministic.

### Escalation metadata

- Policy action rules can emit artifact-only escalation metadata for escalation
  level, queue, role, required authority, and SLA seconds.
- The checked-in mission-ops policy fixture covers command, contact,
  strategic-priority, and downlink-loss escalation rules.

### Timeline protection (`timeline_protection_v1`)

- `timeline_protection_v1` now routes locked and approved timeline-item changes,
  source-preserved transition applications, and locked/approved source
  protection decisions to mission-planning review.
- Transition-application batch plans are also an executable
  `timeline_transition_application_report.v1` contract with checked-in fixture,
  JSON Schema export, and top-level review/import facade dispatch, including
  optional approval-policy rule matching over standalone transition-application
  review rows.
- The contract now exposes report-level application status, transition decision,
  required-action, transition-type, and transition-category count maps, selected
  safe activities, selected-subset timeline-integrity counts/types, nested
  source/replacement protection-decision objects, application-row transition
  metadata, and model-limit metadata in JSON Schema.
- Executable validation checks the summary counters, selected-activity
  operational payload shape, selected-subset integrity evidence, transition
  summaries, and protection-decision object shape against application rows before
  those artifacts reach review/import adapters.
- A public selected-activities helper now returns the same normalized safe
  subset from a report or source/replacement timelines without traversing
  review-gated application rows.
- The protection policy normalizes JSON-style locked/approved true flags before
  classification, and blocks executed timeline changes with flight-director
  authority metadata, still without executing approval workflow.

### Ground-network allocation (`ground_network_allocation_v1`)

`ground_network_allocation_v1` blocks unavailable/maintenance station contacts
and requires review for:

- declared reservation overlaps,
- severe station capacity reductions,
- low realized downlink completion fractions,
- missing station-calendar trust-boundary evidence,
- and custom contact-priority fields that have no numeric evidence,

all without reserving station time.

### Maneuver authority (`maneuver_authority_v1`)

`maneuver_authority_v1` requires maneuver authority review for maneuver timing
changes, impulsive-burn approval boundaries, and failed provider
`maneuver_result` aliases without approving burns or mutating schedules.

### Contact/command success and result aliases

Policy action rules can match:

- explicit `contact_success: false` and `command_success: false` evidence,
  including metadata-supplied trimmed case-insensitive JSON-style false values at
  contact-intent ingress.
- normalized scalar, list-valued, or map-valued provider `contact_result` /
  `command_result` aliases such as `dropped`, `no-contact`, `rejected`, and
  `timed-out`.
- normalized provider `observation_result` / `maneuver_result` aliases for
  organization-specific routing and maneuver-authority failure review.
- `actual_completion_fraction`, `contact_success_factor`,
  `command_success_factor`, `observation_success_factor`, and
  `maneuver_success_factor` thresholds with executable unit-interval validation.

`policy_decision.v1` rule matches keep matched source confidence factors in that
same interval.

### Cadence import status routing

Policy action rules can match `cadence_import_status` / `cadence_import_statuses`
so adapter handoff issues can be routed from policy without reopening raw import
rows, with runtime normalization, artifact validation, and exported JSON Schema
constraining those selectors from `Policy.capabilities/0` to the same Cadence
import status vocabulary as manifest rows for adapter preflight checks.

### Command/contact authority (`command_contact_authority_v1`)

- Classifies downlink, uplink, command, tracking, and health-check windows into
  distinct artifact-only authority queues.
- Routes failed or low-confidence contact-success evidence to ground-network
  review, raw failed contact-result evidence to the same queue, command-success
  evidence to command authority review, raw failed command-result evidence to
  the same authority, and missing or invalid Cadence import context to
  mission-planning adapter review.
- Also classifies `review_command_window_station_calendar` evidence from direct
  command-window station-calendar overlays, blocking unavailable or maintenance
  station time and routing reserved or reduced-capacity station time to
  ground-network review.
- All through approval-policy rows without approving contacts or sending
  commands.

### Resource projection policies

- **Conservative operations bundle** also blocks projected storage overflow,
  battery depletion, and downlink shortfall pressure risks from
  `resource_projection_report.v1` rows.
- **`resource_projection_authority_v1` bundle** matches resource pressure
  status/types, resource source quality, resource trust-boundary status, and
  first pressure-kind evidence plus invalid resource-projection activity and
  summary input evidence from resource-projection approval context for
  review/escalation routing without mutating mission state.
- **V3 strategy default approval policy** treats promoted branch-level
  `storage_overflow`, `battery_depletion`, and `downlink_shortfall` risks as
  blocked planning boundaries.

### Decision records and repair coverage

- `policy_decision.v1` rows summarize matched escalations and schema-validated
  `model_limits` copied from `Policy.capabilities/0` without executing workflows.
- Built-in contact/command, conservative-ops, degraded-payload, mission-ops,
  ground-network, and resource-projection bundles now match the actual V2/V3
  repair requirement actions and `health_check_review` requirement type emitted
  by planner artifacts.

### Degraded-payload guard

The degraded-payload guard now blocks antenna-unavailable
contact/downlink/tracking changes without blocking command and health-review
exemptions.

### Provenance preservation

Policy decisions produced from organization-specific policy bundles preserve
adapter, organization, and source provenance as decision-level policy-bundle
provenance.

### Validation and integrity

- **Normalization rejects malformed input** — runtime policy normalization
  rejects malformed fallback limits, blocked-risk lists, action-rule entries,
  action-rule IDs, unit-interval thresholds, boolean action-rule fields, selector
  string fields/lists, and escalation SLA values before classification, matching
  the executable policy-bundle schema boundary instead of silently misclassifying
  inline policy inputs.
- **Clean values normalize** — clean numeric-string fallback limits,
  unit-interval thresholds, non-negative ambiguity counts, non-negative
  contention overlap thresholds, and escalation SLA values normalize before
  runtime classification and organization bundle artifact generation.
- **Deterministic contention ordering** — rule matches are now canonically
  ordered across contention routing fields such as resource scope, resolution
  status/issue, allocation status/reason, selected priority source,
  station-reservation evidence, and provider-calendar identity lists, so repeated
  contact-contention matches remain deterministic for downstream review queues.
- **Duplicate rule-ID rejection** — runtime policy normalization and
  `policy_bundle.v1` executable validation now reject duplicate action-rule IDs
  so rule-match and escalation evidence cannot collapse distinct authority rules
  behind the same identifier.

## Partial

Status: **partial**.

- Policy decisions and built-in or inline organization-specific bundles are
  reusable artifacts.
- Direct row-level policy decisions across contact, link-capacity, resource,
  maneuver-review, command-window, and station-calendar exports now reuse the
  canonical `policy_decision.v1` schema shape.
- Operator-review and Cadence import `source_policy_decision` and
  `source_policy_escalation` snapshots expose and validate their known
  policy-classification and escalation evidence.
- **But** — `authority_context.v1` is caller-supplied evidence for one bounded
  campaign-policy path, not an authority registry or a repository-wide retrofit
  of every policy surface. Command/contact execution boundaries remain
  classification-only, and organization-specific policy adapters intentionally
  remain artifact-only. Within that bounded path, operator-review and Cadence
  import validators recompute authority evaluations, reject missing propagation
  roots, prevent non-eligible selected rows from becoming import-ready, and keep
  blocked alternatives non-eligible independently of an eligible selection.

## Near-term

Status: **near-term**.

- Broaden policy coverage for richer command/contact authority boundaries.
- Extend explicit authority-context propagation to additional policy producers
  only when their callers can supply equally immutable revision and evaluation
  evidence; no ambient-config fallback is planned.
- Policy rule matches now lift organization/inline policy adapter provenance,
  including source, adapter, organization, policy source, and trust boundary,
  plus contention resource-scope, resolution, priority-source, and
  provider-calendar reservation context for downstream review routing without
  changing the artifact-only authority boundary.

## Later

Status: **later**.

- Policy provenance, policy simulation, organization-specific policy adapters,
  and multi-step approval workflows owned by Cadence.

## Out of scope

Status: **out of scope**.

- Autonomous command execution or bypassing Cadence/operator authority.
- External authority lookup, approval, scheduling, Cadence import writes, or a
  claim that a recommendation was authorized or executed.
