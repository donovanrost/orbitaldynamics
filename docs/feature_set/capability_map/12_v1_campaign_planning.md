# 12. V1 Campaign Planning

Status: **implemented** (with `partial`, `near-term`, `later`, and `out of scope` notes below).

## Implemented

V1 produces fixed-horizon campaign manifests spanning multiple spacecraft, targets, ground stations, constraints, and a scoring policy.

From those manifests it generates:

- Candidate observations/downlinks.
- Ranked timelines.
- Selected activities.
- Proposed contacts and contact intents.
- Contact filter reports.
- Contact contention reports.
- Advisory contention-resolution recommendations.
- Contact allocation reports.
- Command-window reports.
- Link capacity reports.
- Station calendar reports.
- Target commitment summaries.
- Objective satisfaction reports, including downlink-completion contact-count and required-data-volume fields.
- Operational timeline reports.
- Resource projection reports over selected activities, when resource summaries are supplied.
- Resource filter reports, when campaign resource summaries suppress candidates.
- Constraint reports.
- Objective tradeoff reports.
- Warnings, assumptions, and provenance.

**Constraint reports** come from the reusable campaign-local constraint module, over the active planner-local constraints:

- `max-timeline-activity`
- `minimum-duration`
- `eclipse-avoidance`
- resource projection margin
- aggregate link-capacity constraints

They include explicit warning severity for local violations.
Embedded reports are declared as optional `campaign_plan.v1` nested contracts
and run the full executable `constraint_report.v1` validator for row shape,
model limits, derived constraint/row/status counts, and status maps. V1 context
also pins the campaign-planner constraint model and the
`campaign_plan.assumptions.constraints` source assumption.
Embedded contact-allocation reports are likewise optional direct nested
contracts and run the full standalone allocation validator over their rows,
typed counters/maps, nested reports, capacity-pack evidence, and model limits.
V1 context pins `campaign_plan.candidate_activities` as the allocation source.
The emitted `cadence_import_manifest.v1` is also an optional direct nested
contract. Embedded manifests run the standalone required-field, row, derived
count/map, model-limit, and artifact-only boundary checks, while V1 requires
their source type and source ID to identify the containing campaign plan.
Embedded `command_window_report.v1` evidence is likewise optional and direct.
It runs the standalone row/count/model-limit validator while V1 pins both
selected-activity source labels and the artifact-only no-schedule-mutation /
no-command-execution boundary.
The optional contact-filter and station-calendar reports are also exported as
direct nested contracts. Campaign validation continues to run their existing
standalone validators over suppression and declared station-availability
evidence.

V1 plan identity is executable: `generated_at` must be an ISO 8601 date-time,
and `plan_id` must equal `campaign_plan:<study_id>:<generated_at>`. This keeps
the source identity consumed by optimizer, review, and Cadence handoffs tied to
the producer's deterministic study/time inputs.

V1 planning assumptions require the producer's candidate-builder, timeline-
selector, resource-filter, contact-filter, and artifact-only Cadence-boundary
identifiers plus typed constraint and scoring-policy maps. Optimizer/report
reconciliation continues to pin the values inside those maps to plan evidence.

V1 provenance requires the producer's run, manifest, revision, propagator, and
propagator-options keys. Values remain nullable for direct planning over an
existing result set; non-null values are typed, and supplied manifest SHA-256
evidence must be a lowercase 64-character digest.

V1 warnings remain an extensible human-readable vocabulary, but executable
validation and export require every entry to be a non-empty string and reject
duplicates before warning evidence reaches review/import handoffs.

The required planning-horizon object has optional positive numeric `duration_s`
and `output_step_s` fields; declared cadence requires and cannot exceed duration.
File-backed propagation manifests require both fields, while direct planning
over an existing result set may emit an empty horizon because the result need
not carry its propagation horizon. When duration is declared, runtime validation
treats `[0, duration_s]` as the envelope for candidate, selected, ranked-timeline,
proposed-contact, and contact-intent rows while retaining each row contract's
interval-order checks.

Every selected, candidate, and ranked-timeline activity requires numeric
non-negative `duration_s` evidence. Runtime validation additionally reconciles
the declared value to `ends_at_s - starts_at_s`, preventing scoring, throughput,
commitment, and handoff consumers from observing contradictory timing evidence.
The JSON Schema export carries the representable required/type/minimum rules;
the cross-field arithmetic check remains executable runtime behavior.

Target commitments are optional typed inline V1 rows. Runtime validation checks
stable target/selected-activity IDs, non-negative counts and durations, status
vocabulary, unique targets, exact candidate/selected observation evidence, and
completeness against target-commitment objective-satisfaction rows.

**Timeline score terms** include:

- selected observation/contact counts
- observation value
- contact value
- eclipse penalty
- activity score
- activity-count penalty components

Selected, candidate, and ranked-timeline activity scores are independently
auditable: runtime validation requires numeric `score` and `score_terms`
evidence, rejects non-numeric term values, and reconciles every activity score
to its term sum. JSON Schema exports numeric score-term map values on all three
activity surfaces; cross-field sum reconciliation remains executable behavior.

Activity lineage is likewise executable across selected, candidate, and ranked
rows: `source_window_id` and nested `source_window.id` are required stable IDs,
and runtime validation requires them to match. The export requires the nested ID
so downstream timing, score, and provenance review can retain the producer
window identity.

Every selected, candidate, and ranked activity also requires a nonblank string
`type`. The runtime/export contract intentionally keeps that vocabulary open:
current producers emit observation and contact-family tokens, while future
activity kinds remain compatible without allowing malformed dispatch values.

The artifact-only Cadence boundary begins on each activity row: selected,
candidate, and ranked activities require a `cadence_import` envelope with stable
`external_id`, nonblank `activity_type`, and external identity equal to the
activity ID. These fields support deterministic review/import mapping but do not
grant schedule mutation or command authority.

Current producer activity types also pin their Cadence dispatch family:
observations map to `observation`, commands to `command`, and downlink, tracking,
and health-check activities to `contact`. Future activity types retain an open
dispatch mapping until their producer contract is declared.

Producer-supported downlink, command, tracking, and health-check rows also
require stable ground-station identity and a direction equal to the activity
type across selected, candidate, and ranked timelines. The conditional rule
keeps observations and future non-contact activity tokens compatible while
preventing contact-routing drift in review/import artifacts.

Runtime `campaign_plan.v1` validation requires each ranked timeline to carry a
stable scenario ID, numeric score, and numeric score-term values. When the
optional `score_term_report.v1` is present, its source, model, term-key union,
rank/scenario/term rows, values, timeline scores, and selected flags must match
the enclosing ranked timelines. Both that report and the optional
`objective_tradeoff_report.v1` are exported as direct nested campaign contracts.
The exported ranked-timeline schema constrains every score-term value to a
number. These V1 terms are explanatory fields that include counts and subtotals,
so they are not treated as one additive score sum.
Runtime validation also reconciles the optional objective-tradeoff report with
the ranked timelines: V1 model/source, rank and scenario identity, ranking and
term-key counts, scores and selected-score deltas, term maps, selected counts,
and ordered activity IDs must match. Ranked-timeline activity envelopes reuse
the executable planned-activity contract and require their declared activity
count to match the nested rows.
The optional optimizer handoff is reconciled with the same plan: V1 optimizer
and selection identities, candidate/selected/ranked counts and ordered IDs,
score-term keys, constraints, scoring policy, and objective must match the
enclosing candidates, selected timeline, assumptions, ranking explanation, and
objective-tradeoff report. The required ranking explanation has executable and
exported objective/formula/policy-object shape while the optimizer itself
remains optional for compatibility.

## Partial

- Station contention resolution is deterministic and priority-aware, but still not a live reservation service.
- Resource/link constraints are planning-grade summaries rather than calibrated subsystem or link-budget models.
- Constraint reports and objective tradeoffs are reviewable, but still derive from the simple greedy timeline ranking model.

## Near-term

**Goal** — make V1 feature-complete as a reviewable operator artifact by broadening remaining station-contention policy depth, without changing the artifact-only Cadence boundary.

### Contact-contention review/import rows

Contact-contention review/import rows now preserve, for both conflict groups and resolution recommendations:

- resource scope
- station and spacecraft ID arrays
- candidate count
- selection reason
- matched policy-escalation authority, rule, queue, role, level, and SLA routing metadata

### Approval-policy action rule matching

Approval-policy action rules can match:

- contention resource scope
- selection reason
- selected priority source
- ambiguous resolution status/issue
- station-calendar provider IDs, provider entry IDs, reservation IDs
- declared/missing station-calendar trust-boundary status lists
- applied station-calendar direction lists
- overlap-pressure thresholds for contention window duration, summed contact duration, overlap duration, maximum concurrent contacts, and pairwise overlap count
- station reservation identity, owner, and match-status selectors

**Ground-network allocation bundle** — requires review for declared provider-calendar contention, plain same-station contention groups, and deterministic same-station contention recommendations. It routes high-overlap station contention to a priority ground-network queue with overlap-pressure rule evidence.

**Mission-ops escalation bundle** — applies the same high-overlap priority routing alongside generic contact-execution coordination, and blocks duplicate contact identity contention until manual resolution.

**Invalid / reduced-capacity rows** — invalid contact-contention input rows now receive row-level approval-policy evidence that flows through operator-review and Cadence-import handoffs, plus reduced-capacity allocation rows whose declared `required_capacity_fraction` exceeds available station capacity.

### Priority-aware resolution

Priority-aware resolution can use a computed `command_contact_priority` field, so command/uplink contacts can win station conflicts without requiring callers to precompute a mission-specific numeric priority.

The default priority chain now also includes computed `station_reservation_priority`, so direct matched/owned station-reservation evidence, or a direct reservation ID with an active reservation status, can beat higher-score unreserved contacts. This includes the `owner_matched` status emitted by station filtering and contact allocation for caller-owned reserved windows, in advisory station-contention recommendations. It accepts both station-prefixed reservation fields and direct reservation aliases, while aggregate provider-calendar reservation lists remain review evidence instead of phantom ownership.

Direct station-reservation ID, owner, status, and match-status evidence is flattened onto conflict groups, recommendations, review rows, and import rows as plural lists, so adapters can route ownership conflicts without unpacking candidate rows.

Approval-policy action rules can now match `priority_fields_without_numeric_evidence_count_min` plus `priority_field_without_numeric_evidence` / `priority_fields_without_numeric_evidence` evidence, when custom contention priority fields were requested but no candidate carried usable numeric data.

### Alias and input normalization

- **Contact direction aliases** — contact filtering, contact-intent generation, command-window review, link-capacity summaries, and allocation normalize provider contact direction aliases before station-calendar matching.
- **Contact allocation parsing** — contact allocation parses clean numeric-string timing aliases and capacity-fraction requirements, plus top-level or metadata-supplied trimmed case-insensitive contact/command feedback booleans and confidence factors, before reduced-capacity blocking, packing, policy, and review/import handoff.
- **Contact contention canonicalization** — contact contention now canonicalizes provider-shaped nested `station` / `ground_station` identity objects, provider direction aliases, and clean numeric-string contact timing aliases before grouping or invalid-input review, so station ownership, direction, and timing evidence are not lost at the standalone API boundary.

### Contention resolution ranking and policy

Contention resolution parses numeric-string score, priority, and top-level or metadata-supplied feedback confidence evidence for ranking and review, while malformed numeric strings remain missing numeric evidence.

**Contact priority override maps** — resolution policies can carry mission-specific contact priority override maps (`contact_priorities`, `contact_priority_overrides`, `priority_overrides`, or `priority_by_contact_id`) that rank contacts through `policy_contact_priority` without mutating candidate rows. Normalized override maps/counts/contact IDs are exported in the resolution schema and semantically linted for count and ID consistency. Malformed override keys or nonnumeric values are retained as ignored priority-override warning evidence through recommendation, operator-review, and import rows.

**Executable tie-breakers** — resolution `tie_breakers` are now executable for starts, ends, score, priority, computed command priority, computed station-reservation priority, and contact identity, so equal-rank contention can be resolved by declared policy instead of hardcoded fallback order.

**Policy robustness** — unsupported caller selection rules normalize back to the default executable policy while preserving requested/ignored policy evidence; keyword-list policies are accepted; and malformed policy inputs become warning evidence instead of crashes.

### Schema and report exposure

- Exported JSON Schema now describes and constrains the nested contention-resolution policy metadata (`selection_rule`, `priority_fields`, `tie_breakers`, `requested_selection_rule`, `ignored_tie_breakers`, `ignored_policy_input`, `policy_warnings`, and `action`) instead of treating it as an opaque object.
- Each resolution recommendation now carries the effective selection rule, priority fields, tie breakers, unsupported requested rule, ignored tie breakers/input, and policy warnings through operator-review and Cadence-import rows.
- Resource and link-capacity constraints now expose explicit planning-grade warning/fail rows for operator review.

## Later

Richer candidate activity types, payload constraints, link budgets, and multi-objective timeline selection.

## Out of scope

Auto-importing or approving schedules in Cadence.
