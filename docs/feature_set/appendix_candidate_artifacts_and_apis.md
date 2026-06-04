# Appendix: Candidate Artifact Types and APIs

## Existing Artifact Families

- Study result artifact: `ResultSet.Artifact.build/2` and
  `ResultSet.Artifact.write_json!/2`.
- Benchmark artifact: `Benchmark.Artifact` and study benchmark artifacts.
- V1 campaign plan: `campaign_plan` in a result artifact from
  `CampaignPlanner.build/2` or `OrbitalDynamics.campaign_plan/2`.
- V2 repair artifact: result from `CampaignPlanner.repair/1` or
  `OrbitalDynamics.campaign_repair/1`.
- V3 strategy artifact: result from `CampaignPlanner.strategy/1` or
  `OrbitalDynamics.campaign_strategy/1`.

## Candidate Future Artifact Types

- `planned_activity`: typed activity with ID, type, spacecraft, start/end,
  source window, dependencies, exclusivity, approval status, lock state, and
  provenance.
- `proposed_contact`: station/provider contact with direction, AOS/LOS,
  expected throughput, capacity assumptions, conflicts, and Cadence import ID.
- `station_calendar_report`: artifact-only overlay of declared station
  availability/capacity intervals onto contact candidates with affected-contact
  IDs, timing, station-calendar lineage, availability, and capacity fractions.
- `link_capacity_report`: fixed-rate ground-station throughput summary with raw
  and capacity-adjusted totals based on declared station capacity fractions,
  plus limited selected-realized actual throughput evidence, while explicitly
  leaving link-budget modeling and full provider reconciliation out of scope.
- `contact_allocation_report`: artifact-only allocated/deferred/blocked contact
  allocation rows that compose declared ground-network filtering and
  station- and spacecraft-scoped contention recommendations without reserving
  station time or mutating schedules, while preserving actual-throughput
  evidence plus overlapping station-calendar context on realized blocked rows
  when supplied without claiming provider reconciliation.
- `contact_intent`: artifact-only contact request with direction, ground
  station, timing, estimated throughput, station availability, conflict status,
  source-window lineage, timeline identity, and Cadence import metadata.
- `maneuver_recommendation`: maneuver activities with timing, frame, delta-v,
  assumptions, review boundary, uncertainty, fuel impact, and downstream review
  requirements.
- `maneuver_review_report`: artifact-only review/import table over maneuver
  recommendations with rank, required operator action, delta-v totals, source
  recommendation, execution-uncertainty status/counts, and
  no-command-execution boundary.
- `resource_summary`: fuel, power, storage, payload, antenna, and availability
  summaries per spacecraft and plan branch.
- `plan_delta`: old/new activity comparison with repair action, reason, churn
  cost, and approval requirement.
- `timeline_diff_report`: artifact-only source/replacement activity comparison
  by timeline identity with added, removed, changed, unchanged, timing-delta,
  changed-field, status-transition, approval-transition, review-action, and
  transition-decision rows.
- `strategy_branch`: mission-state branch with events, candidate plan, repair
  result, score terms, risks, approvals, and probability assumptions.
- `validation_record`: model, backend, validation level, reference case,
  tolerance, observed error, evidence path, and reference-fixture report rows.
- `accepted_planning_state`: spacecraft state estimate with epoch, frame,
  covariance or uncertainty summary, source, quality metadata, and provenance.
- `candidate_refresh`: regenerated windows and activities for a remaining
  horizon, plus stale-candidate invalidation and source-window lineage.
- `candidate_diff_row`: retained/new candidate diff identity row with stable
  candidate IDs, source-window IDs, semantic change reasons, and budget-match
  evidence.
- `policy_decision`: approval/authority rule match with action, classification,
  reason, source policy, fallback auto/operator/block limits, and
  operator-facing explanation.
- `schema_validation_report`: manifest or artifact validation result with
  schema contract, validated artifact family/version, warnings, errors,
  validation mode, and compatibility-scope assumptions.

## Candidate Public APIs

- `OrbitalDynamics.capability_catalog/0` for public discovery of declared
  analysis, planning, operations, constraint, reporting, and
  environment-provider capability metadata.
- `OrbitalDynamics.evaluate_artifact_metric_constraints/2` and
  `OrbitalDynamics.artifact_metric_constraint_report/2` for reusable
  artifact-level constraint evaluation and review/import report generation.
- `OrbitalDynamics.campaign_local_constraint_report/6` for reusable
  campaign-local constraint reports over candidate activities, ranked timelines,
  and optional resource-projection/link-capacity summaries.
- `OrbitalDynamics.task_chunking_recommendation/2` and
  `OrbitalDynamics.resolve_task_chunk_size/2` for deterministic chunk-size
  guidance shared by direct scenario runs and study execution reports.
- `OrbitalDynamics.Environment` for current environment-model capability records
  and future ephemeris, solar, atmosphere, and model provider contracts, with
  top-level environment-model construction, validation, and provider-capability
  facades plus request-fit checks and provider selection for time span, body,
  and output.
- `OrbitalDynamics.OrbitElements` for bidirectional two-body osculating
  classical element conversion and reporting.
- `OrbitalDynamics.OrbitData` for accepted planning-state inputs, simple
  JSON/map Cartesian state-estimate import/export, narrow CCSDS OPM KVN
  import/export with metadata-only maneuver/covariance preservation, narrow
  CCSDS OEM KVN import/export with metadata-only covariance preservation, top-level
  direct and wrapper-aware orbit-data import/export facades, TLE and CCSDS OMM
  metadata preflight facades, and future
  external orbit-data interchange adapters.
- `OrbitalDynamics.Timeline` for operational activity products independent of
  raw propagation scenarios, including top-level timeline identity, context,
  link, transition, and protection helper facades.
- `OrbitalDynamics.ResourceSummary` for thin fuel, power, storage, downlink,
  payload, antenna, degraded-mode, assumptions, and provenance rows, with
  top-level normalization and JSON-row conversion facades.
- `OrbitalDynamics.Communications.ContactIntent` for contact intent,
  directionality, throughput estimates, station availability, conflict status,
  conservative station capacity context, source-window lineage, and Cadence import metadata, with top-level
  `OrbitalDynamics.contact_intents_from_activities/2` and
  `OrbitalDynamics.contact_intent_from_activity!/1` facades for artifact-only
  standalone conversion. Standalone `contact_intent.v1` rows can now flow
  directly through `OrbitalDynamics.operator_review_package/1` and
  `OrbitalDynamics.cadence_import_manifest/2` into `contact_intent_review` and
  `review_contact_intent` gates when the row carries review-required policy
  evidence, preserving provider result labels as schema-safe row and approval
  context strings through review and import surfaces. Those handoff rows lift policy routing
  fields from approval requirements, rule matches, and policy-decision
  escalations, including matched escalation level, queue, role, authority, and
  SLA metadata, so adapters can route contact-intent reviews by required
  authority without unpacking nested evidence; V3 branch derivation replays
  usable standalone planned-activity, proposed-contact, standalone
  realized-activity, realized-state snapshot activity, direct
  operational-timeline, and operational-timeline review/import feedback rows as
  branch-local contact, throughput, observation, command, or maneuver pressure
  with source path and trust-boundary evidence preserved. V3 branch derivation keeps
  ordinary approval-required contact intents review-only, while direct
  standalone, operator-review, or Cadence-import blocked-by-policy and
  missing/invalid Cadence-import downlink intents replay into branch-local
  downlink-completion pressure with source-window, approval, import-status,
  station-calendar provider, station reservation match, and trust-boundary
  evidence preserved. Contact intents also preserve `capacity_fraction`,
  `capacity_fraction_min`, and `capacity_fraction_max` from station
  capacity-fraction fields or provider percent aliases such as
  `capacity_percent`, `station_capacity_percent`, and nested
  throughput/capacity/activity context variants through policy, review, and
  import rows without treating the intent as a link-budget or reservation
  model. Standalone `proposed_contact.v1` rows can also flow into
  V3 branch-local contact-success and station-throughput replay, and directly
  into `OrbitalDynamics.cadence_import_manifest/2` as `import_proposed_contact`
  adapter rows without requiring a surrounding campaign artifact. Mission-state
  standalone planned/proposed activity source fields now replay through the same
  branch-local feedback and operational-feedback merge path as prior-plan
  standalone rows while preserving `mission_state.source_*` provenance.
  Mission-state `source_result_artifact` / `result_artifact` wrappers can carry
  the same planned/proposed row fields through that live replay path, inheriting
  wrapper trust boundaries when a nested row has no explicit trust boundary,
  and strategy operational-feedback provenance now summarizes replayed
  planned/proposed/realized source rows with activity-type, direction,
  Cadence-import status, planned-protection decision, and realized-status count
  maps when those fields are present.
  Standalone `planned_activity.v1` rows can flow through
  `OrbitalDynamics.operator_review_package/1` and
  `OrbitalDynamics.cadence_import_manifest/2` by reusing operational-timeline
  classification, so command/contact review, approval review, conflict
  resolution, terminal-exception review, and missing Cadence import preparation
  are available without wrapping the row in a full report. Standalone
  `realized_activity.v1` rows can likewise flow into V3 branch-local realized
  contact/throughput/observation/command/maneuver feedback, merge into
  strategy-level operational feedback when supplied through mission-state
  source fields, and flow through the same public review and import facades by
  reusing timeline-feedback reconciliation;
  without planned context they are kept as `realized_only` feedback and routed to
  `review_unplanned_realization` / `review_realized_feedback` gates.
  `realized_state_snapshot.v1` rows route each embedded activity through V3
  branch-local replay and through those same public review/import gates while
  preserving the snapshot artifact ID.
  Top-level `result_artifact.v1` wrappers now dispatch before the generic
  V1 campaign fallback, so embedded execution failures become
  `execution_review` operator-review rows and `review_execution` Cadence
  import gates while completed runs produce empty handoff artifacts; embedded
  constraint and maneuver-review sections are lifted through the same wrapper
  path with result-artifact provenance.
- `OrbitalDynamics.Communications.StationCalendar` for declared
  station-calendar provider artifacts that normalize into repair-time
  ground-network intervals without direct provider calls.
- `OrbitalDynamics.Communications.ContactAllocation` for deterministic
  artifact-only allocated/deferred/blocked contact rows from declared
  ground-network filters and same-station contention recommendations.
- `OrbitalDynamics.Validation` for model capability and evidence declarations,
  with top-level registry, policy, result-set record, and reference-fixture
  verification facades, plus `OrbitalDynamics.dependency_policy/0` for
  numerical-backend package policy.
- `OrbitalDynamics.Schema` for manifest/artifact schema validation, linting, and
  JSON Schema export, with top-level validation and compatibility-schema
  facades for import-gate callers.
- `OrbitalDynamics.Policy` for approval and authority classification artifacts,
  with top-level policy bundle, policy-bundle artifact, normalization, and
  decision facades.
- `OrbitalDynamics.CandidateRefresh` for mission-state-to-opportunity
  regeneration.
- `OrbitalDynamics.Optimizer` for deterministic and external optimizer
  adapters.
