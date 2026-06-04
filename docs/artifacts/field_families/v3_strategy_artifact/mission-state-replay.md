# Mission-State Replay and Operational Feedback

- `strategy_policy`, `approval_policy`, `operational_feedback`,
  `operational_feedback_provenance`, assumptions, and provenance. V3 accepts
  operational feedback and `timeline_feedback_report.v1` artifacts embedded in
  the mission-state snapshot, replays `timeline_feedback_report.v1` artifacts
  embedded in single or list-valued prior `source_result_artifact` /
  `result_artifact` wrappers with indexed source paths plus report or wrapper
  trust-boundary provenance, replays prior
  result-artifact-embedded `operator_review_package.v1` rows through the same
  review-pressure and operational-feedback paths as top-level review packages,
  replays prior result-artifact-embedded `cadence_import_manifest.v1` review
  rows through the same review-pressure and operational-feedback paths as
  top-level import manifests, recovers V2 repair
  `source_candidate_activities` / `candidate_activities` from prior
  `source_result_artifact` / `result_artifact` wrappers while preserving wrapper
  trust-boundary evidence on replayed source candidates, uses those replayed
  candidates as planning context for branch-local station/target feedback,
  realized-feedback matching, prior-plan candidate source counts, and
  branch-generated candidate-refresh prior-candidate diff inputs, and replays
  prior planned `activities` from those wrappers into branch-event realized-state
  synthesis plus command/maneuver feedback derivation; prior wrapper
  `proposed_contacts` likewise replay proposed-contact contact-success and
  station-throughput feedback context, and wrapper `operational_feedback` maps
  replay through the same prior-plan feedback source
  with source-path and trust-boundary provenance, consumes valid top-level
  `candidate_refresh.v1.operational_feedback` from supplied refresh artifacts,
  and lets top-level request feedback override all derived sources.
  Mission-state `operational_timeline_report.v1` rows replay through the same
  strategy feedback and branch-pressure path as prior-plan operational timeline
  rows, with `mission_state.operational_timeline_report.rows` source labels,
  weighted-row counts, feedback-weight source labels, and report trust-boundary
  provenance preserved before explicit mission-state or request feedback
  overrides. When those mission-state timeline-feedback or operational-timeline
  reports drive branch-generated refreshes, V3 also copies them into the
  generated `candidate_refresh.v1` request as typed top-level source reports so
  the branch candidate source exposes `CandidateRefresh` report paths, row
  counts, and trust-boundary provenance instead of only aggregate feedback keys.
  Mission-state `source_result_artifact` / `result_artifact` wrappers can carry
  direct `operational_feedback`, embedded `timeline_feedback_report`, and
  embedded `operational_timeline_report` inputs into the same live feedback
  merge, preserving wrapper or nested feedback trust boundaries in provenance
  and branch-local feedback events.
  Mission-state `source_command_window_report` and
  `source_maneuver_review_report` inputs likewise replay into V3 command and
  maneuver operational feedback, derived branches, and branch-generated
  `candidate_refresh.v1` provenance through
  `candidate_refresh.mission_state.source_*` report paths, preserving weighted
  row counts and maneuver execution-uncertainty evidence; the same report
  classes can be embedded in mission-state result-artifact wrappers and inherit
  wrapper trust boundaries. Mission-state
  `source_resource_projection_report` and `source_resource_filter_report`
  inputs now use the same branch-local resource-pressure path as prior-plan
  reports, carrying live resource shortfalls, unavailable resources, suppression
  policy context, and trust-boundary evidence into generated branch refreshes.
  The same mission-state path accepts resource-projection and resource-filter
  reports embedded in `source_result_artifact` / `result_artifact` wrappers, so
  live bundled result artifacts can replay projected resource pressure and
  suppression pressure without callers extracting the nested reports by hand.
  Mission-state `source_timeline_diff_report` inputs now replay removed-work
  rows into branch-local target-revisit and downlink-completion pressure, and
  mission-state `source_result_artifact` / `result_artifact` wrappers that embed
  timeline-diff or timeline-transition-application reports replay through those
  same branch-local timeline pressure paths while inheriting wrapper trust
  boundaries. Branch-generated candidate sources list typed
  `source_report_input_paths` so source reports that drive refresh objectives
  remain inspectable alongside operational-feedback provenance. Mission-state `source_constraint_report`
  inputs now replay failed or warning resource-margin and routed
  downlink-shortfall rows into the same branch-local refresh pressure path as
  prior-plan constraint reports while preserving trust-boundary evidence and
  `mission_state.source_constraint_report` in generated candidate source audit
  paths. Mission-state result-artifact wrappers can carry the same constraint
  rows as embedded `constraint_report` or `source_constraint_report` artifacts,
  including list-valued report keys that retain indexed source paths, while
  inheriting wrapper trust boundaries. Mission-state
  `source_objective_satisfaction_report` inputs likewise
  replay unmet or partial downlink-completion rows into branch-local refresh
  pressure while preserving `mission_state.source_objective_satisfaction_report`
  as candidate-source audit evidence instead of duplicating the same report as
  an additional refresh objective. Mission-state
  `source_objective_tradeoff_report` and `source_score_term_report` inputs now
  replay routed collection-latency and downlink-gap rows through the same
  branch-local refresh pressure paths as prior-plan reports, preserving their
  trust-boundary evidence and `mission_state.source_*_report` audit paths on
  generated branch candidate sources without reintroducing them as duplicate raw
  refresh objectives. These objective and score report classes can also replay
  from mission-state `source_result_artifact` / `result_artifact` wrappers while
  preserving wrapper trust boundaries and indexed paths for list-valued embedded
  report keys. Repair-generated `candidate_refresh.v1` sources also
  enumerate supplied `candidate_refresh.mission_state` report inputs for the
  same objective, resource, contact, station-calendar, freshness, budget,
  candidate-diff, and timeline-diff report classes in
  `source_report_input_paths`, keeping passive report inputs auditable without
  forcing them into branch events. V3 branch-generated refresh requests now
  populate the non-objective mission-state source-report bundle through the
  same wrapper-aware report discovery used for live branch replay, so
  communications, resource, timeline-diff, command-window, maneuver-review,
  freshness, budget, and candidate-diff reports carried under either canonical
  report keys or `source_*_report` keys inside mission-state result-artifact
  wrappers remain visible to branch replay and CandidateRefresh provenance even
  when an unrelated branch event triggered the refresh, without reintroducing
  objective and constraint reports as duplicate raw refresh objectives.
  Candidate-source audit paths are also populated from CandidateRefresh's
  normalized source-report summary, so mission-state operator-review packages
  and Cadence-import manifests that preserve schema-validation rows surface
  their replay paths in both `source_report_input_paths` and
  `candidate_refresh_request_source_report_input_paths`.
  Mission-state `source_link_capacity_report`
  inputs now replay selected or actual downlink shortfall rows into branch-local
  downlink-completion pressure and risk evidence while deriving station
  throughput feedback from realized throughput rows, preserving source windows,
  source activity IDs, trust-boundary evidence, and
  `mission_state.source_link_capacity_report` candidate-source audit paths;
  candidate insertion still depends on matching refreshed or supplied downlink
  candidates. Mission-state `source_contact_filter_report` inputs now replay
  suppressed downlink rows into the same branch-local contact-filter pressure
  path as prior-plan reports, preserving nested station IDs, source windows,
  downlink demand lineage, trust-boundary evidence, and
  `mission_state.source_contact_filter_report` candidate-source audit paths.
  Mission-state `source_contact_allocation_report` inputs now replay deferred,
  blocked, or policy-blocked downlink rows into the same branch-local
  allocation pressure path as prior-plan reports, while unavailable, reserved,
  or zero-capacity station-block rows also replay as branch-local ground-network
  state before regenerated contacts are filtered. These rows preserve
  allocation status and reason, source windows, downlink demand lineage,
  trust-boundary evidence, source allocation evidence on the resulting
  contact-filter and allocation rows, including reduced-capacity policy
  decisions, and `mission_state.source_contact_allocation_report`
  candidate-source audit paths. Mission-state `source_contact_contention_report`
  conflict groups now replay conflicted downlink contacts into branch-local
  contention pressure, preserving group/contact IDs, station/spacecraft timing,
  source-window and downlink-demand lineage, required operator action, and
  trust-boundary evidence while invalid contact inputs remain passive
  provenance; `source_contact_contention_resolution_report` inputs replay deferred downlink
  recommendations into the same branch-local contention pressure path as
  prior-plan reports, preserving selected/deferred contact identity,
  source-window lineage, selection reason, priority source, review status,
  trust-boundary evidence, and
  `mission_state.source_contact_contention_resolution_report` candidate-source
  audit paths. Mission-state `source_result_artifact` / `result_artifact`
  wrappers can carry station-calendar, contact-allocation, contact-filter,
  contact-contention, contact-contention-resolution, and link-capacity reports
  through those same branch-local communications pressure paths, with wrapper
  trust boundaries inherited by nested reports that do not declare their own.
  Mission-state `source_contact_intent` and
  `source_contact_intents` rows now replay blocked, invalid, or missing-import
  downlink intent gates through the same branch-local contact-intent pressure
  path as prior-plan intent rows, preserving policy, reservation, timing,
  station-calendar, trust-boundary, and `mission_state.source_contact_intent`
  feedback-source evidence without treating non-report intent rows as
  `source_report_input_paths`. Candidate-refresh provenance still emits an
  explicit `contact_intent` source summary for those rows so branch-local
  pressure can be audited without reopening each embedded intent. Those
  contact-intent inputs can also be bundled
  in mission-state `source_result_artifact` /
  `result_artifact` wrappers as `source_contact_intent`, `contact_intent`,
  `source_contact_intents`, or `contact_intents`, inheriting wrapper trust
  boundaries while keeping row feedback-source paths on the nested intent row.
  Mission-state `source_station_calendar_report`
  inputs now replay affected contacts and provider-calendar contention groups
  into the same branch-local station-calendar pressure path as prior-plan
  reports, preserving reservation owner/status, provider entry IDs,
  trust-boundary evidence, and `mission_state.source_station_calendar_report`
  candidate-source audit paths even when event feedback points at a report
  subpath such as `.provider_calendar_contention_groups`. Mission-state
  `source_timeline_transition_application_report` inputs now feed the same
  timeline-diff branch-local refresh path as prior-plan transition application
  reports, preserving `application_status`, selected-activity context,
  trust-boundary evidence, and
  `mission_state.source_timeline_transition_application_report`
  candidate-source audit paths from the `.applications` report subpath.
  Mission-state `source_operator_review_package`,
  `operator_review_package`, `source_cadence_import_manifest`, and
  `cadence_import_manifest` inputs now survive V3 request normalization and
  replay through the same branch-local review/import pressure and
  operational-feedback provenance paths as prior-plan handoff artifacts,
  including timeline-diff handoff rows that derive downlink recovery pressure,
  while preserving package or manifest trust-boundary evidence on the live
  mission-state source paths.
  Mission-state standalone `source_realized_activity`,
  `realized_activity`, `source_realized_activities`,
  `source_realized_state_snapshot`, `realized_state_snapshot`, and
  `source_realized_state` inputs now replay the same source-specific
  branch-local realized-feedback events as prior-plan standalone realized
  activity artifacts, preserving mission-state source paths, inherited snapshot
  trust boundaries, planned-activity context, and contact, throughput,
  observation-quality, command, and maneuver feedback fields. Those rows also
  merge into strategy-level `operational_feedback` and appear as
  `mission_state.realized_activity` in operational-feedback provenance with
  source paths, activity-type, direction, Cadence import status, realized-status,
  feedback-weight, and trust-boundary evidence.
  Mission-state `source_result_artifact` / `result_artifact` wrappers can carry
  those same realized rows as `source_realized_activity`, `realized_activity`,
  `source_realized_activities`, `realized_activities`,
  `source_realized_state_snapshot`, `realized_state_snapshot`,
  `source_realized_state`, or `realized_state`, preserving nested source paths
  and inherited wrapper trust boundaries through the same realized-feedback
  replay. Prior-plan result-artifact wrappers can use the same canonical or
  adapter-facing `source_*` realized-activity and realized-state snapshot keys,
  with V3 preserving the nested wrapper path and inherited trust boundary for
  contact, throughput, observation-quality, command, and maneuver feedback
  branches. Prior-plan and mission-state `operator_review_package` and
  `cadence_import_manifest` fields, plus wrapper-carried
  `source_operator_review_package`,
  `operator_review_package`, `source_cadence_import_manifest`, or
  `cadence_import_manifest` bundles, can be single maps or lists, with indexed
  source paths and any direct or inherited wrapper trust boundaries preserved
  when their command-window review/import rows become branch-local command
  feedback. Strategy-level `operational_feedback_provenance.sources` keeps the
  stable aggregate merge-order source label while also exposing those indexed
  `source_report_paths`; replayed `rows.source_operational_feedback` sources use
  the same pattern for direct review rows and nested Cadence import
  `source_review_row` feedback.
  When V3 derives operational feedback directly from
  `mission_state.realized_activities`, provider `feedback_weight`,
  `feedback_sample_weight`, `sample_weight`, and `confidence_weight` values
  accept clean numeric strings and apply to contact success, station throughput,
  observation success, observation-quality score/status/source, cloud-cover,
  blur, command success, maneuver success, and target-priority averages before
  branch-local candidate refresh consumes those factors; reviewed
  operator-review and Cadence-import realized-feedback rows replay the same
  target-keyed observation-quality maps without requiring the original feedback
  report; the source provenance records the
  weighted row count, any declared feedback-weight source labels, and
  per-field/key `feedback_trust_boundaries` derived from direct telemetry rows
  that produced contact, throughput, demand, command, maneuver, observation, or
  resource feedback. Zero feedback weights are accepted as explicit
  no-confidence rows and excluded from effective aggregation, while negative or
  malformed feedback weights are preserved as invalid realized-feedback
  provenance and excluded from effective weighted aggregation. Malformed
  direct realized-activity station, target, spacecraft, resource, source-window,
  scenario, or activity identities are excluded from derived feedback and
  retained as invalid `mission_state.realized_activities` feedback provenance
  for operator-review and import handoff rows.
  The provenance object records the deterministic merge order and each
  contributing feedback source, including prior repair reports, mission-state
  telemetry, mission-state operational-timeline reports, mission-state
  timeline-feedback reports, embedded mission-state feedback, supplied
  candidate-refresh feedback, and explicit request overrides.
  Explicit request and mission-state operational-feedback maps may preserve
  multiple `trust_boundaries` plus per-field `feedback_trust_boundaries`, which
  derived branch events use when a single default trust boundary would be
  ambiguous.
  It also records `effective_sources` per final feedback key plus
  `overridden_sources` for lower-precedence sources, so Cadence review adapters
  can audit when explicit operator/request feedback superseded a supplied
  candidate-refresh feedback map without replaying the merge.
  When a timeline-feedback report or candidate-refresh artifact is used as a
  source, its nested `operational_feedback_provenance` is preserved on the V3
  feedback source instead of flattening the derived feedback map into missing
  trust evidence. Timeline-feedback sources include field/key
  `feedback_trust_boundaries` for downlink-demand maps and resource override
  maps, so replayed downlink-demand and resource-pressure branch events keep
  the same operational trust boundary as the source row that produced the
  feedback. Strategy recommendation review rows
  and selected strategy-recommendation Cadence import rows also carry the same
  feedback context as `operational_feedback_*` fields plus
  schema-typed `source_operational_feedback_provenance`, so routing tools can
  inspect declared/missing trust-boundary status, flattened
  `operational_feedback_trust_boundaries`, field-keyed
  `operational_feedback_field_trust_boundaries`, accepted
  `source_operational_feedback` maps, and availability-override aliases without
  unpacking the full strategy artifact. Selected strategy recommendations also
  emit `operational_feedback_driver` explanation rows when the recommended
  branch score includes success-rate or station-throughput feedback
  adjustments; those driver rows now preserve observation-quality score,
  status/source, cloud-cover, and blur fields when quality evidence drives the
  selected observation-success factor. `objective_satisfaction` explanation rows mirror the
  selected branch's priority-commitment, downlink-completion, coverage, revisit,
  and collection-latency count/ratio evidence. Risk-driver explanation rows preserve the same concrete
  activity, scenario, station, spacecraft, target, and numeric-or-boolean risk
  values exposed by the selected branch risk indicators, so command-feedback
  risks keep their command activity and scenario context. Strategy
  recommendation review rows and Cadence import gates also flatten the
  selected recommendation's `risk_types`, `activity_ids`, `scenario_ids`,
  `ground_station_ids`, `spacecraft_ids`, and `target_ids`, so adapter queues can
  route risk-bearing recommendations without reopening nested branch artifacts.
  Recommendation explanations also emit `branch_event_summary` rows when the
  recommended branch carries what-if events, including event count/type evidence,
  status-transition type/category/reason summaries, operator-review requirement
  counts, and combined source branch IDs. Branch event lineage fields are normalized to
  canonical string `source_branch_id` values and sorted unique
  `source_branch_ids` arrays, dropping malformed non-string lineage entries,
  before branch comparison, operator review, and Cadence import consume them.
  Branch-comparison event aggregation applies the same string-only filtering to
  event types and lineage IDs before sorting report fields. Branch event
  trust-boundary normalization now promotes a valid top-level or provenance
  trust boundary string to the event row and drops malformed direct values
  before declared/missing status counts are computed.
  Branch events also canonicalize `station_id` aliases into string
  `ground_station_id` values before branch repair, risk rows, and contact
  routing consume them. Scalar event routing identifiers such as event `id`,
  `scenario_id`, `activity_id`, `target_id`, and `source_activity_id` are
  likewise kept only when they normalize to non-empty strings, and list-shaped
routing selectors such as source-activity, target, and allowed-scenario IDs
are de-duplicated after the same string-only normalization while preserving
declared order. Provider-calendar and station-reservation IDs now use that same
stable-ID normalization on branch events, and provider-calendar entry,
reservation, direction, owner, status, and source-lineage lists are preserved as
ordered, de-duplicated string arrays. Branch event timing aliases `start_s` /
`end_s` and
`actual_start_s` / `actual_end_s` are parsed when numeric and emitted only as
canonical `starts_at_s` / `ends_at_s` and `actual_starts_at_s` /
  `actual_ends_at_s` fields; inverted event intervals are collapsed to a
  zero-duration interval at the normalized start boundary. Clean
  unit-interval branch-event factors parse numeric strings and are accepted
  only inside `[0, 1]`; out-of-range numeric factors are preserved as invalid
  branch-event evidence and warnings instead of being clamped into candidate
  scoring, while malformed values are dropped. Non-negative branch-event
  scalar fields likewise parse numeric strings only when they are zero or
  positive; negative values are preserved as invalid branch-event evidence and
  warnings instead of being floored into candidate scoring, while malformed
  values are dropped.
  Branch-authored resource-margin pressure events can infer their
  `resource_field` from clean numeric-string margin aliases such as
  `storage_capacity_margin`, `downlink_capacity_margin`, `battery_soc`, or
  `battery_state_of_charge`.
  Mission-state downlink-completion and collection-latency objectives parse
  clean numeric-string required contacts, required downlink volume, latency
  limits, and objective window bounds before deriving branch-local refreshes;
  branch-local planned/source downlink activities parse clean numeric-string
  timing aliases, throughput values, station-capacity fractions, and selected
  activity scores before matching objective windows, volume requirements, and
  strategic branch scoring, and reduced-capacity overlays apply to normalized
  candidate scores; numeric-string branch-local candidate activity
  scores, planning-horizon durations, and
  branch-refresh output cadences
  normalize before candidate ordering, replacement selection, timeline ranking,
  and default objective-window fallback. Campaign scoring-policy weights,
  downlink rates, rank limits, max-timeline-activity limits, and minimum
  activity-duration constraints also parse clean numeric strings before
  candidate generation and ranking. Mission-state ground-network capacity
  fractions and station-window timing aliases also normalize from clean numeric
  strings before branch derivation and branch-local refresh request generation.
  Campaign target priorities, realized revisit priorities, and urgent-target
  branch priorities likewise parse clean numeric strings before observation
  scoring and branch-local target insertion; target specs from catalogs,
  objectives, and branch events normalize clean numeric-string latitude,
  longitude, minimum-elevation, and priority fields before branch-local refresh
  generation; and explicit branch
	  `allow_placeholder` flags normalize trimmed case-insensitive JSON-style boolean strings, including
	  `"1"` / `"0"`, before urgent-target staging. V2 repair policy preservation
	  and locked-change
	  booleans also normalize trimmed case-insensitive JSON-style boolean strings before timeline-protection
	  decisions, and V1 campaign `avoid_eclipse` constraints normalize trimmed case-insensitive JSON-style
	  boolean strings before candidate filtering. V3 strategy request parsing also
	  preserves explicit `false` atom/string alias values for branch derivation
	  flags, so alternate-key `true` values cannot re-enable derived branches.
	  Malformed values remain missing/default evidence.
