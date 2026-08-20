# 17. Reproducibility, Artifacts, and Audit

Status: **implemented** (core), with additional **implemented** refresh-feedback
work, a **partial** executable-schema track, and **near-term** / **later** /
**out of scope** items noted at the end.

## Manifests, runs, and result artifacts (implemented)

- JSON study manifests.
- Manifest SHA metadata.
- `StudyRun` metadata.
- Result-set artifacts.
- Campaign, repair, and strategy artifacts.
- Executable campaign and Cadence-facing row contracts through
  `OrbitalDynamics.Schema`.
- `mix orbital_dynamics.schema.lint`.
- Benchmark artifacts.
- Deterministic ordering in runners and candidate lists.
- Report tasks.
- Labels.

## Schema export and compatibility tooling (implemented)

- Top-level and targeted nested JSON Schema compatibility exports that now embed
  each contract's direct declared nested contracts under `$defs`, per-contract
  bulk directory output, and bundle output through
  `mix orbital_dynamics.schema.export`. This includes an explicit
  `result_artifact.v1` wrapper contract for run metadata, payload metrics, and
  promoted event rows, plus embedded constraint, maneuver-review, and Monte Carlo
  reproducibility report contracts.
- Structural `study_manifest.v1` JSON Schema export through
  `mix orbital_dynamics.manifest.schema.export`.

### Compatibility policy

- An explicit schema export compatibility policy in
  `OrbitalDynamics.Schema.compatibility_policy/0` and the exported bundle.
- Each standalone contract schema embeds the full compatibility policy, while
  compact nested `$defs` retain policy-version references.

### Identity policy

- A stable public-ID policy in `OrbitalDynamics.Schema.identity_policy/0`,
  embedded in standalone contract schemas and the structural `study_manifest.v1`
  manifest schema.
- It names generated-ID semantic invariants for campaign/candidate-refresh
  source ordering, sequence suffix assignment, and timeline-publication
  `publication_id` lineage.
- It is enforced by artifact linting for public artifact rows.
- Manifest field-reference artifacts carry compatibility and identity policy
  version breadcrumbs plus a compact generated-ID identity-policy summary for
  preflight tooling.

## Validation, readiness, and quality gates (implemented)

### Schema validation reports

- `schema_validation_report.v1` wrappers from
  `OrbitalDynamics.Schema.validation_report/2` and
  `mix orbital_dynamics.schema.lint --format json` for machine-readable artifact
  validation/import gates.
- Schema capability metadata advertises validated-contract metadata, status/issue
  counts, remediation rows, enforced model limits, batch
  file/artifact/skip counts, nested report entries, skipped-artifact rows, and
  compatibility/identity policy breadcrumbs for catalog consumers.
- `schema_validation_report.v1` exports nested validation issue rows and
  machine-readable invalid-input remediation rows.

### Operational readiness reports

- `operational_readiness_report.v1` for machine-readable importable, review-only,
  analysis-only, and blocked readiness classification over existing review/import
  evidence. Runtime validation reconciles the report ID to its source artifact
  type and ID rather than accepting merely well-formed stale lineage.
- Includes structured operational-mode gate evidence for analysis-only mode
  markers and capability-published analysis-mode aliases such as `sim`,
  `tradeoff`, `no execution`, and `not for ops`, including direct artifact
  assumption markers such as `assumptions.not_for_execution`.
- Includes boolean-gated candidate-rejection and provider-counteroffer review
  evidence and fail-closed downgrades for otherwise ready imports with
  stale/unknown freshness or failed schema-validation evidence.
- Provides compact `operational_import_eligibility` and
  `operational_readiness_gate_summary` summaries that preserve non-passed gate
  evidence and gate status/classification routing **without granting Cadence
  write or operator authority**.

### Quality gates

- Standalone `quality_gate_report.v1` artifacts from
  `OperationalReadiness.quality_gate_report/2` for row-oriented gate routing with
  explicit **handoff-only execution-boundary** fields. Runtime validation pins
  both report identity and source-readiness lineage to the declared source
  artifact identity, then pins every row ID to that source plus gate ID and rank.
- `operational_quality_gate_summary` provides a compact row-derived routing view
  over standalone quality-gate rows, preserving status/classification counts,
  gate IDs, row IDs, and non-passed rows without approving or importing work.
  Runtime validation derives the source quality-gate and readiness report IDs
  from the declared source artifact identity for this summary and all four
  specialized quality-gate summaries. CampaignPlanner checks that exact lineage
  before deriving summary-backed pressure branches and risk terms, while
  preserving row-derived recovery from stale redundant aggregate arrays.
- Derived operator-review packages and Cadence import manifests preserve
  quality-gate gate counts, status/classification count maps, gate-ID maps,
  quality-gate row-ID maps, and gate ID sets at their top-level adapter
  boundary.
- Resource-availability quality gates preserve resource-blocked contact-ID maps
  by blocking dimension and spacecraft, so Cadence-facing gate queues can route
  unavailable-resource pressure without reopening contact-allocation rows.
- `operational_quality_gate_unavailable_resource_summary` provides the compact
  row-derived unavailable-resource routing view over quality-gate rows,
  preserving reason counts, blocked contact-ID maps, status-grouped row IDs, and
  no-authority artifact-only assumptions. CandidateRefresh may retain an
  invalid or stale summary in replay provenance, but requires the original
  summary to pass standalone validation before its contact maps affect
  candidate selection.
- `operational_quality_gate_schema_validation_summary.v1` provides the
  validated row-derived schema-validation routing view over Cadence-import
  quality-gate rows, preserving pass/fail and issue counts, blocked row IDs,
  failed schema-validation row IDs, and no-authority artifact-only assumptions.
- `operational_quality_gate_import_readiness_summary.v1` preserves the
  validated row-derived freshness/import-status routing view, including
  stale/unknown freshness row IDs, import-preparation row IDs, blocked import
  row IDs, and Cadence-import status maps.
- `operational_quality_gate_operator_training_summary` preserves the matching
  row-derived operator-training routing view, including required roles,
  training, certification, qualification IDs, status/classification row IDs,
  and artifact-only no-authority assumptions.
- An optional mission-policy gate that treats preserved `policy_decision.v1`
  operator-review classifications as review-only and blocked-by-policy
  classifications as import-blocking evidence.

## Study run and resume tooling (implemented)

- `mix orbital_dynamics.study.run` accepts `--run-id` plus `--generated-at` so
  checked-in result artifacts can be regenerated **without changing stable run
  identity**, `--format json` for machine-readable generation summaries, and a
  guarded `--resume` mode that reuses an existing result artifact only after
  executable `result_artifact.v1` validation, manifest-SHA matching, and optional
  requested run-ID matching.
- The same preflight is available through
  `OrbitalDynamics.ResultSet.Artifact.resume_check/2`.
- Opt-in local continuation uses `--checkpoint PATH` for a fresh versioned
  `study_checkpoint.v1` and `--resume-checkpoint PATH` for an interrupted run.
  Each atomic same-directory replacement carries a checkpoint-level content
  hash plus per-scenario payload hashes, original zero-based manifest indexes
  and IDs, and exact manifest/study/model/run-option identities. Resume validates
  all identities, the full scenario manifest, row uniqueness/order/shape, and
  each payload before running only missing scenarios and combining propagation
  outcomes in original manifest order.
- Checkpoint provenance in `execution_report.v1` records the checkpoint path and
  SHA, create/resume mode, exact reused/run counts and indexes, chunk counts,
  identity hashes, and the local-only recovery boundary. Executable validation
  requires those counts to partition the source scenario indexes exactly.
- Checkpoint execution rejects output-path aliases, distributed task
  supervisors, batch propagation, failed-scenario retry composition, and
  identity-free API use. It provides no persistent queue, automatic retry,
  within-scenario checkpoint, distributed recovery, or planner behavior.

## Execution reports (implemented)

- `execution_report.v1` rows for run-mode, task-setting, execution-plan, adaptive
  chunk-size recommendation, timing, node-distribution, and per-scenario failure
  review.
- `execution_report.v1` exports nested failed-scenario rows.

## Reference docs

- The [`docs/artifacts/`](../../artifacts/README.md) reference maps canonical
  checked-in examples to contracts, public field families, and lint commands.

## Policy artifacts (implemented)

- `policy_bundle.v1` JSON Schema exports the nested approval-policy and
  action-rule fields that executable validation supports, including contact
  authority, escalation metadata, and the scalar/plural policy-context selectors
  used by built-in authority rules.
- `policy_decision.v1` exports nested rule-match and escalation row shapes,
  including list-valued station, allocation, timeline-protection, resource,
  provenance, review-queue, and provider-result evidence fields.
- `policy_bundle.v1` and `policy_decision.v1` have checked-in standalone fixtures
  covering mission-operations escalation, contact-schedule authority,
  ground-network allocation, and maneuver-authority metadata.

## Environment and planning-state artifacts (implemented)

- `environment_model_capability.v1` and `environment_provider_capability.v1`
  export typed supported-body and known-limit arrays, and executable validation
  rejects non-string members for those arrays plus provider-output arrays.
- `accepted_planning_state.v1` exports nested spacecraft state-estimate rows,
  including OPM-derived metadata and covariance-reference provenance fields.

## Campaign, repair, and feedback artifacts (implemented)

- `campaign_plan.v1` exports nested activity, candidate-activity, ranked-timeline,
  proposed-contact, and contact-intent rows with stable source-window
  identifiers, including generated contact-success feedback factor/source fields
  on refreshed contact candidates.
- Its generated timestamp is exported as a date-time, and runtime validation
  requires the exact deterministic `campaign_plan:<study_id>:<generated_at>`
  plan identity used by downstream handoffs.
- Its required assumption object pins the current candidate/selection/filter
  models, artifact-only Cadence boundary, and typed constraint/scoring maps.
- Its required provenance envelope types nullable run/revision/propagator,
  manifest, and propagator-option values while validating supplied manifest
  path and SHA-256 evidence.
- Its warning array is executable as unique, non-empty human-readable strings;
  the vocabulary remains open for future planning conditions.
- Its typed planning horizon validates declared duration/cadence as positive,
  requires duration for cadence, rejects cadence beyond duration, and bounds
  core schedule rows whenever a zero-based planning duration is declared.
- Selected, candidate, and ranked-timeline activities export required numeric
  non-negative durations, and executable V1 validation reconciles every value
  to its start/end interval before scoring or handoff evidence is accepted.
- Those activity surfaces also export numeric score-term map values; executable
  V1 validation requires score/term presence and types, then reconciles each
  activity score to the sum of its terms.
- Executable V1 validation also reconciles every ranked activity snapshot to its
  candidate row and every top-level selected snapshot to the first ranked
  timeline; this cross-array equality remains beyond structural JSON Schema.
- Stable candidate activity IDs are unique, as are stable selected activity IDs
  within each ranked timeline, preventing snapshot-key collapse and ambiguous
  optimizer handoffs. This property-key uniqueness is an executable rule.
- Candidate activities preserve ascending scenario/start/ID order, and each
  ranked timeline preserves ascending start/ID order. Executable adjacent-row
  checks keep report and optimizer array order aligned with the producer.
- Selected, candidate, and ranked activities require stable outer and nested
  source-window IDs, with executable equality checks preserving activity lineage
  back to the producer window.
- V1 proposed contacts are recomputed from final candidates and reconciled for
  exact count, order, and producer fields while permitting additional compatible
  handoff metadata. Malformed source rows remain field-validator concerns.
- V1 contact intents are recomputed from final candidates without an approval
  policy and reconciled for exact count, order, and base producer fields.
  Additional compatible fields preserve separately validated optional policy
  decisions without requiring the unretained campaign policy as plan input.
- Current observation and contact-family activity kinds conditionally pin nested
  source-window type to target visibility or ground-station access respectively.
- Their activity-type tokens are required nonblank strings in runtime and export
  while retaining an open vocabulary for compatible future activity kinds.
- Each activity's required Cadence-import envelope carries a stable external ID
  reconciled to activity identity plus a nonblank import type, while retaining
  the artifact-only no-write boundary.
- Current V1 activity kinds conditionally pin that import type to `observation`,
  `command`, or `contact`; compatible future activity kinds remain open.
- Contact-family activities conditionally require stable ground-station identity
  and exact activity-type direction routing on every V1 activity surface.
- Their nested Cadence envelope also conditionally pins the contact adapter
  contract to `proposed_contact.v1` without granting import or execution authority.
- It also exports typed target-commitment rows reconciled with candidate and
  selected observation counts, durations, selected IDs, statuses, unique target
  identity, and matching objective-satisfaction target rows.
- Executable V1 validation requires numeric ranked-timeline score terms and
  preserves producer ranking order across those timelines: scores descend and
  equal-score rows use ascending scenario identity. It also checks an optional
  score-term report against the enclosing timeline ranks, scenarios, terms,
  values, scores, and selection flags. JSON Schema exports constrain timeline
  term values to numbers and declare the report as a direct nested contract,
  while the cross-row ordering comparison remains executable.
- Ranked timelines require numeric activity-score and activity-count-penalty
  aggregates. Executable validation reconciles timeline score to those core
  terms plus present downlink-completion and precondition/resource-pressure
  adjustments, while excluding component/count explanations from the sum.
- Executable validation also derives activity score from the selected nested
  activity scores and count penalty from selected count plus the declared
  scoring-policy penalty, including the producer's zero default.
- Exported ranked score terms require nonnegative integer selected-observation
  and selected-contact counts. Executable validation reconciles both to nested
  activities using the ranking producer's observation and downlink classifiers.
- Exported ranked score terms also require numeric target-value, contact-value,
  and eclipse-penalty components. Each is reconciled to matching nested activity
  terms but excluded from aggregate score arithmetic to avoid double-counting.
- Ranked-timeline scenario IDs are unique, and nested activities must carry the
  identity of their enclosing scenario. Empty timelines remain valid; scenario
  uniqueness and ownership are executable cross-row/cross-field rules.
- Executable V1 validation also pins optional objective-tradeoff rows to the
  enclosing timeline rank/scenario, selected-score delta, score-term map,
  selected counts, and activity identities while validating each nested ranked
  activity through the existing planned-activity contract; the report is also a
  direct nested contract.
- `campaign_plan.v1` declares its optional `constraint_report.v1` handoff as a
  direct nested contract, runs the standalone row/count/status/model-limit
  validator, and pins the V1 campaign constraint model and source assumption.
- It also declares optional `contact_allocation_report.v1` evidence directly,
  runs the standalone allocation/nested-report validator, and pins the campaign
  candidate-activity source.
- Its optional `cadence_import_manifest.v1` handoff is declared directly, runs
  the standalone manifest/row/count/no-write validator, and must identify the
  containing `campaign_plan.v1` and plan ID as its source.
- Optional `command_window_report.v1` evidence is declared directly, runs its
  standalone row/count/model-limit validator, and pins selected-activity source
  plus the artifact-only command boundary.
- Optional `contact_filter_report.v1` and `station_calendar_report.v1` evidence
  is declared directly, exposing the same reports already checked by their
  standalone campaign validators.
- `campaign_repair.v2` exports nested repaired-activity, source-candidate, source
  contact-allocation, source timeline-feedback handoff rows, plan-delta, and
  approval-requirement rows.
- Its optional `cadence_import_manifest.v1` handoff is also declared directly
  and runs the standalone manifest/row/count/no-write validator. Repair-specific
  validation pins the source to the containing repair ID and requires its row
  count, provenance count, and ordered source-review row IDs to match the
  enclosing `operator_review_package.v1`.
- Optional V2 source `operational_readiness_report.v1` and
  `quality_gate_report.v1` evidence is declared as direct nested contracts and
  runs both standalone validators. Executable repair validation also requires
  the quality-gate report's readiness-report ID and source artifact identity to
  match the paired readiness report when both are present.
- V2 also declares candidate-refresh source `candidate_diff_report.v1`,
  `freshness_report.v1`, and `refresh_budget_report.v1` evidence directly. All
  three run their standalone row/count/model-limit validators at the repair
  boundary while remaining optional for repairs that did not consume refresh
  evidence.
- Source `contact_allocation_report.v1` and `station_calendar_report.v1`
  evidence is likewise declared directly and validated before V2 uses its
  station availability, allocation, reservation, and capacity context in
  replacement ranking and pressure scoring.
- Source `contact_filter_report.v1`, `resource_filter_report.v1`, and
  `resource_projection_report.v1` evidence is also declared directly. Existing
  runtime validators enforce suppression rows/counts, trust and resource
  context, projected-resource evidence, and exact model limits before V2
  derives filter or projection pressure.
- V2 source `timeline_feedback_report.v1` evidence is declared directly and
  runs its complete standalone validator at the embedded source path, including
  row-derived counts, exact model limits, operational feedback, and nested
  operator-review validation.
- V2 `source_contact_intents` and `source_resource_summaries` are declared as
  optional arrays with direct `contact_intent.v1` and `resource_summary.v1`
  definitions. Existing runtime row validators enforce each populated item
  before repair scoring, ranking, or strategy handoff.
- The remaining produced V2 metadata surface is declared and executable:
  stable study/source identity, non-negative row-derived change counts, exact
  preserved-activity subsets, and shared policy validation for top-level
  approval rule matches. Older repairs may omit these additive fields.
- `realized_state_snapshot.v1` and `timeline_feedback_report.v1` export nested
  operational-feedback rows plus command/contact feedback, throughput-delta,
  success fields, and source planned/realized activity context.

### Realized-activity rows

- `realized_activity.v1` rows now type source-window IDs, top-level
  `activity_type`, direction, station/target IDs, actual throughput,
  command/contact success, command result, success-factor evidence, maneuver
  delta-v vectors, provider/import provenance fields, source/provenance, and
  metadata.
- Checked-in standalone realized-activity and realized-state snapshot examples
  exist for import-gate compatibility checks.
- Executable validation covers reversed actual execution intervals, negative
  actual throughput/data-volume evidence, out-of-range completion fractions and
  success factors, and malformed success-factor evidence.
- Snapshot-level `model_limits` validation runs against
  `CampaignPlanner.realized_state_snapshot_model_limits/0`.

### Timeline-feedback rows

- Timeline-feedback rows and nested activity context apply the same non-negative
  actual-throughput/data-volume checks plus unit-interval
  completion/success-factor checks.
- Downstream operator-review/Cadence-import rows preserve those checks when
  validated directly.

### Realized-state snapshot spacecraft-state rows

- Now require a scenario identity and apply executable nested stable-ID,
  status/mode/payload-status, degraded flag, payload/antenna availability,
  incompatible-activity, source, and metadata validation instead of relying on
  list-shape checks alone.
- Repair/strategy normalization maps legacy realized spacecraft-state `id` values
  into `scenario_id` and records dropped identity-less and invalid-identity rows
  as separate snapshot metadata counts before artifact validation.
- Realized-state snapshot metadata now exports typed snapshot, mission-state,
  source, feedback-boundary, dropped-row accounting, and provider/import
  provenance fields, requiring a direct or provenance-supplied `trust_boundary`
  whenever metadata declares provider or adapter identity.
- Snapshot-level `model_limits` declare the provider-feedback,
  no-ground-truth-reconstruction, no-schedule-mutation, and
  no-subsystem-state-estimation boundary.

## Checked-in standalone fixtures (implemented)

- `operator_review_package.v1` has a checked-in standalone approval plus
  realized-feedback package fixture for import-gate compatibility checks.
- `strategy_recommendation.v1` has a checked-in standalone recommendation fixture
  covering ranked branches, tradeoffs, risks, explanation rows, schema-visible
  branch-event transition summaries, and approval requirements.
- `strategy_branch.v1` has a checked-in standalone fixture covering branch
  probability, numeric score terms, risk indicators, policy decision evidence,
  approval requirements, typed branch-event downlink source lineage, bounded
  feedback factors, latency/data identity, and resource/provenance context.
- `branch_comparison_report.v1` has a checked-in standalone
  selected-versus-alternative fixture covering score deltas, branch probability,
  flattened resource margins, repair score summaries, and approval/risk counts.
- `maneuver_recommendation.v1` has a checked-in standalone impulsive-burn
  recommendation fixture covering timing, frame, delta-v vector, magnitude,
  row-level validation/model-limit metadata, and **recommendation-only execution
  boundary**.
- `monte_carlo_reproducibility_report.v1` has a checked-in standalone
  reproducibility fixture covering seeded RNG metadata, generated scenario IDs,
  sigma vectors, assumptions, known limits, capability-exact `known_limits` and
  `model_limits` validation, integer seed/count validation, and string-valued
  source provenance in the exported JSON Schema.
- `campaign_request_lint.v1` has a checked-in standalone fixture and JSON Schema
  export for preflight validation of V2/V3 request files.
- `validation_reference_report.v1` and `validation_check.v1` have checked-in
  standalone fixtures for linting individual reference reports and check rows.
- `station_calendar_provider.v1`, `contact_contention_report.v1`, and
  `contact_contention_resolution_report.v1` have checked-in standalone fixtures
  covering declared station availability/reservation inputs and advisory
  same-station plus same-spacecraft cross-station contention recommendations,
  including per-recommendation normalized resolution-policy diagnostics.
- Checked-in standalone `link_capacity_report.v1`, `contact_allocation_report.v1`,
  and `resource_filter_report.v1` plus `resource_projection_report.v1` fixtures
  now lint the communications and resource report contracts outside their
  campaign wrapper.
- Checked-in standalone optimizer, ranking comparison, Pareto frontier,
  score-term, objective-tradeoff, and objective-satisfaction fixtures cover
  import-gate compatibility checks.

## Candidate refresh (implemented)

- `candidate_refresh.v1` exports nested candidate-activity, source-window lineage,
  invalidated-candidate, refreshed contact-intent, contact-allocation, and
  resource-summary rows with resource source-quality fields.
- Its `refresh_id` now hashes material refresh inputs such as accepted planning
  state, mission-state objectives and spacecraft states, targets, ground network,
  prior candidates, resource summaries, policies, and operational feedback, so
  distinct branch-local refresh requests do not collapse to the same artifact
  identity.
- Candidate-refresh provenance now also records supplied source
  `candidate_diff_report.v1`, `freshness_report.v1`, `refresh_budget_report.v1`,
  and `operational_readiness_report.v1` paths, counts, row/status totals,
  gate/evidence counters, and trust boundaries when they arrive through
  top-level, accepted-state, or mission-state refresh inputs, keeping
  branch-generated refresh artifacts auditable **without changing candidate
  selection**.
- Candidate-refresh review/import handoffs now lift operational-readiness
  source-report summaries into `operational_readiness_review` and
  `review_operational_readiness` rows.
- Operator-review packages and Cadence-import manifests built directly from
  `operational_readiness_report.v1` preserve the source readiness report ID,
  readiness/import/status classification, and gate counts at the top level, so
  import-readiness routing does not need to reopen row-level evidence.

## Maneuver recommendation and review (implemented)

- `maneuver_recommendation.v1` and `maneuver_review_report.v1` export
  three-number delta-v vector shapes.
- Executable validation checks recommendation `model_limits` against
  `ManeuverReview.recommendation_model_limits/0`.
- Maneuver-review reports type declared/missing execution-uncertainty review
  metadata, expose invalid recommendation IDs and model-limit strings in JSON
  Schema, and cross-check row-derived maneuver/review/invalid-recommendation
  counters plus approval/action count maps before review/import handoff.
- Bounded maneuver-success confidence evidence still carries schema-validated
  `model_limits` copied from `ManeuverReview.capabilities/0`.

## Optimizer, ranking, and Pareto artifacts (implemented)

- `optimizer_contract.v1` exports typed selected/candidate/ranked ID arrays and
  planner ordering/limit arrays, with executable validation enforcing its
  candidate/selection/ranked count fields against the corresponding ID arrays and
  its `known_limits` against `OrbitalDynamics.Optimizer.capabilities/0`.
- V1 campaign validation additionally reconciles the optional optimizer model,
  selection policy, ordered ID lists, scenario and score-term keys, constraints,
  scoring policy, and objective with the enclosing plan; the required ranking
  explanation exports and validates typed objective, formula, and policy object.
- Optimizer, ranking comparison, and Pareto frontier JSON Schema exports also
  publish those limit arrays as exact string sets for non-Elixir import gates.
- `monte_carlo_reproducibility_report.v1` exports typed generated-scenario ID,
  capability-checked known-limit, `model_limits`, and sigma-vector arrays.
- `objective_tradeoff_report.v1` exports nested ranking tradeoff row fields with
  integer ranking/activity/contact counts and numeric score deltas, with
  executable validation deriving ranking totals, score-term keys, and per-row
  activity counts from the emitted tradeoff rows.
- `ranking_comparison_report.v1` exports nested pairwise ranked-scenario
  comparison row fields with integer-or-null rank deltas and now validates
  row-derived comparison totals.
- `pareto_frontier_report.v1` exports nested dominance-summary row fields and
  validates frontier/dominated counts, stable-ID dominance lists, numeric
  objective-value maps, and objective counts from rows/objective directions.

## Resource projection and filtering (implemented)

- `resource_projection_report.v1` exports nested per-spacecraft projection row
  fields including explicit projected overflow/shortfall, per-activity
  resource-flow roll-forward rows, first resource-pressure activity fields,
  resource source quality, declared-vs-missing trust-boundary status, boolean
  payload/antenna availability flags, and optional resource-pressure approval
  requirements, plus invalid external resource-summary rows.
- `resource_filter_report.v1` exports nested suppressed-candidate row fields plus
  deterministic resource blocking dimensions, source-quality counts,
  trust-boundary status counts, bounded contact/command confidence factors, and
  duplicate suppressed-candidate ID disambiguation fields.

## Branch comparison (implemented)

- `branch_comparison_report.v1` exports branch score/probability, objective
  satisfaction, feedback factor/risk, resource projection, repair score-term, and
  repaired link-capacity row fields including selected capacity, required downlink
  demand, planned shortfall, and requirement status, plus repaired constraint
  counts/statuses from nested branch repair results and branch-event
  station/calendar/provider/reservation summary arrays plus status-transition
  type/category/reason summaries and operator-review requirement counts.
- Its resource projection fields include first-pressure direction and
  station-calendar context from nested projection flow rows, with executable
  `model_limits` validation against
  `CampaignPlanner.branch_comparison_model_limits/0`.

## Score-term and objective reports (implemented)

- `score_term_report.v1` exports nested score-term row fields; objective and
  score-term reports export typed score-term key arrays with row-derived
  key/count validation.
- `objective_satisfaction_report.v1` exports nested objective status row fields,
  validates objective totals against emitted rows, including downlink-completion
  count and MB totals aggregated across multiple scoped downlink objectives.

## Link capacity and contact contention (implemented)

- `link_capacity_report.v1` exports nested ground-station throughput row fields
  including effective/ignored contact counts.
- `contact_contention_report.v1` and `contact_contention_resolution_report.v1`
  export nested station- and spacecraft-scoped contention group and
  recommendation rows with typed count fields, source-window lineage, resource
  scope, station/spacecraft identity, direction, required operator action,
  approval status, provenance, and stable-ID patterns on exported
  contact/source-window/scenario/station/spacecraft/deferred-contact ID arrays.
- Nested contention-resolution policy metadata is exported for selection rules,
  priority fields, tie breakers, normalized priority override maps/counts/IDs, and
  action, with executable validation cross-checking group/recommendation totals
  against emitted rows.

## Contact allocation (implemented)

- `contact_allocation_report.v1` now exports formal nested schemas for its
  embedded station-calendar, contact-filter, contact-contention, and
  contention-resolution reports instead of leaving those nested artifacts as
  generic objects, including their checked-in `model_limits` arrays and
  contact-contention provenance.
- Exported allocation row requirements now match the executable row contract,
  keeping `approval_status` optional for reduced-capacity pack rows that do not
  carry policy approval evidence, with executable row-count validation for
  duplicate-contact and station-calendar overlap/reservation evidence.

### Stable-ID patterns in exported schemas

- Link-capacity top-level invalid/unmatched/ambiguous contact ID arrays plus
  row-level contact/selected/duplicate/ambiguous contact ID arrays now carry
  stable-ID patterns in exported schemas to match executable validation.
- Resource-projection invalid activity/resource-summary ID arrays and
  resource-filter invalid resource-summary ID arrays now carry the same stable-ID
  patterns as their executable validators.
- Top-level contact-allocation invalid/status/resource-blocked ID arrays plus
  contact-filter and resource-filter invalid-input ID arrays now carry stable-ID
  patterns in exported schemas to match executable validation.

### Collision and overlap evidence

- Duplicate-contact collision rows now require candidate count, ID, and
  source-candidate evidence across allocation, contention, and contention
  recommendation artifacts.
- Station-calendar duplicate affected-row collisions require base row ID plus
  integer, group-consistent index/count evidence.
- Filter suppressed rows cross-check station-calendar ambiguity and reservation
  count/list pairs, require overlap counts to cover listed overlap IDs when
  broader overlap state is preserved, and require duplicate suppressed-candidate
  base/index evidence to match group size and index coverage.

## Planned activity (implemented)

- `planned_activity.v1` exports command, contact, observation, and maneuver
  success-confidence fields with unit-interval bounds, first-class resource
  source/trust/provenance, margin, battery, availability/degraded, product,
  latency, throughput, link profile/quality, observation-quality, pointing,
  thermal, dependency, and exclusivity fields aligned with typed mission-plan
  activity evidence.
- Accepts top-level `activity_type` as a JSON-facing alias for canonical `type`.
- Adds a typed optional raw `execution_uncertainty` map for timing 3-sigma,
  delta-v 3-sigma vectors, and source labels used by timeline/review handoffs,
  with standalone executable validation for the same confidence bounds,
  type-alias boundary, and uncertainty-map shape.
- `MissionPlan.Activity.from_map!/1` parses clean numeric-string timing,
  impulsive-burn epoch/delta-v, known execution-uncertainty numeric fields, and
  trimmed case-insensitive JSON-style `locked` / `allow_overlap?` booleans at the
  typed activity artifact boundary while preserving malformed numeric strings or
  booleans as invalid input or opaque review metadata.

## Operational timeline (implemented)

- `operational_timeline_report.v1` exports its row, execution-uncertainty counts
  and row fields, dependency/exclusivity stable-ID arrays, timeline-identity field
  shape, and timeline-integrity review fields for missing dependencies,
  out-of-order dependencies, explicit exclusivity overlaps, and shared
  exclusivity-group overlaps.
- Malformed scenario/station/target/source-window, explicit timeline,
  product/payload/instrument, or scalar station-overlay IDs are routed to
  invalid-input review rows, and malformed or non-stable station-calendar
  overlay-list entries plus dependency/exclusivity list entries are ignored
  instead of becoming phantom stable-ID links.
- Standalone operational-timeline activity ingress also parses clean
  numeric-string timing aliases, known execution-uncertainty numeric fields, and
  optional throughput/data-volume/resource-margin/latency/pointing/capacity
  context numbers plus trimmed case-insensitive JSON-style resource
  availability/degraded booleans before schema validation, dropping malformed
  optional numeric strings and booleans as missing typed evidence.
- `operational_timeline_report.v1` now has a checked-in fixture for import-gate
  compatibility checks with executable `model_limits` validation against
  `OrbitalDynamics.Timeline.model_limits/0`.

## Operator-review / Cadence-import row families (implemented)

- Operator-review/Cadence-import schemas export the corresponding
  operational-timeline, score-term, objective-tradeoff, and branch-comparison
  feedback factor source-label row families.

## Strategy V3 and branch exports (implemented)

- `campaign_strategy.v3` and standalone `strategy_branch.v1` export nested
  branch-event and `operational_feedback` map shapes for
  score/risk/approval/resource context, maneuver execution uncertainty feedback
  events, branch repair command-window report references, strategy
  operational-feedback provenance, plus success-rate, throughput, target-priority,
  resource-margin, and payload/antenna availability overrides.

## Candidate-refresh top-level operational feedback (implemented)

- `candidate_refresh.v1` now emits valid non-empty normalized
  `operational_feedback` maps at the top level as well as in provenance, so
  branch-local refresh handoffs can preserve command, maneuver, resource, and
  maneuver-execution uncertainty inputs without requiring consumers to reconstruct
  them from warning/provenance rows.
- V3 strategy consumes that top-level refresh feedback as a first-class merge
  source before explicit request feedback.
- Repair/strategy candidate-source summaries expose the refresh feedback input
  keys, trust-boundary status, and nested feedback provenance for operator-review
  and import routing.

## Executable schemas (partial)

Schemas are now executable for the following artifacts and rows:

- Campaign V1/V2/V3 and candidate-refresh artifacts.
- `planned_activity.v1`, `proposed_contact.v1`, `contact_intent.v1`,
  `resource_summary.v1`, `resource_projection_report.v1`, `realized_activity.v1`,
  and `realized_state_snapshot.v1`.
- `plan_delta.v1`, `approval_requirement.v1`, `policy_decision.v1`,
  `strategy_recommendation.v1`, `maneuver_recommendation.v1`,
  `execution_report.v1`.
- `objective_tradeoff_report.v1`, `ranking_comparison_report.v1`,
  `branch_comparison_report.v1`, and `optimizer_contract.v1`.
- `link_capacity_report.v1`, `contact_contention_report.v1`,
  `contact_contention_resolution_report.v1`, `station_calendar_report.v1`, and
  `objective_satisfaction_report.v1`.
- `operational_timeline_report.v1`, `timeline_diff_report.v1`, and
  `monte_carlo_reproducibility_report.v1`.
- `schema_validation_report.v1` rows.

### JSON Schema compatibility exports

- Exports cover required top-level fields, coarse property types, typed top-level
  `_count` fields instead of opaque object fallbacks, and targeted nested schemas.

### First nested coverage

First nested coverage exists for:

- Policy bundle approval rules; policy decision rule matches/escalations.
- Objective-tradeoff rows; constraint rows; resource-projection rows;
  branch-comparison rows; score-term rows; link-capacity rows.
- Timeline status/approval transition rows.
- Contact-contention group/recommendation rows; objective-satisfaction rows.
- Candidate-refresh candidate-activity rows.
- Campaign activity/ranked-timeline/contact rows; campaign repair delta and
  approval rows.
- Standalone and embedded strategy recommendation ranked-branch, approval-status
  enum, string-keyed strategy-policy numeric scoring weights, V2/V3 embedded
  approval-policy action-rule selectors, embedded V2/V3 policy-decision
  classification/rule-match/escalation rows, tradeoff, risk, explanation, and
  approval-requirement rows.
- Contact-intent approval rows.
- Campaign/repair/refresh warning arrays; realized feedback rows; execution
  failure rows; validation issue rows; candidate-refresh validation records;
  validation-reference fixture report/check rows.
- Optimizer/environment scalar arrays.
- Operational/command-window/operator-review timeline identity rows; timeline-diff
  source/replacement timeline identity rows.

### Shared nested activity-context schemas

- Shared nested activity-context schemas exist for approval requirements, repair
  deltas, operator-review rows, and Cadence import rows.
- They carry matching executable stable-ID validation and explicit
  score/throughput/feedback plus dependency/exclusivity, timeline-integrity, link
  profile/quality, pointing/attitude, thermal, resource availability, and
  station-calendar overlap/reservation field typing.
- This includes executable stable-ID validation for nested station-calendar
  entry/provider/reservation IDs and non-negative station-calendar/timeline-integrity
  counts, and unit-interval checks for nested completion, success-factor,
  confidence, error-rate, loss-rate, and battery state-of-charge evidence plus
  planning-grade resource margin evidence.

### Candidate-refresh objective context

- Candidate-refresh observation and collection-latency objective ID/count context
  that branch-local review and import handoffs already preserve.

### Additional partial coverage

- V3 strategy branch rows, standalone strategy-branch event rows, V3
  operational-feedback maps.
- Checked standalone `spacecraft_state_estimate.v1`,
  `maneuver_execution_delta.v1`, `planned_activity.v1`, `proposed_contact.v1`,
  `contact_intent.v1`, nested
  planned-activity/candidate-activity/proposed-contact/contact-intent Cadence
  import adapter trust rules, and plan-delta nested planned-snapshot
  identity/timing plus realized-activity validation with nested planned-activity
  Cadence import adapter trust rules.
- `approval_requirement.v1`, `refreshed_window.v1`, `source_window_lineage.v1`,
  `validation_record.v1`, `remaining_horizon.v1`, `candidate_activity.v1`,
  `invalidated_candidate.v1`, `candidate_diff_report.v1`, `candidate_diff_row.v1`,
  `plan_delta.v1`, `strategy_recommendation.v1`, `strategy_branch.v1`,
  `branch_comparison_report.v1`.
- Standalone candidate-activity duration, eclipse-overlap, schema-enumerated
  lighting-condition/detail/model/confidence exports matching embedded refresh
  rows, schema-visible spacecraft/collection/product/payload/instrument identity,
  observation objective IDs, objective types, required-observation counts,
  target-priority source/objective evidence, and objective score terms for direct
  target-observation refresh objectives, plus collection-latency objective IDs,
  collection/product/payload/instrument selectors, latency limits, required
  downlink volume, and objective score terms for direct collection-latency refresh
  objectives with standalone stable-ID and non-negative quantity validation.
- Strategy branch candidate-plan capacity-adjustment rows with bounded
  `capacity_fraction` instead of raw event feedback fields.
- Timeline-diff review classification for changed downlink-completion requirement,
  shortfall, status, and source-lineage evidence in reusable activity context.
- Candidate/proposed-contact/activity-context nested `throughput_model` schemas
  whose known estimated/planned/actual/delivered/received MB aliases and
  downlink-completion demand/shortfall evidence are numeric and non-negative while
  capacity/confidence factors are unit-interval bounded.
- `maneuver_recommendation.v1`, `monte_carlo_reproducibility_report.v1`,
  `campaign_request_lint.v1`, `validation_reference_report.v1`,
  `validation_check.v1`, `freshness_report.v1`, and `refresh_budget_report.v1`
  fixtures.

**Most nested semantic validation remains executable Elixir code.**

### Versioning and identity policy (partial)

- Artifact versioning now has a first compatibility policy for exported contracts,
  and public artifact IDs have a first machine-identifier policy.

### Schema-visible `model_limits` arrays

- New scoring/comparison reports, `candidate_refresh.v1`, operational-timeline,
  timeline-diff, timeline-feedback, command-window, maneuver-review,
  station-calendar, station-contention, contention-resolution, link-capacity,
  contact-allocation, resource-projection,
  candidate-diff/freshness/refresh-budget, `operator_review_package.v1`,
  `contact_intent.v1`, and `cadence_import_manifest.v1` artifacts emit
  schema-visible `model_limits` arrays copied from their **artifact-only**
  capability declarations.

### Exporter type inference

- The JSON Schema exporter now also infers scalar `*_count` fields as integers and
  generic `*_id`/`*_ids` fields as stable-ID strings or string arrays when a
  field-specific type hint is not present, preventing review/import count
  summaries or identifier fields from defaulting to opaque object schemas.
- The standalone exported schemas now cover top-level identity fields such as
  `manifest_id`, `refresh_id`, validation `fixture_id` / `model_id`, realized
  `planned_activity_id`, and contact-allocation invalid/blocked contact-ID arrays
  with the same stable-ID shape used by executable validation.

### Scalar typing improvements

- Link-capacity JSON Schema exports now type top-level source, required downlink
  demand, selected shortfall/status, and actual-throughput fields with the same
  scalar contracts enforced by executable validation instead of falling back to
  opaque object schemas.
- Branch-comparison, command-window, objective-satisfaction, and score-term report
  exports now also type their top-level source path as a string, matching
  checked-in Cadence-facing fixture shape instead of treating source provenance
  labels as opaque objects.
- Contact-intent station availability and schedule-conflict status, plus
  standalone freshness timing and state-quality status fields, now export with the
  same scalar string/number types enforced by executable validation instead of
  falling back to opaque object schemas.
- Objective tradeoff, branch-comparison, and V3 strategy branch score-term maps
  plus Pareto frontier objective-value maps now export as numeric maps and
  executable validation rejects non-numeric entries after clean numeric-string
  ingress has normalized them, so downstream ranking/review tools can treat those
  maps as quantitative planning evidence instead of opaque JSON objects.
- Direction-scoped station-calendar evidence now also exports
  `station_calendar_directions` as string-array contract data on proposed
  contacts, candidate activities, contact intents, filter/allocation rows,
  station-calendar rows, and provider evidence entries, with executable validation
  rejecting non-string values.

### Integer boundaries and cross-checks

- Executable validation now mirrors that integer boundary for candidate-diff and
  refresh-budget scalar counts plus candidate semantic/budget match count fields,
  and cross-checks resource-projection pressure summaries against row-level
  roll-forward evidence.

### Compatibility-assertion fixtures

- Checked-in command-window, operational-timeline, operator-review, and
  timeline-feedback fixtures now prove that promoted nested activity-context,
  planned-activity, and realized-activity fields remain covered by exported JSON
  Schema properties, with explicit compatibility assertions for provider
  `contact_result` fields on operator-review, command-window, operational-context,
  and Cadence-import row schemas.

### Permissive typed nested source schemas

- Operator-review and Cadence-import handoff row schemas now also expose
  permissive typed nested schemas for `source_contact_intent`,
  `source_operational_timeline`, `source_timeline_diff`,
  `source_timeline_application`, `source_timeline_transition_application`, and
  `source_timeline_protection`, so adapters can inspect known source-row evidence
  without treating those payloads as opaque objects or requiring a fully populated
  embedded row.
- Strategy/scoring handoff sources now follow the same pattern for
  branch-comparison, ranking-comparison, Pareto-frontier, objective-satisfaction,
  objective-tradeoff, score-term, and strategy-tradeoff rows.
- Resource/contact/command handoff sources also expose permissive typed nested
  schemas for contact-allocation rows, contention groups and recommendations,
  command-window rows, station-calendar affected-contact rows, link-capacity rows,
  resource-projection rows, resource summaries, maneuver-review rows, and
  contact/resource suppression rows.

### Review package source-type contracts

- Operator-review packages now advertise capability-backed supported
  `source_artifact_type` contracts, and exported schema plus executable validation
  reject unsupported review package source artifact types before those packages
  are handed to Cadence import manifests.

### Generated-ID ordering invariants (partial)

- Generated IDs now have exported semantic ordering invariants for V1 campaign and
  candidate-refresh source event inputs plus contact-contention conflict groups and
  resolution recommendations.
- Contact-contention duplicate candidates are canonicalized by
  source-window/provider identity so reversing source contact order does not
  change public group IDs or review evidence.
- Relay data-path summaries export a generated route-ID scope through the
  identity policy and advertise it through capability metadata: explicit route
  IDs take precedence, while fallback IDs are stable under route ordering changes
  and change when semantic route evidence changes.
- Timeline-publication summaries export their generated `publication_id` scope
  through the same identity policy, pinning publication sequence, source
  artifact ID, and superseded artifact lineage as the semantic identity inputs.
- Broader cross-version invariants beyond the current public-ID policy scopes are
  still partial.

## Roadmap

- **Near-term** — broaden the exported schema registry toward nested JSON Schema
  or equivalent machine validation, semantic ID stability rules, provenance
  conventions, model-limit declarations for remaining artifact families, and
  broader import/export contract tests.
- **Later** — resumable studies, artifact migrations, signed or content-addressed
  archives, and long-term audit storage contracts.
- **Out of scope** — Cadence's operational audit database.
