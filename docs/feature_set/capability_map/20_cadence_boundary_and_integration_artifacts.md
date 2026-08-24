# 20. Cadence Boundary and Integration Artifacts

Status: **implemented** (with a **partial** semantic-depth area, plus **near-term**, **later**, and **out of scope** markers below).

## Implemented

### Core artifacts and contracts

- V1 proposed contacts and planned activities are implemented.
- V1 proposed contacts carry explicit direction, estimated throughput, source-window lineage, contact intents, and Cadence import IDs.
- Executable contracts validate V1 campaign, V2 repair, and V3 strategy artifacts, plus the following standalone contracts:
  - `planned_activity.v1`, `proposed_contact.v1`, `contact_intent.v1`
  - `resource_summary.v1`, `realized_activity.v1`, `realized_state_snapshot.v1`
  - `plan_delta.v1`, `approval_requirement.v1`, `policy_decision.v1`, `policy_bundle.v1`
  - `operator_review_package.v1`, `strategy_recommendation.v1`
  - `maneuver_recommendation.v1`, `maneuver_review_report.v1`, `branch_comparison_report.v1`
  - `optimizer_contract.v1`, `link_capacity_report.v1`, `contact_allocation_report.v1`, `contact_filter_report.v1`
  - `station_calendar_provider.v1`, `station_calendar_report.v1`
  - `environment_model_capability.v1`, `environment_provider_capability.v1`
  - `constraint_report.v1`, `command_window_report.v1`, `timeline_diff_report.v1`
  - `score_term_report.v1`, `schema_validation_report.v1` rows

### Operator review and Cadence import capability boundaries

- Executable validation and JSON Schema export check `operator_review_package.v1` package-level `model_limits` against `OrbitalDynamics.OperatorReview.capabilities/0`, keeping the Cadence review surface tied to the artifact-only no-mutation boundary and advertising the provider-result map keys flattened into schema-safe review rows.
- Executable validation and JSON Schema export check `cadence_import_manifest.v1` `model_limits` against `OrbitalDynamics.CadenceImport.capability/0`, keeping adapter handoff manifests tied to the no-write/no-approval boundary and advertising the provider-result map keys flattened into schema-safe import rows.
- Operator review and Cadence import capability metadata also advertise the schema-validation and operational-readiness handoff row semantics used for:
  - issue/remediation context
  - nested batch report context
  - readiness summary and gate rows
  - resource-availability gate context
  - Cadence-import gate context

### V3 Cadence consumer dry-run conformance

- `OrbitalDynamics.CadenceImport.dry_run/3` and the opt-in
  `OrbitalDynamics.CadenceImport.bounded_dry_run/4` accept either a validated
  `campaign_strategy.v3` artifact with its bound embedded manifest or that
  validated `cadence_import_manifest.v1` directly. Neither path rebuilds the
  strategy, chooses a recommendation, or rereads ambient configuration.
- The handwritten `OrbitalDynamics.CadenceImport.Adapter` contract exposes
  only `capabilities/0` and `dry_run/2`. Its exact capability surface permits
  only `dry_run` and declares `writes: false`; it has no create, update, write,
  mutation, approval, or execution callback.
- Source artifact type, source artifact identity, manifest identity, and
  presence-sensitive immutable authority context/evaluation evidence are
  checked before delegation and must be echoed unchanged by the adapter.
- Successful evaluations return a compact typed conformance record with a
  deterministic semantic manifest digest, request idempotency identity, and
  semantic-output digest. Repeating the same manifest, adapter, and normalized
  adapter options yields the same semantic result and identity. The bounded
  lifecycle timeout is control metadata, not an adapter option: successful
  synchronous and bounded calls therefore produce identical semantic requests,
  results, and idempotency identities.
- Malformed or unsupported inputs, source/authority drift, unsupported adapter
  capabilities, adapter errors, exceptions, exits/throws, and invalid adapter
  returns are contained as typed errors. Adapter controls and acknowledgements
  plus each delegated manifest row pass the existing bounded JSON-safety
  checks. Before schema inference or extraction, the entire outer input also
  passes a Domain 20 admission gate: at most 64 MiB external term size, 64
  top-level fields, 64 campaign branches, 4,096 rows in each known manifest,
  operator-review, or score-term collection, 2,048 fields in each segmented
  map, and 16,384 total segment-validation work items. Known large V3
  collections are checked as bounded envelopes and per-entry segments;
  additive unknown fields retain the generic JSON-safety limits, including the
  2,048-item collection limit. Structural and segmented checks precede the
  external-size calculation, while every admission check still precedes schema
  inference and extraction. Adapter option lists are collected once with an
  incremental duplicate/shape check and a fixed 2,048-entry cap before their
  bounded string-key map is passed to JSON-safety validation.
- `dry_run/3` remains the compatibility path: both callbacks execute
  synchronously in the caller process and therefore require a trusted adapter.
  Its option normalization, typed callback errors, and semantic identities are
  unchanged.
- `bounded_dry_run/4` requires a separate lifecycle option list containing
  exactly one positive integer `timeout` in milliseconds. It validates that
  option before delegation, then gives `capabilities/0` and `dry_run/2` one
  shared monotonic deadline. Each callback runs in a monitored direct worker
  under a separate lifecycle controller. That controller monitors both the
  original caller and direct worker; an independent guardian monitors caller,
  controller, and worker. Deadline expiry, caller cancellation, worker
  result/death, or controller shutdown kills and drains the direct worker
  (including a direct worker trapping exits), flushes monitor/result messages,
  and terminates the controller and guardian. A result at or after the deadline
  cannot later satisfy the call. Capability and dry-run timeout, exception,
  throw, exit, monitored-worker-death, and controller-death outcomes fail closed
  with distinct typed errors; the caller survives callback failures.
- Bounded execution is direct callback process-lifecycle containment only. It
  is not a malicious-code sandbox, does not guarantee containment of adapter
  descendants (including descendants that trap exits) or ambient/arbitrary
  side effects, and does not turn the declared no-write capability into enforced
  write isolation or write authority.
- This boundary defines producer-side conformance only. The repository supplies
  no live Cadence consumer or API client, database writer, mutation
  implementation, or evidence of acceptance by a downstream Cadence consumer.

### Operational readiness classification

- `operational_readiness_report.v1` classifies existing review/import handoff evidence as importable, review-only, analysis-only, or blocked without approving, writing, or executing anything.
- It preserves structured operational-mode gate evidence for supported analysis-only modes from options, artifact metadata, or direct artifact assumptions.
- That classification plus gate/evidence counts are preserved through:
  - capability-published `operational_readiness_review` rows
  - `review_operational_readiness` Cadence import rows
  - top-level operator-review packages and Cadence import manifests derived
    directly from `operational_readiness_report.v1`
  - exposed alongside the public `OrbitalDynamics.operational_readiness_report/2` facade
- `campaign_repair.v2` declares optional source readiness and quality-gate
  reports as direct nested contracts, applies their complete standalone
  validators, and reconciles the quality-gate source report ID/type/identity to
  its paired operational-readiness report. The checked repair handoff uses the
  current artifact-only models, exact no-authority limits, row-derived counts,
  and explicit review-gate rows rather than legacy partial report shapes.

**Readiness facades.**

- `OrbitalDynamics.operational_import_eligibility/2` publishes the validated `operational_import_eligibility_summary.v1` no-write/no-authority eligibility summary with row-derived gate counts and the same non-passed gate evidence, for adapters that do not need the full report.
- CandidateRefresh accepts direct, accepted-state, mission-state, and result-artifact-wrapped `operational_import_eligibility_summary.v1` handoffs as operational-readiness provenance, preserving source-summary identity, import eligibility counts, readiness/import/status routing, gate counts, non-passed gate evidence, wrapper-qualified paths, trust boundaries, and artifact-only no-import/no-write/no-operator-authority assumptions without reopening full readiness reports.
- `OrbitalDynamics.operational_readiness_gate_summary/2` publishes the validated `operational_readiness_gate_summary.v1` contract with deterministic gate counts and gate-ID maps by status/classification for queue routing without granting import authority. V3 branch events prefer row-local `non_passed_gates` status for review/analysis/blocked/non-passed gate ID routing when compact summary fields disagree.
- CandidateRefresh accepts direct, accepted-state, mission-state, and result-artifact-wrapped `operational_readiness_gate_summary.v1` handoffs as operational-readiness provenance, preserving source-summary identity, gate counts, status/classification maps, passed/review/analysis/blocked/non-passed gate IDs, wrapper-qualified paths, trust boundaries, and artifact-only no-import/no-write/no-operator-authority assumptions without reopening full readiness reports. When compact `non_passed_gates` rows include statuses, CandidateRefresh derives review/analysis/blocked/non-passed gate ID routing from those rows rather than stale summary-level ID lists.
- `OrbitalDynamics.operational_execution_boundary_summary/2` publishes the validated `operational_execution_boundary_summary.v1` contract over the readiness report's execution boundary as a compact handoff-only summary that:
  - derives gate counts from rows
  - preserves analysis-mode evidence
  - normalizes artifact not-for-execution markers from root fields, metadata, and assumptions, plus capability-published analysis-mode aliases such as `sim`, `tradeoff`, `no execution`, and `not for ops` for case/whitespace/separators
  - preserves whether the not-for-execution marker came from the root artifact, metadata, or assumptions
  - denies command execution, Cadence writes, and operator authority
- CandidateRefresh accepts direct, accepted-state, mission-state, and result-artifact-wrapped `operational_execution_boundary_summary.v1` handoffs as operational-readiness provenance, preserving source-summary identity, execution boundary, handoff-only status, execution/write/authority denial counts, analysis-mode routing, gate counts, non-passed gate evidence, wrapper-qualified paths, trust boundaries, and artifact-only no-execution/no-import/no-write/no-operator-authority assumptions without reopening full readiness reports.
- `OrbitalDynamics.operational_quality_gate_report/2` emits a standalone `quality_gate_report.v1` with deterministic row-level gate evidence and row-derived readiness classification/status, status/classification counts, gate ID maps, and explicit handoff-only/no-execution/no-write/no-authority boundary fields, plus a row-derived `execution_boundary` value for adapters that need a stable gate artifact. Existing `quality_gate_report.v1` artifacts are accepted as idempotent handoff inputs when queues already hold the compact gate artifact.
- `OrbitalDynamics.operational_quality_gate_summary/2` publishes the validated `operational_quality_gate_summary.v1` contract over the standalone quality-gate rows as a compact triage summary with row-derived status/classification counts, gate IDs, quality-gate row IDs, and non-passed rows without granting import, execution, write, or operator authority.
- Operator-review packages and Cadence import manifests derived from `quality_gate_report.v1` preserve the same gate counts, status/classification count maps, gate-ID maps, quality-gate row-ID maps, and passed/review/analysis/blocked gate ID sets as top-level adapter fields for import-readiness routing.
- V1 `campaign_plan.v1` artifacts attach `operational_readiness_report.v1` and `quality_gate_report.v1` derived from their own operator-review package and Cadence import manifest. These nested reports classify the campaign handoff as importable, review-only, analysis-only, or blocked while preserving the artifact-only boundary: they do not write Cadence state, execute commands, approve operator actions, or mutate the schedule.

**Readiness capability metadata and gate expansion.**

- Capability metadata advertises the readiness evidence count maps and quality-gate row contexts for freshness, schema validation, policy, adapter-boundary, Cadence-import, and resource-availability routing.
- Non-passed readiness gates are expanded into deterministic review/import rows so blocked, review-required, and analysis-only gates can be routed independently. Analysis-only quality-gate rows preserve the no-execution boundary as `not_required` / `not_applicable` handoffs rather than implying operator approval or Cadence import readiness.
- Resource-availability readiness gates lift pressure counts, reason counts, reason IDs, and unavailable-resource reason IDs directly onto those handoff rows.
- Resource-availability quality-gate summaries publish the validated `operational_quality_gate_unavailable_resource_summary.v1` contract, and quality-gate/review/import rows also carry
  resource-blocked contact IDs by blocking dimension and spacecraft for
  unavailable-resource queue routing.
- CandidateRefresh accepts compact
  `operational_quality_gate_unavailable_resource_summary.v1` handoffs as
  quality-gate source-report provenance from direct, accepted-state,
  mission-state, and wrapped result-artifact inputs, preserving unavailable
  resource reason counts, station reason IDs, blocked contact routing maps,
  quality-gate row IDs, and no-authority evidence without replaying refresh
  generation. Reconstructed generic quality-gate row counts come from
  `quality_gate_row_ids_by_status` when present, while resource-specific
  pressure and blocked-contact maps remain compact-summary evidence.
- Cadence-import readiness gates lift import-status, freshness, and schema-validation count maps onto quality-gate, review, and import rows for adapter routing.
- Quality-gate schema-validation summaries publish the validated
  `operational_quality_gate_schema_validation_summary.v1` contract and expose
  pass/fail and issue counts, blocked/failed quality-gate row IDs,
  status-grouped gate IDs, and no-authority assumptions so adapter queues can
  route schema blockers without reopening the full readiness report.
- CandidateRefresh accepts compact
  `operational_quality_gate_schema_validation_summary.v1` handoffs as
  quality-gate source-report provenance from direct, accepted-state,
  mission-state, and wrapped result-artifact inputs, preserving schema status
  maps, schema-validation status IDs, failed quality-gate row IDs,
  schema-validation gate IDs, and no-authority evidence without replaying
  refresh generation. Reconstructed
  generic quality-gate row counts come from `quality_gate_row_ids_by_status`
  when present, so stale compact schema-validation row counts cannot inflate
  branch-local quality-gate pressure.
- Quality-gate import-readiness summaries publish the validated
  `operational_quality_gate_import_readiness_summary.v1` contract and expose
  freshness status maps and status IDs, import-status maps and status IDs,
  Cadence-import status maps and status IDs, stale/unknown freshness row IDs,
  import-preparation row IDs, and blocked import row IDs from the same
  `cadence_import` quality-gate rows. Standalone analysis-only cadence-import
  rows are routed through explicit
  `analysis_only_quality_gate_row_ids` without making them import-ready.
- CandidateRefresh accepts compact
  `operational_quality_gate_import_readiness_summary.v1` handoffs as
  quality-gate source-report provenance from direct, accepted-state,
  mission-state, and wrapped result-artifact inputs, preserving freshness,
  import-status, and Cadence-import status-ID routing alongside reconstructed
  generic gate status, ready/review/analysis/blocked row routing, and row
  counts from `quality_gate_row_ids_by_status` when present instead of stale
  top-level routing arrays.
- CandidateRefresh accepts compact `operational_quality_gate_summary.v1`
  handoffs as quality-gate source-report provenance from direct, accepted-state,
  mission-state, and wrapped result-artifact inputs, preserving status,
  classification, status-grouped and classification-grouped gate-ID and
  quality-gate-row-ID maps, non-passed gate counts and ID lists, and
  no-authority evidence without replaying refresh generation or granting import
  authority. For compact no-row handoffs, reconstructed readiness/status/
  classification, generic gate counts, classification routing, and non-passed
  routing come from `quality_gate_row_ids_by_status` / `gate_ids_by_status`
  when present instead of stale top-level summary fields.
- CandidateRefresh build applies a blocked quality-gate report to selection only
  when its canonical source type is `planned_activity.v1` and its non-empty
  `source_artifact_id` exactly matches one regenerated candidate. The resulting
  candidate-rejection evidence preserves source report/summary identity, input
  path, exact candidate scope, and trust boundary for review/import routing.
  Generic compact summaries, nonmatching reports, and non-blocked gates remain
  provenance-only, and no Cadence write, approval, or execution authority is
  granted.
- CandidateRefresh applies the symmetric rule to a schema-valid blocked
  `operational_readiness_report.v1` only when its source type is
  `planned_activity.v1` and its non-empty `source_artifact_id` exactly matches
  the regenerated candidate. It preserves distinct readiness report identity,
  path, blocked status, exact scope, and trust evidence in the existing
  candidate-rejection review/import path. Compact readiness summaries,
  malformed reports, wrong-type or nonmatching source identity, and nonblocked
  reports remain provenance-only, without Cadence write, approval, or execution
  authority.
- Quality-gate operator-training summaries publish the validated `operational_quality_gate_operator_training_summary.v1` contract and expose role, training,
  certification, and qualification routing from `operator_training`
  quality-gate rows, including status/classification row IDs and explicit
  no-authority/no-write assumptions.
- CandidateRefresh reconstructs generic quality-gate row counts for compact
  `operational_quality_gate_operator_training_summary.v1` handoffs from
  `quality_gate_row_ids_by_status` when present, while preserving
  operator-training requirement and role/training/certification/qualification
  evidence from the compact summary.
- CandidateRefresh accepts compact
  `operational_quality_gate_operator_training_summary.v1` handoffs as
  quality-gate source-report provenance from direct, accepted-state,
  mission-state, and wrapped result-artifact inputs, preserving required roles,
  training IDs, certification IDs, qualification IDs, operator-training gate
  IDs, review-only row IDs, and no-authority evidence without replaying refresh
  generation.

**Readiness evidence preservation and fail-closed rules.**

- Direct readiness classification of boolean-gated source artifacts preserves `reviewable` evidence while deriving candidate-rejection and provider-counteroffer review/import rows, so operator-review-required handoffs remain review-only rather than being downgraded to analysis-only.
- Readiness evidence preserves current/stale/unknown freshness status counts when freshness reports or freshness review/import rows are present.
- Readiness evidence preserves pass/fail schema-validation status plus error, warning, and remediation evidence counts when schema-validation reports or review/import rows are present.
- Otherwise, ready import evidence fails closed when those source rows report stale/unknown freshness or failed schema validation: requiring review for stale/unknown freshness and blocking failed schema validation.
- Adapter-shaped import rows require a declared trust boundary before staying import-eligible.
- Readiness evidence preserves source model, model-limit, mission-policy classification, review-type, import-action, source-review-type, and adapter-boundary status count maps from direct source artifacts and review/import rows, so contact-allocation, resource-projection, and policy-authority readiness gates remain traceable to their exact adapter routing families.
- Adapter-shaped rows with missing trust boundaries require review, while explicitly unknown or untrusted trust-boundary evidence blocks import eligibility and flows into quality-gate/review/import handoff context.
- Executable validation rejects negative readiness evidence count-map values to match the exported JSON Schema contract.

**Readiness policy and resource gates.**

- Readiness reports include an optional `mission_policy` gate when preserved policy decisions are present, requiring review for `operator_review_required` policy evidence and blocking import eligibility for `blocked_by_policy`.
- Cadence import and contact-allocation ground-station reserved, unavailable, zero-capacity, or reduced-capacity allocation reasons feed the same readiness `resource_availability` gate and quality-gate/review/import handoff context before import eligibility is reported.

### Candidate rejection ingress

- Cadence import accepts `candidate_rejection_report.v1` as a supported artifact-only source, lifting reviewable rejected candidates into:
  - `candidate_rejection_review` operator-review rows
  - `review_candidate_rejection` import rows
- These rows carry candidate/activity/timeline identity, rejection reasons, margin evidence, and source row context, including when the report is embedded in a `candidate_refresh.v1` artifact.
- Cadence import `import_action`, `import_status`, `cadence_import_status`, and `source_review_type` fields are capability-backed and schema-constrained for row import actions, row import statuses, flattened review-type fields, and embedded source review rows.
- Source review queue keys are validated against their review type, queue, and approval status.

### Maneuver review and import

- Result-set artifacts expose maneuver recommendation rows extracted from trajectory assumptions plus `maneuver_review_report.v1` review/import tables without command execution.
- Maneuver review reports can be normalized into `operator_review_package.v1` `maneuver_review` rows and typed `review_maneuver` Cadence import gates for artifact-only burn review/import queues.
- Supplying an approval policy classifies maneuver-review rows with `approval_requirements`, approval-rule matches, and `policy_decision.v1` evidence plus matched escalation level, queue, role, authority, and SLA metadata, with maneuver and uncertainty count evidence bounded as non-negative integers, so `maneuver_authority_v1` can be applied directly to standalone burn review tables.
- Standalone `maneuver_recommendation.v1` rows can also flow directly through `OrbitalDynamics.operator_review_package/1` and `OrbitalDynamics.cadence_import_manifest/2` into the same `maneuver_review` / `review_maneuver` gates.
- Result-artifact wrappers prefer an embedded `maneuver_review_report.v1` row when both the review report and its source `maneuver_recommendations` are present, so generated result-set artifacts do not double-queue the same burn for Cadence review/import.

**Malformed and uncertainty handling.**

- Malformed recommendation rows inside a maneuver-review input list are review-gated as `review_invalid_maneuver_recommendation` with source evidence instead of aborting report generation.
- Malformed optional execution-uncertainty or maneuver-success confidence metadata is preserved as invalid recommendation source evidence instead of leaking invalid typed fields into review/import rows.
- Invalid maneuver recommendations can also carry explicit `maneuver_authority_v1` rule-match evidence through operator-review and Cadence-import rows.
- Declared maneuver execution uncertainty is preserved as review metadata and surfaced to policy context without modeling burn execution.
- Maneuver review rows preserve `maneuver_success_factor` and source labels through approval-policy context, operator-review rows, and Cadence import gates so confidence-threshold policy rules can classify standalone burn reviews.
- Clean numeric-string maneuver recommendation epoch, delta-v, confidence, and execution-uncertainty values normalize before review-policy classification, while malformed numeric maneuver metadata remains on the invalid recommendation review path.

### Exported schemas for contact intent and proposed contact

- The exported `contact_intent.v1` JSON Schema includes optional Cadence import, contact metadata, timeline identity lineage, approval requirements, approval rule matches, `policy_decision.v1`, and `model_limits` fields without making them required.
- `proposed_contact.v1` constrains optional standalone `model_limits`, source-window ID, timeline identity, station availability, and schedule-conflict status through executable validation and exported JSON Schema.
- Proposed-contact Cadence import rows preserve station-calendar trust/source evidence so initial schedule-import handoff can distinguish declared provider state from missing-boundary station data without reopening nested reports.
- Standalone planned-activity operational-timeline review/import rows preserve the same station-calendar overlap, reservation, trust-boundary, and source provider evidence for command/contact timeline queues.

### V1 campaign artifacts: optimizer and link capacity

- V1 campaign artifacts include `optimizer_contract.v1` rows for the selected greedy ranking model.
- V1 campaign artifacts include `link_capacity_report.v1` rows for fixed-rate downlink capacity and capacity-adjusted throughput, including `planned_contact` rows whose direction is `downlink`, and optional fixed downlink requirement shortfall evidence.
- Per-contact `required_downlink_mb` fallback demand is traced by required-contact IDs, with matched realized-throughput completion ratios against declared demand.
- Link-capacity contact ingress parses clean numeric-string timing aliases, throughput/data-volume aliases, capacity fractions, completion fractions, and top-level or metadata-supplied trimmed case-insensitive contact/command feedback booleans and confidence factors before fixed-rate summary, policy matching, and selected actual-throughput reconciliation.
- V1 campaign embedded link-capacity rows are lifted into top-level `link_capacity_review` and Cadence `review_link_capacity` queues with campaign-source provenance, policy evidence, and ignored-contact reason-count maps.
- V3 branch repair embedded link-capacity rows are likewise lifted into `link_capacity_review` and Cadence `review_link_capacity` gates while preserving the `branch_id` provenance.
- V1 campaign downlink-completion data-volume objectives and V2 repair mission-state downlink objectives feed embedded link-capacity requirements unless explicit policy overrides them, without claiming a link-budget model.

### V1 campaign artifacts: allocation and objective satisfaction

- `contact_allocation_report.v1` rows handle allocated/deferred/blocked contact handoff without claiming provider reservation authority.
- `objective_satisfaction_report.v1` rows report selected objective status.
- Partial/unmet/no-candidate objective rows lift into V1 campaign `objective_satisfaction_review` and Cadence `review_objective_satisfaction` queues with campaign-source provenance.

### Operator review package normalization (V1, V2, V3)

V1, V2, and V3 artifacts emit `operator_review_package.v1` rows that normalize raw inputs into a stable artifact-only import surface. Normalized inputs:

- station-contention groups, station-contention recommendations
- command-window reviews, station-calendar reviews, link-capacity reviews
- contact-allocation reviews, refresh-budget reviews, resource-projection reviews
- approval requirements, policy escalation summaries
- V3 branch repair constraint and operational timeline reviews
- contact suppression rows from contact filters
- score terms and objective tradeoffs from V3 branch repair results
- resource suppression rows from campaign resource filters
- warnings, risk explanations, strategy recommendations, strategy tradeoffs
- maneuver reviews, timeline diff reviews
- V2 plan-delta reviews with timeline identity/context
- realized feedback review rows with source planned/realized activity context and realized provider/import provenance

The import surface carries row-derived review-type, approval-status, required-action, deterministic review-queue, review-row-ID, and Cadence-import-status count maps, exported as non-negative JSON Schema count maps with canonical enum keys for review type and Cadence import status, plus open count maps for approval, action, row-ID, and queue routing.

**Validation.** Executable validation checks scalar review totals against package rows while enforcing as integers (matching the exported JSON Schema) the rank/count evidence for:

- operator-review package and operator-review row rank/count evidence
- operational-timeline, timeline-diff, operational/timeline-diff row count fields and diff ranks
- command-window, station-calendar, maneuver-review, objective-satisfaction
- ranking-comparison, Pareto-frontier, constraint, score-term, link-capacity
- contact-filter, contact-contention, contact-allocation, resource-filter, resource-projection
- Cadence import manifest scalar/count-map and row rank/count evidence values

Selected timeline integrity issue counts, branch-event counts, and embedded branch-comparison target/revisit counts are bounded as non-negative row evidence in review/import handoffs.

### Cadence import manifest (V2 and V1)

- V2 `cadence_import_manifest.v1` turns repaired operator-review rows into deterministic, review-gated adapter actions with ready, review-required, and missing-import status counts exported and validated as non-negative integers.
- `campaign_repair.v2` declares that manifest as an optional direct nested
  contract and applies its complete standalone validator at runtime. A present
  manifest must identify the containing repair, name
  `operator_review_package.rows` as its source, preserve the package review
  count in both manifest and provenance, and retain the review row IDs in
  source order.
- It includes reported and row-derived import-action, import-status, Cadence-import-status, source-review, import-side, and row-ID routing maps exported as non-negative JSON Schema count maps with canonical enum keys, plus open non-negative source review action/queue count maps preserved from operator-review rows.
- The public manifest/review facades reject non-map or unsupported artifact-contract inputs with explicit adapter-boundary errors that list supported contracts instead of leaking function-clause failures.
- Already-built operator-review packages and Cadence import manifests pass through their public facades as stable artifacts, with atom-key manifests normalized to the string-key JSON shape.
- V1 campaign plans emit the same manifest contract over proposed contacts plus embedded contention-group, operational-timeline, and contact-allocation review rows, including effective allocation status for policy-blocked selections, with ready, review-required, and missing-import status counts plus the same row-derived summary maps.
- `campaign_plan.v1` declares that manifest as an optional direct nested
  contract and applies the standalone manifest/row/count/model-limit validator
  at runtime. The embedded handoff must name `campaign_plan.v1` and the
  containing plan ID as its source; declared no-write/no-approval assumption
  values remain validated.

**Import status vocabularies.**

- Operator-review packages and Cadence import manifests advertise import and Cadence-import status vocabularies through their capability surfaces.
- Executable/schema validation constrains row-level `cadence_import_status` handoff fields to present/missing/invalid/not-applicable values.
- Exported Cadence import schemas constrain top-level `source_artifact_type` to the capability-advertised supported source contracts, and executable validation rejects unsupported manifest source artifact types.
- Operator-review packages expose row-derived source/replacement Cadence-import status counts.
- Package and manifest generation normalizes unsupported upstream Cadence-import status values into invalid, review-required rows that preserve the raw provider value and clear matching operator-review presence flags, instead of treating arbitrary provider statuses as ready for import.

### V3 strategy artifacts

- V3 strategy artifacts emit selected-branch recommendation import rows, non-selected branch alternative-review rows from branch comparisons, and generic review-gated rows from the strategy operator-review package, including branch-scoped refresh-budget gates from generated branch repair.
- Selected strategy recommendation review/import rows aggregate risk-driver direction plus station-calendar entry and direction context from remaining branch risks so Cadence adapters can route pressure reviews without reopening branch risk arrays.
- Strategy import provenance records whether the operator-review package was embedded or derived and reports the derived review count even when the source strategy artifact omitted the embedded package.

### Review queues and row identity

- Operator-review rows carry deterministic `review_queue` and `review_queue_key` fields derived from review type, required action, and approval status, and package/import manifests expose row-derived queue-count maps so downstream adapters can route without reparsing generic row payloads.
- Generic and plan-delta Cadence import review rows preserve row-level target IDs alongside station, spacecraft, branch, scenario, and source-window identifiers.
- Contact-intent, operational-timeline, plus generic review rows derive `has_cadence_import` from explicit source-row import identity when the source review row omits the presence flag.

### Contact allocation review rows

Contact allocation reports emit typed `review_contact_allocation` manifest rows with:

- allocation state, selected/deferred contact IDs
- station contention context, source suppression, policy evidence
- matched escalation routing fields
- contact/command feedback evidence
- actual-throughput evidence when present on realized blocked rows
- `source_contact_allocation` context

### Timeline feedback rows

- Timeline feedback reports emit realized-feedback record/review rows with timeline-match, planned timeline identity, dependency/exclusivity, and realized-activity correlation context, plus planned-vs-realized direction, ground-station, and source-window match status, so completed feedback on the wrong contact identity remains review-gated.
- Malformed realized `cadence_import` context is preserved as invalid import review evidence before import-manifest handoff.
- Realized resource telemetry lifts onto timeline-feedback rows: spacecraft ID; fuel/power/storage/downlink margins; battery state-of-charge; battery capacity and energy-used fields; availability booleans; degraded/mode status; and incompatible/suppressed activity-type lists. These fields are preserved through operator-review and Cadence-import rows, normalizing top-level or metadata-supplied trimmed case-insensitive JSON-style availability/degraded booleans and preserving explicit `false` availability values.
- Timeline-feedback maneuver rows also preserve declared execution-uncertainty review metadata and derived timing/delta-v 3-sigma fields through operator-review and Cadence-import rows.

### Operational timeline rows

- Operational timeline reports emit review-gated rows for command/contact timeline actions, approval review, conflict resolution, and missing Cadence import preparation.
- Cadence import manifests preserve those as typed `review_operational_timeline` rows with `source_operational_timeline` context and:
  - row-level spacecraft/product/collection/payload/instrument identity
  - product lists, planned/actual throughput, estimated/required downlink demand, data-volume evidence
  - Cadence import provider/adapter/trust provenance
  - score terms and target priority
  - matched policy-escalation routing metadata when policy evidence is present
  - command/contact, observation, and maneuver feedback evidence
  - full Cadence import identity when declared
- Standalone proposed-contact import manifests preserve malformed non-object `cadence_import` context as invalid import evidence instead of crashing the direct import path.

### Timeline diff and timeline protection rows

- Timeline-diff reports emit typed `review_timeline_diff` manifest rows with source/replacement timeline identities, transition fields, changed fields, activity context, source diff context, and transition-level operator-review recommendation metadata, preserving source/replacement and selected self-dependency evidence separately from missing-dependency evidence, with nested protection-decision payloads typed for stable IDs, lifecycle status, lock/approval flags, timeline identity, decision, category, and reason.
- Timeline-protection rows emit typed `review_timeline_protection` manifest rows with protection category, protection decision, and source protection summary context.

### Contention, command-window, and standalone review rows

- Station-contention group and resolution reports emit review-gated contention rows.
- Command-window and station-calendar reports emit review-gated adapter rows, with command-window and station-calendar rows preserving matched policy escalation routing fields for review queues.
- Standalone contact-filter, resource-filter, maneuver-review, timeline-diff, approval-requirement, branch-comparison, and ranking-comparison reports emit review manifest rows with `source_review_row` preserved for adapter handoff.

### Link capacity review rows

Link-capacity reports emit typed `review_link_capacity` manifest rows with:

- throughput rollups, selected-contact IDs
- declared downlink requirement shortfalls
- actual delivered throughput shortfalls when present
- per-contact required-demand trace IDs
- policy evidence, matched escalation routing fields
- `source_link_capacity` context

### Resource projection review rows

- Resource-projection reports emit typed `review_resource_projection` manifest rows with resource-pressure rollups and `source_resource_projection` context.
- V1 campaign artifacts expose embedded `resource_projection_report.v1` rows through that same review/import path with campaign-source provenance.
- Resource-pressure approval requirements and rule matches plus matched policy-escalation routing fields are preserved on those review/import rows when policy classified the projection.

### Policy escalation review rows

- Policy-decision reports emit typed `review_policy_escalation` manifest rows with queue, role, required authority, SLA, source escalation, and source decision context, plus flattened policy-bundle provenance source, adapter, organization, and policy-source fields.

### Other inputs

- V2 approval requirements and plan deltas.
- V3 strategy recommendation explanations, ranked branch IDs, approval-status enums, numeric strategy-policy weights, tradeoff rows, risks, approval requirements, branch-comparison rows, approval status, warnings, and realized-state input shape.

## Partial

Status note: artifact contracts are now executable, and V1/V2/V3 plus candidate-refresh, timeline-feedback, operational-timeline, contact-contention, command-window, station-calendar, and remaining generic operator-review reports emit formal Cadence import manifests for proposed-contact, repaired plan-delta, strategy-branch-recommendation, embedded operational-timeline, realized-feedback, refreshed contact-intent, refreshed allocation/filter, station-contention, command-window, station-calendar, and generic review adapter rows.

**The remaining partial area is calibrated behavior and semantic depth rather than adapter row coverage.**

### Contention and operator-review coverage

- Standalone exported contact-contention contracts and operator-review packages now cover:
  - station-contention groups and standalone or campaign-embedded recommendations
  - command-window review rows, station-calendar review rows
  - warnings, approval requirements, policy escalation rows
  - contact suppression rows, resource suppression rows
  - risk explanations, strategy recommendations with operational-feedback provenance context
  - maneuver review rows, timeline diff review rows
  - realized feedback rows from `timeline_feedback_report.v1` with command/contact success, provider contact/command result fields, throughput delta fields, planned timeline identity, dependency/exclusivity arrays, duplicate realized feedback evidence, planned-vs-realized direction/station/source-window match status, and source planned/realized activity context

### Branch comparison normalization

- Standalone `branch_comparison_report.v1` rows can be normalized into strategy-tradeoff review rows with branch risk counts, typed/high-risk summaries, first resource-pressure status/type, activity, station, calendar, and direction context, repair score-term, and repaired link-capacity context (including required downlink volume, selected shortfall, and requirement status).
- Cadence import strategy branch/tradeoff rows preserve the same top-level evidence.

### Contact and resource suppression

- Standalone `contact_filter_report.v1` and `resource_filter_report.v1` artifacts can be normalized into contact- and resource-suppression review rows without a campaign wrapper.
- Cadence import manifests preserve those suppression rows as typed adapter gates with source suppression context, policy evidence, station reservation fields, contact/command feedback evidence, and thin resource availability fields, including:
  - clean numeric-string resource summary values, policy thresholds, and candidate timing aliases normalized before suppression
  - duplicate suppressed-candidate identity metadata
- Planned-contact downlink suppressions stay on the `review_suppressed_contact` action path.

### Standalone link capacity

- Standalone `link_capacity_report.v1` artifacts can be normalized into `link_capacity_review` rows with selected-contact and fixed-rate capacity-adjusted throughput summaries, plus declared downlink requirement shortfalls, actual delivered throughput shortfalls when present, and per-contact required-demand trace IDs.
- Cadence import manifests preserve link-capacity rows as typed `review_link_capacity` adapter gates with throughput rollups, selected-contact IDs, requirement status, policy evidence, top-level or metadata-supplied feedback evidence, ignored-contact reason counts, and `source_link_capacity` context.
- V1 campaign artifacts expose embedded link-capacity reports through the same review/import path with campaign-source provenance.

### Standalone resource projection

- Standalone `resource_projection_report.v1` artifacts can be normalized into `resource_projection_review` rows with:
  - per-spacecraft storage/downlink margins
  - projected storage overflow and downlink shortfall values
  - availability flags, resource source-quality labels
  - declared-vs-missing trust-boundary status
  - clean numeric-string summary/activity resource estimates normalized before roll-forward
  - trust-boundary status, source-row and review-row first resource-pressure activity fields
  - flow-row counts, peak overflow/shortfall values
  - typed approval requirements when policy classifies pressure rows
  - invalid selected-activity input evidence and invalid external resource-summary evidence when malformed rows cannot be safely projected
- Spacecraft-unavailable summaries produce `spacecraft_unavailable` pressure rows with zero projected activity effects and preserved review/import availability evidence.
- Standalone resource-filter and resource-projection inputs also accept top-level `activity_type` as the activity/candidate kind alias before invalid-input review gating, matching operational timeline row re-ingestion.
- V3 strategy and V1 campaign operator-review packages lift embedded resource projections into the same review row type with branch or campaign source paths.
- Cadence import manifests preserve resource-projection rows as typed `review_resource_projection` adapter gates with storage/downlink pressure rollups, projected remaining storage/downlink capacity, first pressure activity fields, source quality, trust-boundary status, warnings, and `source_resource_projection` context, including flattened thermal-margin, availability, and activity-type pressure rows that can replay into branch-local refresh without nested source context while preserving top-level source activity IDs, plus flow-summary total/minimum remaining-capacity context, policy-supplied approval requirements, rule matches, invalid-input source activity evidence, and invalid external resource-summary evidence.

### Standalone constraint reports

- Standalone `constraint_report.v1` artifacts can be normalized into `constraint_review` rows for failed and warning constraints.
- Cadence import manifests preserve those rows as typed `review_constraint` gates with scenario, metric, threshold, value/score, status, non-negative report count evidence, and source constraint row context.

### Standalone objective satisfaction

- Standalone `objective_satisfaction_report.v1` artifacts can be normalized into `objective_satisfaction_review` rows for partial, unmet, and no-candidate-window objectives.
- Cadence import manifests preserve those rows as typed `review_objective_satisfaction` gates with objective status, target/count/downlink evidence, non-negative row count bounds, selected IDs, source objective row context, and the report-level planned-summary `model_limits`.
- V1 campaign embedded objective-satisfaction reports use the same review/import surface with `campaign_plan.objective_satisfaction_report.rows` provenance.

### Standalone scoring reports

- Standalone `score_term_report.v1` and `objective_tradeoff_report.v1` artifacts can be normalized into scoring review rows.
- Cadence import manifests preserve those rows as typed `review_score_term` and `review_objective_tradeoff` gates with term values, selected status, score deltas, non-negative activity/contact count evidence, activity IDs, and source scoring rows.
- V1 campaign embedded scoring reports use the same review/import surface with campaign-source provenance.

### Standalone policy decisions

- Standalone `policy_decision.v1` artifacts can be normalized into policy-escalation review rows for authority-boundary queues.
- Cadence import manifests preserve those rows as typed `review_policy_escalation` adapter gates with queue, role, required authority, SLA, source escalation, source decision context, and flattened policy-bundle provenance source, adapter, organization, and policy-source fields for organization adapter routing.

### Schema-export compatibility coverage

Checked-in study-result fixtures with executable artifact contracts are covered by a schema-export compatibility test that fails when fixture fields are missing from top-level or `rows` JSON Schema properties, including:

- branch-comparison, operator-review, Cadence-import, and nested Cadence source-review row fields
- standalone strategy-recommendation top-level fields, tradeoffs, explanation rows, remaining risks, and approval rows
- standalone strategy-branch top-level fields, branch events, risk indicators, and tradeoffs
- operational-timeline and timeline-feedback dependency/exclusivity, protection, identity-match, and realized-provider handoff row fields
- command-window dependency/exclusivity plus approval context row fields

**Additional schema coverage.**

- Contact-allocation row schemas cover checked-in station-calendar overlay, reservation, contention, reduced-capacity, selected-contact, resource-suppression, and resource-trust fields.
- Link-capacity row schemas cover utilization, ignored/ambiguous/duplicate contact identity, and unused capacity evidence; the report-level schema exposes selected-utilization, downlink-shortfall, ignored/unmatched/ambiguous selected contact, duplicate-contact, and model-limit summary fields.
- Timeline-diff, objective-satisfaction, and maneuver-review row schemas expose activity/protection context, downlink satisfaction quantities, stable selected/candidate identity arrays, and execution-uncertainty status.
- Operational-timeline and timeline-diff report-level validation exposes and cross-checks status/action/changed-field count maps, dependency and exclusivity issue counts, duplicate timeline-identity counts, and model limits against their rows.
- Operator-review package schemas expose review type, queue, approval, action, Cadence-import status, and model-limit summaries and validate those count maps against review rows.
- Cadence import manifest schemas expose import action/status, Cadence-import status, source-review type/action/queue, and model-limit summary fields with row-derived validation for import handoff counts.
- Resource-filter report schemas expose invalid-candidate, duplicate-suppression, resource-source, and trust-boundary summary fields, with suppressed resource quality/trust maps validated against suppressed candidate rows.
- Resource-projection report schemas expose valid/invalid resource-summary and activity counts plus resource quality/trust maps, with row-derived validation for projected resource summaries.

### Nested source-report schema reuse

- Operator-review and Cadence-import row schemas reuse the nested `candidate_diff_report.v1`, `freshness_report.v1`, and `refresh_budget_report.v1` schemas for source report fields instead of exposing those handoff reports as opaque objects.
- Candidate-refresh operational-readiness source-report summaries lift into `operational_readiness_review` / `review_operational_readiness` handoff rows and preserve readiness review-type/import-action/source-review-type count maps plus resource-availability pressure counts, reason IDs/counts, unavailable-resource IDs, and blocking-dimension counts for resource gate rows in branch-local provenance and Cadence import rows, including when candidate-refresh reconstructs the source readiness report from branch-local operator-review or Cadence-import containers.
- Quality-gate unavailable-resource summaries expose the same row-derived reason
  counts, blocked contact IDs by blocking dimension/spacecraft/status, and
  quality-gate row-ID routing groups for adapter queues without reopening the
  full readiness report.
- Operational-readiness schemas expose adapter-boundary evidence counts for trust-boundary import eligibility.
- Reduced-capacity contact-allocation capacity-pack handoff rows expose `default_required_capacity_fraction` as an executable unit-interval field on operator-review rows, Cadence-import rows, and nested source review rows.

### Capability enum checks

- Operator-review capability review types are checked against the exported `operator_review_package.v1` row enum so runtime-supported rows such as `execution_review` remain schema-visible.
- Contact/resource filter capability suppression reasons are checked against the exported `suppressed_candidates[].suppressed_reason` enum so filter reports expose their triage vocabulary as machine-readable contract data, and optional suppressed-candidate `review_status` is constrained to `operator_review_required`.

### Standalone approval requirements

- Standalone `approval_requirement.v1` rows can be normalized into single-row approval review packages and typed `review_approval_requirement` Cadence import gates with `source_requirement`, activity-context, lifted routing-field preservation, and matched policy-escalation level, queue, role, authority, and SLA metadata, without executing approval workflow.

### Warning, risk, strategy, and comparison review rows

- Warning and risk-explanation review rows emit typed `review_warning` and `review_risk` Cadence import gates that preserve reason, severity, source path, branch/scenario identity, lifted activity or station routing context, station-calendar direction context, first resource-pressure context, and structured `source_risk` evidence when present.
- Strategy recommendation, strategy tradeoff, ranking-comparison, and Pareto-frontier review rows emit typed Cadence import gates that preserve source/reason context, recommended branch identity, ranked branch IDs, recommendation tradeoff/risk/approval counts, branch score deltas, left/right rank and value deltas, objective vectors, dominance links, and source comparison rows and operational-feedback provenance context instead of relying on generic row passthrough.

### Contact contention direction and station identity

- Contact-contention group and recommendation rows carry source-window IDs; downlink/uplink/command/tracking direction evidence; station-calendar provider IDs; provider entry IDs; overlap/reservation IDs; reservation owner/status lists; trust-boundary status lists; required action; approval status; and operator action reason through the contention contract, resolution recommendations, operator-review package, and Cadence import rows.
- Direct command, uplink, and tracking station windows now participate in artifact-only contention and allocation review; direction-only uplink rows normalize as planned contacts for allocation; and command/uplink station-calendar, command-window, link-capacity, contention, and allocation approval requirements use the command-review authority type without changing the downlink/tracking suppression boundary.

### Station-calendar provider evidence

- Station-calendar affected rows preserve the applied provider-calendar provider ID, provider entry ID, applied entry, and full overlapping provider-calendar entries through `station_calendar_report.v1`, operator-review rows, and Cadence import rows, so provider evidence remains inspectable without reconstructing it from entry IDs.
- The affected-row schema and executable validator type direction lists, feedback confidence factors, ambiguity/reservation overlap lists and counts, trust/provenance evidence, nested source entries, and overlaps for provider/entry/station/reservation IDs, availability/status, capacity fraction, reservation owner/status, timing, and ambiguous-entry summaries.
- Provider-shaped availability/status tokens are canonicalized for case, whitespace, and hyphen differences before those rows are validated or applied.
- Station-calendar review/import rows carry top-level provider IDs, provider-entry IDs, direction lists, ambiguous-entry summaries, matched policy escalation queue, role, required authority, SLA, and source escalation evidence for reserved, unavailable, or reduced-capacity station boundaries, plus the declared/missing trust-boundary status for the provider calendar row.

**Provider calendar contention groups.**

- Provider-calendar overlap groups expose artifact-only `provider_calendar_contention_groups` with typed entry/provider/reservation, trust-boundary, overlap-pair, and preserved source-entry evidence, and route them through station-calendar operator-review and Cadence-import rows as `review_station_provider_contention` without provider API calls, schedule mutation, reservations, or automatic conflict resolution.
- Contact-allocation reports that embed a station-calendar report lift those nested provider contention groups into the same operator-review and Cadence-import handoff rows so allocation review does not hide provider calendar conflicts when the allocation artifact is the reviewed boundary; V3 replay consumes those allocation-derived Cadence-import rows as branch-local station pressure while preserving the provider contention group as the feedback source.
- Approval-policy context selectors attach requirements, rule matches, policy decisions, and escalation routing metadata to those provider-calendar contention groups.
- V3 branch derivation can replay those provider-contention groups into branch-local candidate-refresh station events from their preserved source entries, keeping the provider contention group ID, entry IDs, reservation ownership/status, trust boundary, and overlap window attached as audit evidence even after operator-review and Cadence-import handoff rows are the only remaining source.

### Station-calendar provider entries and planned activity

- `station_calendar_provider.v1` entry schemas and executable validation expose scalar/list direction aliases plus entry-level trust/provenance so provider inputs can declare direction-scoped station state before overlay.
- Planned-activity operational-timeline review/import rows carry the same station-calendar trust/source evidence when supplied by the activity context.

### Command windows

- Command windows now have a typed `command_window_report.v1` artifact boundary with dependency/exclusivity lineage preserved into review and import rows.
- Provider-shaped reservation aliases are normalized into canonical station-reservation identity, owner, status, and match-status evidence before command-window policy/review/import routing, including:
  - nested `source_station_calendar_entry` reservation evidence that remains distinguishable as provider-overlap rather than owned reservation time
  - nested `source_station_calendar_overlaps` reservation lists that remain visible to approval-policy, review, and import consumers
- Command-window capacity context accepts provider percent aliases such as `capacity_percent`, `station_capacity_percent`, and nested throughput/capacity/activity context evidence.
- Validation fixtures observe row-derived command-window type, required-action, approval-status, Cadence-import-status, and required-action row-ID maps before import routing consumes the report (variants before policy/review/import handoff).

### Maneuver review boundary and provider scope

- Maneuver review tables now have a typed `maneuver_review_report.v1` boundary.
- Live provider adapters and provider-side conflict resolution remain outside the current artifact-only station-provider contention boundary.

## Near-term

Deepen calibrated policies behind the queue semantics, especially adapter- or mission-specific prioritization beyond deterministic routing keys.

## Later

An actual separately owned Cadence adapter package or service implementation
after consumer requirements mature beyond the handwritten no-write dry-run
contract.

## Out of scope

Direct Cadence database writes, Cadence API clients, operator UI, schedule approval, command execution, and contact execution.
