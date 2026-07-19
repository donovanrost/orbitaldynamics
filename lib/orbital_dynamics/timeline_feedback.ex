defmodule OrbitalDynamics.TimelineFeedback do
  @moduledoc """
  Reconciles planned timeline activities with realized feedback rows.

  This is an artifact helper only. It compares identifiers, status, and timing
  fields so repair and operator-review flows can reason about execution feedback
  without mutating schedules or executing commands.
  """

  @schema_contract "timeline_feedback_report.v1"
  @activity_state_schema_contract "timeline_activity_state.v1"
  @report_statuses ~w(matched planned_only realized_only)
  @match_strategies ~w(
    activity_id
    ambiguous_timeline_id
    planned_activity_id
    timeline_id
    unmatched_planned
    unmatched_realized
  )
  @planned_protection_decisions ~w(mutable preserve review_change)
  @realized_terminal_statuses ~w(completed executed partial missed failed delayed canceled cancelled rejected)
  @realized_completion_statuses ~w(completed executed)
  @realized_failure_statuses ~w(missed failed canceled cancelled rejected)
  @realized_feedback_match_statuses ~w(matched)
  @lifecycle_event_realized_statuses %{
    "approve" => "approved",
    "reject" => "rejected",
    "lock" => "locked",
    "start_execution" => "executing",
    "record_execution" => "executed",
    "record_completion" => "completed",
    "record_partial" => "partial",
    "record_failure" => "failed",
    "record_miss" => "missed",
    "delay" => "delayed",
    "cancel" => "canceled"
  }
  @command_contact_directions ~w(command uplink)
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @realized_status_policy {
    @realized_terminal_statuses,
    @realized_feedback_match_statuses,
    @lifecycle_event_realized_statuses
  }

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Timeline}

  alias OrbitalDynamics.TimelineFeedback.{
    ActivityState,
    ArtifactValue,
    DownlinkDemandFeedback,
    ExecutionUncertainty,
    FeedbackAggregation,
    LinkContext,
    OperationalContext,
    OperationalFeedbackExclusion,
    OperationalFeedbackProvenance,
    OutcomeValue,
    ProviderResult,
    ReconciliationCommunicationsEvidence,
    ReconciliationIdentity,
    ReconciliationLifecycleEvidence,
    ReconciliationObservationEvidence,
    ReconciliationOutcomeEvidence,
    ReconciliationPlanEvidence,
    ReconciliationRealizedIngressEvidence,
    ReconciliationResourceEvidence,
    ReconciliationStationCalendarEvidence,
    ReconciliationTimingEvidence,
    RealizedFeedbackValidation,
    RealizedIdentity,
    RealizedStatus,
    ResourceFeedback,
    StationCalendarContext,
    SuccessFactor,
    ThermalContext,
    Throughput
  }

  @doc """
  Declares the feedback reconciliation model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      activity_state_artifact_contract: @activity_state_schema_contract,
      model: :planned_vs_realized_activity_reconciliation,
      validation_level: :artifact_contract,
      planned_key: :id,
      realized_key: :id,
      report_statuses: @report_statuses,
      feedback_kinds: Timeline.capabilities().operational_kinds,
      match_strategies: @match_strategies,
      cadence_import_statuses: Timeline.capabilities().cadence_import_statuses,
      planned_protection_decisions: @planned_protection_decisions,
      supported_realized_statuses: @realized_terminal_statuses,
      realized_completion_statuses: @realized_completion_statuses,
      realized_failure_statuses: @realized_failure_statuses,
      realized_feedback_match_statuses: @realized_feedback_match_statuses,
      lifecycle_event_realized_statuses: @lifecycle_event_realized_statuses,
      station_capacity_fraction_paths: StationCalendarContext.capacity_fraction_paths(),
      station_capacity_percent_paths: StationCalendarContext.capacity_percent_paths(),
      station_capacity_value_paths: StationCalendarContext.capacity_value_path_metadata(),
      source_station_capacity_fraction_paths: StationCalendarContext.capacity_fraction_paths(),
      source_station_capacity_percent_paths: StationCalendarContext.capacity_percent_paths(),
      source_station_capacity_value_paths: StationCalendarContext.capacity_value_path_metadata(),
      command_contact_directions: @command_contact_directions,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      feedback_helpers: [
        :reconcile,
        :operational_feedback,
        :activity_state,
        :normalize_realized_activity,
        :normalize_realized_activities
      ],
      public_facades: [
        :reconcile_timeline_feedback,
        :timeline_operational_feedback,
        :timeline_activity_state,
        :normalize_realized_timeline_activity,
        :normalize_realized_timeline_activities
      ],
      row_semantics: [
        :report_status,
        :report_status_counts,
        :feedback_kind,
        :feedback_kind_counts,
        :match_strategy,
        :match_strategy_counts,
        :activity_state,
        :activity_state_count_maps,
        :normalized_realized_activity,
        :normalized_realized_activity_list,
        :duplicate_realized_feedback,
        :duplicate_realized_match_count,
        :duplicate_realized_feedback_count,
        :ambiguous_planned_timeline_match,
        :ambiguous_timeline_match_count,
        :ambiguous_timeline_feedback_count,
        :command_contact_directions,
        :command_success,
        :contact_success,
        :contact_success_factor,
        :throughput_delta_mb,
        :command_success_factor,
        :observation_success_factor,
        :maneuver_success_factor,
        :maneuver_result,
        :maneuver_delta_v_feedback,
        :execution_uncertainty,
        :execution_uncertainty_declared_count,
        :execution_uncertainty_missing_count,
        :data_volume_delta_mb,
        :downlink_demand_mb,
        :downlink_demand_sources,
        :target_priority_overrides,
        :resource_margin_overrides,
        :resource_availability_overrides,
        :resource_feedback_context,
        :feedback_status,
        :realized_completion_statuses,
        :realized_failure_statuses,
        :realized_feedback_match_statuses,
        :lifecycle_event_status_derivation,
        :feedback_weight,
        :completed_fraction_feedback_factor,
        :product_identity,
        :observation_quality_context,
        :pointing_context,
        :attitude_context,
        :link_profile_context,
        :link_quality_context,
        :lighting_context,
        :thermal_context,
        :resource_identity,
        :timing_delta_s,
        :timing_variance_threshold,
        :contact_identity_match_status,
        :observation_identity_match_status,
        :normalized_provider_feedback_scalars,
        :provider_result_map_value_keys,
        :actual_data_rate_throughput_derivation,
        :cadence_import_identity,
        :cadence_import_status,
        :cadence_import_status_counts,
        :realized_provider_provenance,
        :realized_source_quality,
        :activity_state_realized_provider_counts,
        :activity_state_realized_source_quality_counts,
        :activity_state_realized_trust_boundary_status,
        :station_calendar_capacity_fraction_context,
        :station_calendar_capacity_percent_aliases,
        :station_calendar_reservation_expiration_context,
        :station_capacity_value_paths,
        :source_station_capacity_value_paths,
        :derived_operational_feedback,
        :operational_feedback_provenance,
        :operational_feedback_source_counts,
        :operational_feedback_input_keys,
        :operational_feedback_realized_activity_count,
        :operational_feedback_trust_boundary_status,
        :operational_feedback_source_quality_counts,
        :operational_feedback_exclusion,
        :operational_feedback_excluded_count,
        :operator_review_package,
        :planned_protection_decision,
        :planned_protection_decision_counts,
        :timeline_protection_evidence,
        :timeline_integrity_review,
        :invalid_activity_input_review,
        :invalid_realized_feedback_input_review,
        :invalid_realized_feedback_unit_interval_review
      ],
      known_limits: [
        :artifact_level_only,
        :no_schedule_mutation,
        :no_command_execution,
        :no_operator_authority_decision,
        :timing_deltas_require_declared_actual_times
      ]
    }
  end

  @doc """
  Builds a deterministic feedback reconciliation report.
  """
  def reconcile(planned_activities, realized_activities, opts \\ [])

  def reconcile(planned_activities, realized_activities, opts)
      when is_list(planned_activities) and is_list(realized_activities) and is_list(opts) do
    validate_missing_dependencies? = Keyword.get(opts, :validate_missing_dependencies?, false)
    timing_variance_threshold_s = timing_variance_threshold(opts)
    planned = normalize_planned_rows(planned_activities, validate_missing_dependencies?)
    realized = normalize_realized_rows(realized_activities)

    planned_by_id = Map.new(planned, &{&1["id"], &1})
    planned_by_timeline_id = planned_by_timeline_id(planned)

    realized_by_planned_id =
      realized
      |> Enum.reduce(%{}, fn realized_row, matched_rows ->
        {planned_id, strategy, ambiguity} =
          realized_match(realized_row, planned_by_id, planned_by_timeline_id)

        matched_row =
          realized_row
          |> Map.put("match_strategy", strategy)
          |> Map.merge(ambiguity || %{})
          |> put_realized_match_context(planned_id, strategy, ambiguity)

        Map.update(matched_rows, planned_id, [matched_row], &[matched_row | &1])
      end)
      |> Map.new(fn {planned_id, realized_rows} ->
        {planned_id, Enum.sort_by(realized_rows, & &1["id"])}
      end)

    rows =
      (Map.keys(planned_by_id) ++ Map.keys(realized_by_planned_id))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.map(
        &reconciliation_row(
          &1,
          planned_by_id,
          realized_by_planned_id,
          timing_variance_threshold_s
        )
      )

    status_counts = status_counts(rows)
    feedback_kind_counts = count_by(rows, "feedback_kind")
    match_strategy_counts = count_by(rows, "match_strategy")
    cadence_import_status_counts = count_by(rows, "cadence_import_status")
    planned_protection_decision_counts = count_by(rows, "planned_protection_decision")
    execution_uncertainty_declared_count = execution_uncertainty_status_count(rows, "declared")
    execution_uncertainty_missing_count = execution_uncertainty_status_count(rows, "missing")
    operational_feedback_excluded_count = Enum.count(rows, &operational_feedback_excluded?/1)
    operational_feedback = operational_feedback(rows)

    operational_feedback_provenance =
      operational_feedback_provenance(rows, operational_feedback, %{
        "source_report_status_counts" => status_counts,
        "source_feedback_kind_counts" => feedback_kind_counts,
        "source_match_strategy_counts" => match_strategy_counts,
        "source_cadence_import_status_counts" => cadence_import_status_counts,
        "source_planned_protection_decision_counts" => planned_protection_decision_counts,
        "source_execution_uncertainty_declared_count" => execution_uncertainty_declared_count,
        "source_execution_uncertainty_missing_count" => execution_uncertainty_missing_count,
        "source_operational_feedback_excluded_count" => operational_feedback_excluded_count
      })

    %{
      "schema_contract" => @schema_contract,
      "model" => "planned_vs_realized_activity_reconciliation",
      "planned_count" => length(planned),
      "realized_count" => length(realized),
      "row_count" => length(rows),
      "duplicate_realized_match_count" => duplicate_realized_match_count(rows),
      "duplicate_realized_feedback_count" => duplicate_realized_feedback_count(rows),
      "ambiguous_timeline_match_count" => ambiguous_timeline_match_count(rows),
      "ambiguous_timeline_feedback_count" => ambiguous_timeline_feedback_count(rows),
      "status_counts" => status_counts,
      "feedback_kind_counts" => feedback_kind_counts,
      "match_strategy_counts" => match_strategy_counts,
      "cadence_import_status_counts" => cadence_import_status_counts,
      "planned_protection_decision_counts" => planned_protection_decision_counts,
      "execution_uncertainty_declared_count" => execution_uncertainty_declared_count,
      "execution_uncertainty_missing_count" => execution_uncertainty_missing_count,
      "operational_feedback_excluded_count" => operational_feedback_excluded_count,
      "operational_feedback" => operational_feedback,
      "model_limits" => model_limits(),
      "rows" => rows,
      "assumptions" =>
        %{
          "identity_match" =>
            "planned.id matches realized.planned_activity_id, realized.timeline_id, or realized.id; duplicate planned timeline identities are review-gated as ambiguous",
          "timing_delta" => "actual time minus planned time when both are declared",
          "boundary" => "report_only_no_schedule_mutation",
          "dependency_model" =>
            "planned dependencies and exclusivity are checked inside the artifact when referenced rows are present; missing dependency checks are opt-in and schedules are not mutated",
          "missing_dependency_validation" =>
            if(validate_missing_dependencies?, do: "enabled", else: "disabled")
        }
        |> maybe_put("timing_variance_threshold_s", timing_variance_threshold_s)
    }
    |> maybe_put("operational_feedback_provenance", operational_feedback_provenance)
    |> then(fn report ->
      operator_review_package = OperatorReview.from_timeline_feedback_report(report)

      report
      |> Map.put("operator_review_package", operator_review_package)
      |> Map.put(
        "cadence_import_manifest",
        CadenceImport.from_operator_review_package(operator_review_package)
      )
    end)
  end

  def reconcile(_planned_activities, _realized_activities, _opts),
    do: raise(ArgumentError, "planned and realized activities must be lists")

  @doc """
  Normalizes one realized activity feedback row into the report-compatible shape.

  This exposes the same artifact-only realized feedback normalization used by
  `reconcile/3` without requiring callers to build a planned-vs-realized report.
  """
  def normalize_realized_activity(activity, opts \\ [])

  def normalize_realized_activity(activity, opts) when is_map(activity) do
    sequence = Keyword.get(opts, :sequence, 1)
    realized_input_to_row({activity, sequence})
  end

  def normalize_realized_activity(_activity, _opts),
    do: raise(ArgumentError, "realized activity must be a map")

  @doc """
  Normalizes realized activity feedback rows into report-compatible rows.
  """
  def normalize_realized_activities(activities, opts \\ [])

  def normalize_realized_activities(activities, _opts) when is_list(activities) do
    normalize_realized_rows(activities)
  end

  def normalize_realized_activities(_activities, _opts),
    do: raise(ArgumentError, "realized activities must be a list")

  @doc """
  Normalizes one planned activity and one realized feedback row into a compact
  artifact-only activity state.

  The state is derived from the same reconciliation engine as
  `reconcile/3`. It is useful for adapter boundaries that need normalized
  planned/realized state, status transition, protection, and review evidence
  without building a full timeline feedback artifact.
  """
  def activity_state(planned_activity, realized_activity, opts \\ [])

  def activity_state(nil, nil, _opts) do
    raise ArgumentError, "planned or realized activity is required"
  end

  def activity_state(planned_activity, realized_activity, opts) when is_list(opts) do
    planned = optional_activity_state_input(planned_activity, "planned activity")
    realized = optional_activity_state_input(realized_activity, "realized activity")

    report = reconcile(planned, realized, opts)
    rows = Map.get(report, "rows", [])
    lifecycle_state = Timeline.activity_lifecycle_state(planned_activity, realized_activity)

    ActivityState.build(rows, lifecycle_state, model_limits())
  end

  def activity_state(_planned_activity, _realized_activity, _opts) do
    raise ArgumentError, "activity state options must be a keyword list"
  end

  defp optional_activity_state_input(nil, _label), do: []
  defp optional_activity_state_input(%{} = activity, _label), do: [activity]

  defp optional_activity_state_input(_activity, label) do
    raise ArgumentError, "#{label} must be a map or nil"
  end

  defp timing_variance_threshold(opts) do
    case Keyword.get(opts, :timing_variance_threshold_s) do
      value when is_number(value) and value >= 0.0 -> value * 1.0
      _value -> nil
    end
  end

  @doc """
  Derives normalized operational feedback from a timeline feedback report or row list.

  The returned map is shaped for the V3 strategy `operational_feedback` input:
  contact and station-throughput feedback are keyed by ground station, command
  and maneuver feedback by activity, and observation feedback by target. It is
  deterministic and artifact-only; it does not mutate schedules or execute
  workflow.
  """
  def operational_feedback(%{"rows" => rows}) when is_list(rows), do: operational_feedback(rows)

  def operational_feedback(%{rows: rows}) when is_list(rows), do: operational_feedback(rows)

  def operational_feedback(rows) when is_list(rows) do
    rows = Enum.map(rows, &stringify_keys/1)

    %{
      "contact_success_rate" =>
        feedback_average_by(rows, & &1["ground_station_id"], &contact_success_feedback_value/1),
      "station_throughput_factor" =>
        feedback_average_by(rows, & &1["ground_station_id"], &station_throughput_feedback_value/1),
      "observation_success_rate" =>
        feedback_average_by(rows, & &1["target_id"], &observation_success_feedback_value/1),
      "image_quality_score" =>
        feedback_average_by(rows, & &1["target_id"], &image_quality_score_feedback_value/1),
      "image_quality_status" =>
        feedback_text_by(rows, & &1["target_id"], &image_quality_status_feedback_value/1),
      "image_quality_source" =>
        feedback_text_by(rows, & &1["target_id"], &image_quality_source_feedback_value/1),
      "cloud_cover_fraction" =>
        feedback_average_by(rows, & &1["target_id"], &cloud_cover_feedback_value/1),
      "blur_score" => feedback_average_by(rows, & &1["target_id"], &blur_score_feedback_value/1),
      "downlink_demand_mb" => downlink_demand_feedback(rows),
      "downlink_demand_sources" => downlink_demand_sources_feedback(rows),
      "target_priority_overrides" => target_priority_feedback(rows),
      "resource_margin_overrides" => resource_margin_feedback(rows),
      "resource_availability_overrides" => resource_availability_feedback(rows),
      "maneuver_success_rate" =>
        feedback_average_by(rows, & &1["activity_id"], &maneuver_success_feedback_value/1),
      "maneuver_execution_uncertainty" => maneuver_execution_uncertainty_feedback(rows),
      "command_success_rate" =>
        feedback_average_by(rows, & &1["activity_id"], &command_success_feedback_value/1)
    }
  end

  def operational_feedback(_report_or_rows),
    do: raise(ArgumentError, "timeline feedback report or rows are required")

  defp operational_feedback_provenance(rows, operational_feedback, source_counts) do
    OperationalFeedbackProvenance.build(
      rows,
      operational_feedback,
      source_counts,
      @schema_contract,
      operational_feedback_trust_specs()
    )
  end

  defp operational_feedback_trust_specs do
    [
      {"contact_success_rate", & &1["ground_station_id"], &contact_success_feedback_value/1},
      {"station_throughput_factor", & &1["ground_station_id"],
       &station_throughput_feedback_value/1},
      {"observation_success_rate", & &1["target_id"], &observation_success_feedback_value/1},
      {"image_quality_score", & &1["target_id"], &image_quality_score_feedback_value/1},
      {"cloud_cover_fraction", & &1["target_id"], &cloud_cover_feedback_value/1},
      {"blur_score", & &1["target_id"], &blur_score_feedback_value/1},
      {"target_priority_overrides", & &1["target_id"], &target_priority_feedback_value/1},
      {"maneuver_success_rate", & &1["activity_id"], &maneuver_success_feedback_value/1},
      {"command_success_rate", & &1["activity_id"], &command_success_feedback_value/1},
      {"downlink_demand_mb", &downlink_demand_feedback_trust_key/1,
       &downlink_demand_feedback_trust_value/1},
      {"downlink_demand_sources", &downlink_demand_feedback_trust_key/1,
       &downlink_demand_sources_feedback_trust_value/1},
      {"resource_margin_overrides", &resource_feedback_spacecraft_id/1,
       &resource_margin_feedback_trust_value/1},
      {"resource_availability_overrides", &resource_feedback_spacecraft_id/1,
       &resource_availability_feedback_trust_value/1}
    ]
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp normalize_realized_rows(rows) do
    rows
    |> Enum.with_index(1)
    |> Enum.map(&realized_input_to_row/1)
    |> Enum.sort_by(& &1["id"])
  end

  defp realized_input_to_row({%{} = activity, sequence}) do
    source_activity = stringify_keys(activity)

    activity =
      source_activity
      |> normalize_realized_activity_type_alias()
      |> normalize_realized_activity_direction_alias()

    invalid_sections =
      invalid_realized_feedback_unit_interval_sections(activity) ++
        invalid_realized_feedback_nonnegative_number_sections(activity)

    feedback_activity = sanitize_realized_feedback_unit_interval_values(activity)

    case realized_input_identity_issue(activity) do
      nil ->
        if realized_status_supported?(activity) do
          realized_row(feedback_activity, source_activity, invalid_sections)
        else
          invalid_realized_row(
            source_activity,
            sequence,
            invalid_realized_status_reason(activity)
          )
        end

      reason ->
        invalid_realized_row(source_activity, sequence, reason)
    end
  end

  defp realized_input_to_row({activity, sequence}) do
    invalid_realized_row(
      %{"raw_input" => inspect(activity)},
      sequence,
      "invalid_realized_feedback_shape"
    )
  end

  defp normalize_realized_activity_type_alias(%{} = activity) do
    cond do
      present_string?(Map.get(activity, "type")) ->
        activity

      present_string?(Map.get(activity, "activity_type")) ->
        Map.put(activity, "type", String.trim(Map.get(activity, "activity_type")))

      true ->
        activity
    end
  end

  defp normalize_realized_activity_direction_alias(%{} = activity) do
    case Map.get(activity, "direction") do
      direction when is_binary(direction) ->
        case Timeline.normalize_contact_direction(direction) do
          nil -> Map.delete(activity, "direction")
          normalized -> Map.put(activity, "direction", normalized)
        end

      _direction ->
        activity
    end
  end

  defp normalize_planned_rows(rows, validate_missing_dependencies?) do
    normalized_timeline_rows =
      Timeline.normalize_activities(rows,
        validate_missing_dependencies?: validate_missing_dependencies?
      )

    rows
    |> Enum.zip(normalized_timeline_rows)
    |> Enum.map(fn {activity, timeline_row} ->
      activity = planned_activity_for_timeline_row(activity, timeline_row)

      planned_row(activity, timeline_row)
    end)
    |> Enum.sort_by(& &1["id"])
  end

  defp planned_activity_for_timeline_row(_activity, %{"invalid_activity_input" => true} = row),
    do: Map.get(row, "source_activity", %{})

  defp planned_activity_for_timeline_row(activity, _timeline_row),
    do: planned_activity_to_map(activity)

  defp planned_activity_to_map(%OrbitalDynamics.MissionPlan.Activity{} = activity) do
    activity
    |> OrbitalDynamics.MissionPlan.Activity.to_map()
    |> stringify_keys()
  end

  defp planned_activity_to_map(%{} = activity), do: stringify_keys(activity)

  defp planned_row(_activity, %{"invalid_activity_input" => true} = timeline_row) do
    source_activity = Map.get(timeline_row, "source_activity", %{})

    %{
      "id" => Map.get(timeline_row, "activity_id"),
      "type" => "invalid_activity_input",
      "source_activity" => source_activity,
      "status" => "invalid",
      "starts_at_s" => source_activity_value(source_activity, "starts_at_s", "start_s"),
      "ends_at_s" => source_activity_value(source_activity, "ends_at_s", "end_s"),
      "timeline_id" => Map.get(timeline_row, "timeline_id"),
      "timeline_identity" => Map.get(timeline_row, "timeline_identity"),
      "operational_kind" => Map.get(timeline_row, "operational_kind"),
      "direction" => Map.get(source_activity, "direction"),
      "ground_station_id" =>
        Map.get(source_activity, "ground_station_id") || Map.get(source_activity, "station_id"),
      "target_id" => Map.get(source_activity, "target_id"),
      "resource_id" => first_identifier(source_activity, ["resource_id", "resource"]),
      "source_window_id" =>
        Map.get(source_activity, "source_window_id") ||
          get_in(source_activity, ["source_window", "id"]),
      "source_window_type" => get_in(source_activity, ["source_window", "type"]),
      "dependency_activity_ids" => Map.get(timeline_row, "dependency_activity_ids"),
      "dependency_timeline_ids" => Map.get(timeline_row, "dependency_timeline_ids"),
      "exclusive_with_activity_ids" => Map.get(timeline_row, "exclusive_with_activity_ids"),
      "exclusive_with_timeline_ids" => Map.get(timeline_row, "exclusive_with_timeline_ids"),
      "cadence_import_status" => Map.get(timeline_row, "cadence_import_status"),
      "cadence_import_type" => Map.get(timeline_row, "cadence_import_type"),
      "cadence_import_id" => Map.get(timeline_row, "cadence_import_id"),
      "cadence_import_contract" => Map.get(timeline_row, "cadence_import_contract"),
      "has_cadence_import" => Map.get(timeline_row, "has_cadence_import"),
      "required_operator_action" => Map.get(timeline_row, "required_operator_action"),
      "operator_action_reason" => Map.get(timeline_row, "operator_action_reason"),
      "timeline_integrity_status" => Map.get(timeline_row, "timeline_integrity_status"),
      "timeline_integrity_issue_count" => Map.get(timeline_row, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" => Map.get(timeline_row, "timeline_integrity_issue_types"),
      "timeline_integrity_issues" => Map.get(timeline_row, "timeline_integrity_issues"),
      "missing_dependency_activity_ids" =>
        Map.get(timeline_row, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" =>
        Map.get(timeline_row, "missing_dependency_timeline_ids"),
      "dependency_cycle_activity_ids" => Map.get(timeline_row, "dependency_cycle_activity_ids"),
      "dependency_cycle_timeline_ids" => Map.get(timeline_row, "dependency_cycle_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        Map.get(timeline_row, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        Map.get(timeline_row, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        Map.get(timeline_row, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        Map.get(timeline_row, "exclusivity_violation_timeline_ids"),
      "exclusivity_violation_group" => Map.get(timeline_row, "exclusivity_violation_group"),
      "source_activity_context" => Map.get(timeline_row, "activity_context"),
      "invalid_activity_input" => true,
      "invalid_activity_input_reason" => Map.get(timeline_row, "invalid_activity_input_reason")
    }
    |> compact_map()
  end

  defp planned_row(activity, timeline_row) do
    activity_id = required_id!(activity, "id")

    %{
      "id" => activity_id,
      "type" => Map.get(activity, "type"),
      "source_activity" => activity,
      "status" => Map.get(activity, "status"),
      "starts_at_s" =>
        Map.get(timeline_row, "starts_at_s") ||
          first_number(activity, ["starts_at_s", "start_s"]),
      "ends_at_s" =>
        Map.get(timeline_row, "ends_at_s") ||
          first_number(activity, ["ends_at_s", "end_s"]),
      "timeline_id" => Map.get(timeline_row, "timeline_id"),
      "timeline_identity" => Map.get(timeline_row, "timeline_identity"),
      "operational_kind" => Map.get(timeline_row, "operational_kind"),
      "direction" => Map.get(timeline_row, "direction"),
      "ground_station_id" => Map.get(timeline_row, "ground_station_id"),
      "spacecraft_id" => activity_spacecraft_id(activity),
      "target_id" => Map.get(timeline_row, "target_id"),
      "resource_id" => first_identifier(activity, ["resource_id", "resource"]),
      "target_priority" =>
        first_number(activity, ["target_priority", ["metadata", "target_priority"]]),
      "source_window_id" => Map.get(timeline_row, "source_window_id"),
      "source_window_type" => Map.get(timeline_row, "source_window_type"),
      "contact_success_factor" =>
        first_unit_interval_number(activity, [
          "contact_success_factor",
          ["metadata", "contact_success_factor"],
          ["throughput_model", "contact_success_factor"]
        ]),
      "contact_success_factor_source" =>
        Map.get(activity, "contact_success_factor_source") ||
          get_in(activity, ["metadata", "contact_success_factor_source"]) ||
          get_in(activity, ["throughput_model", "confidence_source"]),
      "command_success_factor" =>
        first_unit_interval_number(activity, [
          "command_success_factor",
          ["metadata", "command_success_factor"]
        ]),
      "command_success_factor_source" =>
        Map.get(activity, "command_success_factor_source") ||
          get_in(activity, ["metadata", "command_success_factor_source"]),
      "observation_success_factor" => realized_observation_success_factor(activity),
      "observation_success_factor_source" => realized_observation_success_factor_source(activity),
      "observation_success" => Map.get(activity, "observation_success"),
      "observation_result" =>
        provider_result_artifact_value(Map.get(activity, "observation_result")),
      "feedback_weight" => normalized_feedback_weight(activity),
      "feedback_weight_source" => normalized_feedback_weight_source(activity),
      "maneuver_success_factor" =>
        first_unit_interval_number(activity, [
          "maneuver_success_factor",
          ["metadata", "maneuver_success_factor"]
        ]),
      "maneuver_success_factor_source" =>
        Map.get(activity, "maneuver_success_factor_source") ||
          get_in(activity, ["metadata", "maneuver_success_factor_source"]),
      "delta_v_km_s" => maneuver_delta_v(activity),
      "delta_v_magnitude_km_s" => vector_norm(maneuver_delta_v(activity)),
      "dependency_activity_ids" => Map.get(timeline_row, "dependency_activity_ids"),
      "dependency_timeline_ids" => Map.get(timeline_row, "dependency_timeline_ids"),
      "exclusive_with_activity_ids" => Map.get(timeline_row, "exclusive_with_activity_ids"),
      "exclusive_with_timeline_ids" => Map.get(timeline_row, "exclusive_with_timeline_ids"),
      "cadence_import_status" => Map.get(timeline_row, "cadence_import_status"),
      "cadence_import_type" => Map.get(timeline_row, "cadence_import_type"),
      "cadence_import_id" => Map.get(timeline_row, "cadence_import_id"),
      "cadence_import_contract" => Map.get(timeline_row, "cadence_import_contract"),
      "has_cadence_import" => Map.get(timeline_row, "has_cadence_import"),
      "required_operator_action" => Map.get(timeline_row, "required_operator_action"),
      "operator_action_reason" => Map.get(timeline_row, "operator_action_reason"),
      "superseded_required_operator_action" =>
        Map.get(timeline_row, "superseded_required_operator_action"),
      "superseded_operator_action_reason" =>
        Map.get(timeline_row, "superseded_operator_action_reason"),
      "timeline_integrity_status" => Map.get(timeline_row, "timeline_integrity_status"),
      "timeline_integrity_issue_count" => Map.get(timeline_row, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" => Map.get(timeline_row, "timeline_integrity_issue_types"),
      "timeline_integrity_issues" => Map.get(timeline_row, "timeline_integrity_issues"),
      "missing_dependency_activity_ids" =>
        Map.get(timeline_row, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" =>
        Map.get(timeline_row, "missing_dependency_timeline_ids"),
      "dependency_cycle_activity_ids" => Map.get(timeline_row, "dependency_cycle_activity_ids"),
      "dependency_cycle_timeline_ids" => Map.get(timeline_row, "dependency_cycle_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        Map.get(timeline_row, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        Map.get(timeline_row, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        Map.get(timeline_row, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        Map.get(timeline_row, "exclusivity_violation_timeline_ids"),
      "exclusivity_violation_group" => Map.get(timeline_row, "exclusivity_violation_group"),
      "source_activity_context" => source_activity_context(activity_id, activity, timeline_row),
      "planned_data_volume_mb" => planned_data_volume_mb(activity),
      "estimated_throughput_mb" =>
        first_number(activity, [
          "estimated_throughput_mb",
          "estimated_downlink_mb",
          ["metadata", "estimated_throughput_mb"],
          ["metadata", "estimated_downlink_mb"],
          ["throughput_model", "estimated_throughput_mb"]
        ])
    }
    |> Map.merge(link_context(activity))
    |> Map.merge(station_calendar_context(activity))
    |> Map.merge(activity_execution_uncertainty_context(activity))
    |> Map.merge(operational_context(activity))
    |> Map.merge(thermal_context(activity))
    |> Map.merge(planned_product_context(activity))
    |> compact_map()
  end

  defp realized_row(%{} = activity, source_activity, invalid_sections) do
    activity = stringify_keys(activity)
    source_activity = source_activity || activity
    status = realized_status(activity)
    feedback_status = realized_feedback_status(activity)

    id = realized_id!(activity)

    planned_activity_id =
      identifier(activity, "planned_activity_id") || identifier(activity, "activity_id")

    timeline_id =
      identifier(activity, "timeline_id") || get_in(activity, ["metadata", "timeline_id"])

    %{
      "id" => id,
      "source_activity" => source_activity,
      "realized_activity_id" =>
        identifier(activity, "id") || identifier(activity, "realized_activity_id"),
      "planned_activity_id" => planned_activity_id,
      "timeline_id" => timeline_id,
      "status" => status,
      "feedback_status" => feedback_status,
      "actual_starts_at_s" => first_number(activity, ["actual_starts_at_s", "actual_start_s"]),
      "actual_ends_at_s" => first_number(activity, ["actual_ends_at_s", "actual_end_s"]),
      "type" => Map.get(activity, "type"),
      "direction" => Map.get(activity, "direction"),
      "ground_station_id" => activity_ground_station_id(activity),
      "spacecraft_id" => activity_spacecraft_id(activity),
      "target_id" => activity_target_id(activity),
      "resource_id" => first_identifier(activity, ["resource_id", "resource"]),
      "target_priority" =>
        first_number(activity, ["target_priority", ["metadata", "target_priority"]]),
      "timeline_identity" =>
        realized_timeline_identity(id, planned_activity_id, timeline_id, activity),
      "approval_status" => first_string(activity, ["approval_status", "approval_state"]),
      "locked" => realized_activity_locked(activity),
      "executed" => realized_activity_executed(activity),
      "execution_status" => first_string(activity, ["execution_status", "execution_state"]),
      "source_window_id" =>
        Map.get(activity, "source_window_id") || get_in(activity, ["source_window", "id"]),
      "actual_throughput_mb" => actual_throughput_mb(activity),
      "actual_data_rate_throughput_derivation" =>
        actual_data_rate_throughput_derivation(activity),
      "actual_data_volume_mb" => actual_data_volume_mb(activity),
      "contact_success" => Map.get(activity, "contact_success"),
      "contact_result" => provider_result_artifact_value(Map.get(activity, "contact_result")),
      "contact_success_factor" => realized_contact_success_factor(activity),
      "contact_success_factor_source" => realized_contact_success_factor_source(activity),
      "command_success" => Map.get(activity, "command_success"),
      "command_success_factor" => realized_command_success_factor(activity),
      "command_success_factor_source" => realized_command_success_factor_source(activity),
      "observation_success_factor" => realized_observation_success_factor(activity),
      "observation_success_factor_source" => realized_observation_success_factor_source(activity),
      "observation_success" => Map.get(activity, "observation_success"),
      "observation_result" =>
        provider_result_artifact_value(Map.get(activity, "observation_result")),
      "feedback_weight" => normalized_feedback_weight(activity),
      "feedback_weight_source" => normalized_feedback_weight_source(activity),
      "maneuver_success_factor" =>
        first_unit_interval_number(activity, [
          "maneuver_success_factor",
          ["metadata", "maneuver_success_factor"]
        ]),
      "maneuver_success_factor_source" =>
        Map.get(activity, "maneuver_success_factor_source") ||
          get_in(activity, ["metadata", "maneuver_success_factor_source"]),
      "maneuver_success" => Map.get(activity, "maneuver_success"),
      "delta_v_km_s" => maneuver_delta_v(activity),
      "delta_v_magnitude_km_s" => vector_norm(maneuver_delta_v(activity)),
      "maneuver_result" => provider_result_artifact_value(Map.get(activity, "maneuver_result")),
      "command_result" => provider_result_artifact_value(Map.get(activity, "command_result")),
      "completed_fraction" => normalized_completed_fraction(activity),
      "reason" => Map.get(activity, "reason"),
      "realized_activity_context" =>
        realized_activity_context(id, planned_activity_id, timeline_id, status, activity)
    }
    |> Map.merge(link_context(activity))
    |> Map.merge(station_calendar_context(activity))
    |> Map.merge(activity_execution_uncertainty_context(activity))
    |> Map.merge(operational_context(activity))
    |> Map.merge(thermal_context(activity))
    |> Map.merge(realized_product_context(activity))
    |> Map.merge(realized_provider_context(activity))
    |> compact_map()
    |> put_invalid_realized_feedback_sections(invalid_sections)
  end

  defp invalid_realized_row(source_activity, sequence, reason) do
    id = "invalid_realized_feedback:#{reason}:#{sequence}"
    realized_activity_id = source_realized_activity_id(source_activity) || id
    planned_activity_id = invalid_realized_planned_activity_id(source_activity)
    timeline_id = invalid_realized_timeline_id(source_activity)
    unsupported_status = unsupported_realized_status(source_activity, reason)

    %{
      "id" => id,
      "source_activity" => source_activity,
      "realized_activity_id" => realized_activity_id,
      "planned_activity_id" => planned_activity_id,
      "timeline_id" => timeline_id,
      "status" => "invalid",
      "reason" => reason,
      "invalid_realized_feedback_input" => true,
      "invalid_realized_feedback_input_reason" => reason,
      "unsupported_realized_status" => unsupported_status,
      "realized_activity_context" =>
        %{
          "realized_activity_id" => realized_activity_id,
          "planned_activity_id" => planned_activity_id,
          "timeline_id" => timeline_id,
          "invalid_realized_feedback_input" => true,
          "invalid_realized_feedback_input_reason" => reason,
          "unsupported_realized_status" => unsupported_status,
          "source_activity" => source_activity
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp invalid_realized_feedback_unit_interval_sections(activity),
    do: RealizedFeedbackValidation.invalid_realized_feedback_unit_interval_sections(activity)

  defp invalid_realized_feedback_nonnegative_number_sections(activity),
    do: RealizedFeedbackValidation.invalid_realized_feedback_nonnegative_number_sections(activity)

  defp sanitize_realized_feedback_unit_interval_values(activity),
    do: RealizedFeedbackValidation.sanitize_realized_feedback_unit_interval_values(activity)

  defp put_invalid_realized_feedback_sections(row, invalid_sections),
    do: RealizedFeedbackValidation.put_invalid_realized_feedback_sections(row, invalid_sections)

  defp source_activity_context(activity_id, activity, timeline_row) do
    (Map.get(timeline_row, "activity_context") || %{})
    |> Map.merge(%{
      "activity_id" => activity_id,
      "timeline_id" => Map.get(timeline_row, "timeline_id"),
      "activity_type" => Map.get(activity, "type"),
      "scenario_id" => Map.get(activity, "scenario_id"),
      "status" => Map.get(activity, "status"),
      "approval_status" => Map.get(activity, "approval_status"),
      "direction" => Map.get(timeline_row, "direction"),
      "ground_station_id" => Map.get(timeline_row, "ground_station_id"),
      "spacecraft_id" => activity_spacecraft_id(activity),
      "target_id" => Map.get(timeline_row, "target_id"),
      "resource_id" => first_identifier(activity, ["resource_id", "resource"]),
      "target_priority" =>
        first_number(activity, ["target_priority", ["metadata", "target_priority"]]),
      "source_window_id" => Map.get(timeline_row, "source_window_id"),
      "timeline_identity" => Map.get(timeline_row, "timeline_identity"),
      "timeline_integrity_status" => Map.get(timeline_row, "timeline_integrity_status"),
      "timeline_integrity_issue_count" => Map.get(timeline_row, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" => Map.get(timeline_row, "timeline_integrity_issue_types"),
      "timeline_integrity_issues" => Map.get(timeline_row, "timeline_integrity_issues"),
      "missing_dependency_activity_ids" =>
        Map.get(timeline_row, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" =>
        Map.get(timeline_row, "missing_dependency_timeline_ids"),
      "dependency_cycle_activity_ids" => Map.get(timeline_row, "dependency_cycle_activity_ids"),
      "dependency_cycle_timeline_ids" => Map.get(timeline_row, "dependency_cycle_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        Map.get(timeline_row, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        Map.get(timeline_row, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        Map.get(timeline_row, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        Map.get(timeline_row, "exclusivity_violation_timeline_ids"),
      "exclusivity_violation_group" => Map.get(timeline_row, "exclusivity_violation_group"),
      "maneuver_success_factor" =>
        first_unit_interval_number(activity, [
          "maneuver_success_factor",
          ["metadata", "maneuver_success_factor"]
        ]),
      "maneuver_success_factor_source" =>
        Map.get(activity, "maneuver_success_factor_source") ||
          get_in(activity, ["metadata", "maneuver_success_factor_source"])
    })
    |> Map.merge(link_context(activity))
    |> Map.merge(station_calendar_context(activity))
    |> Map.merge(maneuver_delta_v_context(activity))
    |> Map.merge(activity_execution_uncertainty_context(activity))
    |> Map.merge(operational_context(activity))
    |> Map.merge(thermal_context(activity))
    |> Map.merge(planned_product_context(activity))
    |> compact_map()
  end

  defp realized_activity_context(id, planned_activity_id, timeline_id, status, activity) do
    %{
      "activity_id" => planned_activity_id || id,
      "realized_activity_id" => id,
      "planned_activity_id" => planned_activity_id,
      "timeline_id" => timeline_id,
      "activity_type" => Map.get(activity, "type"),
      "status" => status,
      "feedback_status" => realized_feedback_status(activity),
      "direction" => Map.get(activity, "direction"),
      "ground_station_id" => activity_ground_station_id(activity),
      "spacecraft_id" => activity_spacecraft_id(activity),
      "target_id" => activity_target_id(activity),
      "resource_id" => first_identifier(activity, ["resource_id", "resource"]),
      "target_priority" =>
        first_number(activity, ["target_priority", ["metadata", "target_priority"]]),
      "timeline_identity" =>
        realized_timeline_identity(id, planned_activity_id, timeline_id, activity),
      "approval_status" => first_string(activity, ["approval_status", "approval_state"]),
      "locked" => realized_activity_locked(activity),
      "executed" => realized_activity_executed(activity),
      "execution_status" => first_string(activity, ["execution_status", "execution_state"]),
      "source_window_id" =>
        Map.get(activity, "source_window_id") || get_in(activity, ["source_window", "id"]),
      "actual_starts_at_s" => first_number(activity, ["actual_starts_at_s", "actual_start_s"]),
      "actual_ends_at_s" => first_number(activity, ["actual_ends_at_s", "actual_end_s"]),
      "actual_throughput_mb" => actual_throughput_mb(activity),
      "actual_data_rate_throughput_derivation" =>
        actual_data_rate_throughput_derivation(activity),
      "actual_data_volume_mb" => actual_data_volume_mb(activity),
      "contact_success" => Map.get(activity, "contact_success"),
      "contact_result" => provider_result_artifact_value(Map.get(activity, "contact_result")),
      "contact_success_factor" => realized_contact_success_factor(activity),
      "contact_success_factor_source" => realized_contact_success_factor_source(activity),
      "command_success" => Map.get(activity, "command_success"),
      "command_success_factor" => realized_command_success_factor(activity),
      "command_success_factor_source" => realized_command_success_factor_source(activity),
      "observation_success_factor" => realized_observation_success_factor(activity),
      "observation_success_factor_source" => realized_observation_success_factor_source(activity),
      "feedback_weight" => normalized_feedback_weight(activity),
      "feedback_weight_source" => normalized_feedback_weight_source(activity),
      "maneuver_success_factor" =>
        first_unit_interval_number(activity, [
          "maneuver_success_factor",
          ["metadata", "maneuver_success_factor"]
        ]),
      "maneuver_success_factor_source" =>
        Map.get(activity, "maneuver_success_factor_source") ||
          get_in(activity, ["metadata", "maneuver_success_factor_source"]),
      "maneuver_success" => Map.get(activity, "maneuver_success"),
      "command_result" => provider_result_artifact_value(Map.get(activity, "command_result")),
      "maneuver_result" => provider_result_artifact_value(Map.get(activity, "maneuver_result")),
      "completed_fraction" => normalized_completed_fraction(activity),
      "reason" => Map.get(activity, "reason")
    }
    |> Map.merge(link_context(activity))
    |> Map.merge(station_calendar_context(activity))
    |> Map.merge(maneuver_delta_v_context(activity))
    |> Map.merge(activity_execution_uncertainty_context(activity))
    |> Map.merge(operational_context(activity))
    |> Map.merge(thermal_context(activity))
    |> Map.merge(realized_product_context(activity))
    |> Map.merge(realized_provider_context(activity))
    |> compact_map()
  end

  defp realized_activity_locked(activity) do
    first_boolean(activity, [
      "locked",
      ["metadata", "locked"]
    ])
  end

  defp realized_activity_executed(activity) do
    first_boolean(activity, [
      "executed",
      ["metadata", "executed"]
    ])
  end

  defp operational_context(activity), do: OperationalContext.build(activity, @stable_id_pattern)

  defp thermal_context(activity), do: ThermalContext.build(activity)

  defp link_context(activity), do: LinkContext.build(activity)

  defp station_calendar_context(activity) do
    StationCalendarContext.build(activity)
  end

  defp first_boolean(map, keys) do
    Enum.reduce_while(keys, nil, fn key, _value ->
      value =
        case key do
          path when is_list(path) -> get_in(map, path)
          key -> first_value(map, [key])
        end

      case boolean_value(value) do
        value when is_boolean(value) -> {:halt, value}
        nil -> {:cont, nil}
      end
    end)
  end

  defp first_string(map, keys) do
    Enum.find_value(keys, fn key ->
      case first_value(map, [key]) |> stringify_scalar() do
        value when value in [nil, ""] -> nil
        value -> value
      end
    end)
  end

  defp planned_product_context(activity) do
    %{
      "collection_id" => first_identifier(activity, ["collection_id", "collection"]),
      "product_id" => first_identifier(activity, ["product_id", "data_product_id"]),
      "product_ids" =>
        first_value(activity, ["product_ids", "data_product_ids"])
        |> normalize_id_list(["id", "product_id", "data_product_id"]),
      "payload_id" => first_identifier(activity, ["payload_id", "payload"]),
      "instrument_id" => first_identifier(activity, ["instrument_id", "instrument"]),
      "data_volume_mb" => planned_data_volume_mb(activity),
      "estimated_data_volume_mb" =>
        first_number(activity, ["estimated_data_volume_mb", "data_volume_mb"]),
      "estimated_storage_mb" =>
        first_number(activity, ["estimated_storage_mb", "data_volume_mb"]),
      "estimated_downlink_mb" => first_number(activity, ["estimated_downlink_mb"]),
      "required_downlink_mb" => first_number(activity, ["required_downlink_mb"])
    }
    |> compact_map()
  end

  defp realized_product_context(activity) do
    %{
      "collection_id" => first_identifier(activity, ["collection_id", "collection"]),
      "product_id" => first_identifier(activity, ["product_id", "data_product_id"]),
      "product_ids" =>
        first_value(activity, ["product_ids", "data_product_ids"])
        |> normalize_id_list(["id", "product_id", "data_product_id"]),
      "payload_id" => first_identifier(activity, ["payload_id", "payload"]),
      "instrument_id" => first_identifier(activity, ["instrument_id", "instrument"]),
      "actual_data_volume_mb" => actual_data_volume_mb(activity),
      "data_volume_mb" => actual_data_volume_mb(activity),
      "required_downlink_mb" => first_number(activity, ["required_downlink_mb"])
    }
    |> compact_map()
  end

  defp realized_provider_context(activity) do
    raw_cadence_import = Map.get(activity, "cadence_import")
    cadence_import = if is_map(raw_cadence_import), do: raw_cadence_import, else: %{}

    %{
      "source" => Map.get(activity, "source"),
      "provider" => Map.get(activity, "provider") || Map.get(activity, "provider_id"),
      "source_quality" =>
        first_string(activity, [
          "source_quality",
          "quality",
          "quality_level",
          ["provenance", "source_quality"],
          ["metadata", "source_quality"],
          ["metadata", "quality"]
        ]),
      "adapter" => Map.get(activity, "adapter") || Map.get(activity, "import_adapter"),
      "adapter_version" => Map.get(activity, "adapter_version"),
      "external_id" =>
        identifier(activity, "external_id") || identifier(activity, "provider_activity_id"),
      "schema_contract" =>
        Map.get(activity, "schema_contract") || Map.get(cadence_import, "schema_contract"),
      "trust_boundary" =>
        Map.get(activity, "trust_boundary") || get_in(activity, ["provenance", "trust_boundary"]),
      "received_at" => Map.get(activity, "received_at"),
      "ingested_at" => Map.get(activity, "ingested_at"),
      "provenance" => Map.get(activity, "provenance"),
      "metadata" => Map.get(activity, "metadata"),
      "cadence_import" => if(is_map(raw_cadence_import), do: raw_cadence_import),
      "invalid_cadence_import" => if(invalid_cadence_import?(activity), do: true),
      "invalid_cadence_import_reason" =>
        if(invalid_cadence_import?(activity), do: "cadence_import_must_be_object"),
      "source_cadence_import" =>
        if(invalid_cadence_import?(activity),
          do: %{"invalid_import_shape" => stringify_keys(raw_cadence_import)}
        )
    }
  end

  defp invalid_cadence_import?(%{"cadence_import" => cadence_import}),
    do: not is_map(cadence_import)

  defp invalid_cadence_import?(_activity), do: false

  defp realized_timeline_identity(_id, _planned_activity_id, nil, _activity), do: nil

  defp realized_timeline_identity(id, planned_activity_id, timeline_id, activity) do
    %{
      "timeline_id" => timeline_id,
      "activity_id" => planned_activity_id || id,
      "activity_type" => Map.get(activity, "type"),
      "scenario_id" => Map.get(activity, "scenario_id"),
      "subject_id" =>
        activity_ground_station_id(activity) ||
          activity_target_id(activity) ||
          activity_spacecraft_id(activity),
      "source_window_id" =>
        Map.get(activity, "source_window_id") || get_in(activity, ["source_window", "id"])
    }
    |> compact_map()
  end

  defp put_realized_match_context(row, planned_id, strategy, ambiguity) do
    context =
      row
      |> Map.get("realized_activity_context", %{})
      |> Map.put("match_strategy", strategy)
      |> maybe_put(
        "matched_planned_activity_id",
        matched_planned_activity_id(planned_id, strategy)
      )
      |> maybe_put(
        "ambiguous_planned_timeline_id",
        Map.get(ambiguity || %{}, "ambiguous_planned_timeline_id")
      )
      |> maybe_put(
        "ambiguous_planned_activity_ids",
        Map.get(ambiguity || %{}, "ambiguous_planned_activity_ids")
      )

    Map.put(row, "realized_activity_context", context)
  end

  defp matched_planned_activity_id(planned_id, strategy)
       when strategy in ["planned_activity_id", "timeline_id", "activity_id"],
       do: planned_id

  defp matched_planned_activity_id(_planned_id, _strategy), do: nil

  defp planned_by_timeline_id(planned) do
    planned
    |> Enum.reject(&(Map.get(&1, "timeline_id") in [nil, ""]))
    |> Enum.group_by(& &1["timeline_id"])
    |> Map.new(fn {timeline_id, planned_rows} ->
      {timeline_id, Enum.sort_by(planned_rows, & &1["id"])}
    end)
  end

  defp realized_match(realized, planned_by_id, planned_by_timeline_id) do
    planned_activity_id = Map.get(realized, "planned_activity_id")
    timeline_id = Map.get(realized, "timeline_id")
    realized_id = Map.get(realized, "id")

    cond do
      is_binary(planned_activity_id) and Map.has_key?(planned_by_id, planned_activity_id) ->
        {planned_activity_id, "planned_activity_id", nil}

      is_binary(timeline_id) and Map.has_key?(planned_by_timeline_id, timeline_id) ->
        case Map.fetch!(planned_by_timeline_id, timeline_id) do
          [planned_row] ->
            {planned_row["id"], "timeline_id", nil}

          planned_rows ->
            {realized_id, "ambiguous_timeline_id",
             ambiguous_timeline_match(timeline_id, planned_rows)}
        end

      Map.has_key?(planned_by_id, realized_id) ->
        {realized_id, "activity_id", nil}

      true ->
        {realized_id, "unmatched_realized", nil}
    end
  end

  defp ambiguous_timeline_match(timeline_id, planned_rows) do
    %{
      "ambiguous_planned_timeline_id" => timeline_id,
      "ambiguous_planned_match_count" => length(planned_rows),
      "ambiguous_planned_activity_ids" => Enum.map(planned_rows, & &1["id"]),
      "ambiguous_planned_activities" => Enum.map(planned_rows, & &1["source_activity"])
    }
  end

  defp reconciliation_row(id, planned_by_id, realized_by_id, timing_variance_threshold_s) do
    planned = Map.get(planned_by_id, id)
    realized_matches = Map.get(realized_by_id, id, [])
    realized = List.first(realized_matches)
    feedback_kind = feedback_kind(planned, realized)

    execution_uncertainty_context =
      execution_uncertainty_reconciliation_context(planned, realized)

    match_strategy = value(realized, "match_strategy") || "unmatched_planned"

    %{
      "activity_id" => id,
      "match_strategy" => match_strategy,
      "ambiguous_planned_timeline_id" => value(realized, "ambiguous_planned_timeline_id"),
      "ambiguous_planned_match_count" => value(realized, "ambiguous_planned_match_count"),
      "ambiguous_planned_activity_ids" => value(realized, "ambiguous_planned_activity_ids"),
      "ambiguous_planned_activities" => value(realized, "ambiguous_planned_activities"),
      "feedback_kind" => feedback_kind,
      "planned_timeline_id" => value(planned, "timeline_id"),
      "timeline_identity" => value(planned, "timeline_identity")
    }
    |> Map.merge(ReconciliationCommunicationsEvidence.context(planned, realized))
    |> Map.merge(ReconciliationIdentity.context(planned, realized))
    |> Map.merge(ReconciliationLifecycleEvidence.context(planned, realized))
    |> Map.merge(ReconciliationObservationEvidence.context(planned, realized))
    |> Map.merge(
      ReconciliationOutcomeEvidence.context(
        realized,
        feedback_kind,
        @provider_result_map_value_keys,
        @realized_failure_statuses
      )
    )
    |> Map.merge(ReconciliationPlanEvidence.context(planned))
    |> Map.merge(ReconciliationRealizedIngressEvidence.context(realized))
    |> Map.merge(ReconciliationResourceEvidence.context(planned, realized))
    |> Map.merge(ReconciliationStationCalendarEvidence.context(planned, realized))
    |> Map.merge(
      ReconciliationTimingEvidence.context(planned, realized, timing_variance_threshold_s)
    )
    |> Map.merge(ExecutionUncertainty.maneuver_reconciliation_context(planned, realized))
    |> Map.merge(SuccessFactor.reconciliation_context(planned, realized))
    |> Map.merge(Throughput.reconciliation_context(planned, realized))
    |> Map.merge(execution_uncertainty_context)
    |> put_duplicate_realized_feedback(realized_matches)
    |> ReconciliationIdentity.put_mismatch_summary()
    |> put_operational_feedback_exclusion()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp put_operational_feedback_exclusion(row), do: OperationalFeedbackExclusion.apply(row)

  defp put_duplicate_realized_feedback(row, realized_matches) when length(realized_matches) > 1 do
    row
    |> Map.put("realized_match_count", length(realized_matches))
    |> Map.put("realized_activity_ids", Enum.map(realized_matches, & &1["realized_activity_id"]))
    |> Map.put("realized_statuses", Enum.map(realized_matches, & &1["status"]))
    |> Map.put("realized_match_strategies", Enum.map(realized_matches, & &1["match_strategy"]))
    |> Map.put("realized_activities", Enum.map(realized_matches, & &1["source_activity"]))
  end

  defp put_duplicate_realized_feedback(row, _realized_matches), do: row

  defp status_counts(rows) do
    rows
    |> Enum.group_by(& &1["status"])
    |> Map.new(fn {status, status_rows} -> {status, length(status_rows)} end)
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp execution_uncertainty_status_count(rows, status) do
    Enum.count(rows, &(Map.get(&1, "execution_uncertainty_status") == status))
  end

  defp duplicate_realized_match_count(rows) do
    Enum.count(rows, &(Map.get(&1, "realized_match_count", 0) > 1))
  end

  defp duplicate_realized_feedback_count(rows) do
    Enum.reduce(rows, 0, fn row, count ->
      count + max(Map.get(row, "realized_match_count", 1) - 1, 0)
    end)
  end

  defp operational_feedback_excluded?(row), do: FeedbackAggregation.excluded?(row)

  defp feedback_average_by(rows, key_fun, value_fun),
    do: FeedbackAggregation.average_by(rows, key_fun, value_fun)

  defp feedback_text_by(rows, key_fun, value_fun),
    do: FeedbackAggregation.text_by(rows, key_fun, value_fun)

  defp downlink_demand_feedback(rows), do: DownlinkDemandFeedback.demand(rows)

  defp downlink_demand_sources_feedback(rows),
    do: DownlinkDemandFeedback.sources(rows)

  defp downlink_demand_feedback_trust_key(row),
    do: DownlinkDemandFeedback.trust_key(row)

  defp downlink_demand_feedback_trust_value(row),
    do: DownlinkDemandFeedback.trust_value(row)

  defp downlink_demand_sources_feedback_trust_value(row),
    do: DownlinkDemandFeedback.sources_trust_value(row)

  defp target_priority_feedback(rows) do
    rows
    |> Enum.reject(&operational_feedback_excluded?/1)
    |> Enum.reduce(%{}, fn row, grouped ->
      key = stable_scalar_identifier(row["target_id"])
      value = target_priority_feedback_value(row)
      weight = feedback_average_weight(row)

      if is_binary(key) and key != "" and is_number(value) and is_number(weight) and
           weight > 0.0 do
        Map.update(
          grouped,
          key,
          [{max(value, 0.0), weight}],
          &[
            {max(value, 0.0), weight} | &1
          ]
        )
      else
        grouped
      end
    end)
    |> Enum.map(fn {key, weighted_values} -> {key, weighted_average(weighted_values)} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new()
  end

  defp target_priority_feedback_value(%{"feedback_kind" => "observation"} = row) do
    first_target_priority_number(row, [
      ["realized_activity_context", "target_priority"],
      ["source_activity_context", "target_priority"],
      "realized_target_priority",
      "target_priority"
    ])
  end

  defp target_priority_feedback_value(_row), do: nil

  defp resource_margin_feedback(rows), do: ResourceFeedback.margin_overrides(rows)

  defp resource_margin_feedback_trust_value(row), do: ResourceFeedback.margin_trust_value(row)

  defp resource_availability_feedback(rows), do: ResourceFeedback.availability_overrides(rows)

  defp resource_availability_feedback_trust_value(row),
    do: ResourceFeedback.availability_trust_value(row)

  defp maneuver_execution_uncertainty_feedback(rows) do
    rows
    |> Enum.reject(&operational_feedback_excluded?/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      key = stable_scalar_identifier(row["activity_id"])
      entry = maneuver_execution_uncertainty_feedback_entry(row)

      if is_binary(key) and key != "" and entry != %{} do
        Map.put(feedback, key, entry)
      else
        feedback
      end
    end)
    |> sort_nested_feedback_map()
  end

  defp maneuver_execution_uncertainty_feedback_entry(row) do
    %{
      "execution_uncertainty_status" => row["execution_uncertainty_status"],
      "execution_uncertainty" => row["execution_uncertainty"],
      "timing_3sigma_s" => numeric_value(row["timing_3sigma_s"]),
      "delta_v_3sigma_km_s" => numeric_triplet(row["delta_v_3sigma_km_s"]),
      "delta_v_3sigma_magnitude_km_s" => numeric_value(row["delta_v_3sigma_magnitude_km_s"]),
      "execution_uncertainty_source" => row["execution_uncertainty_source"]
    }
    |> compact_map()
    |> case do
      %{"execution_uncertainty_status" => status} = entry
      when status in ["declared", "missing"] ->
        entry

      _entry ->
        %{}
    end
  end

  defp resource_feedback_spacecraft_id(row), do: ResourceFeedback.spacecraft_id(row)

  defp stable_scalar_identifier(value), do: FeedbackAggregation.stable_identifier(value)

  defp sort_nested_feedback_map(feedback) do
    feedback
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new(fn {key, value} ->
      {key,
       value
       |> Enum.sort_by(fn {field, _field_value} -> field end)
       |> Map.new()}
    end)
  end

  defp first_target_priority_number(row, fields) do
    Enum.find_value(fields, fn field ->
      value =
        case field do
          path when is_list(path) -> get_in(row, path)
          field -> Map.get(row, field)
        end

      numeric_value(value)
    end)
  end

  defp contact_success_feedback_value(%{"feedback_kind" => "contact"} = row) do
    OutcomeValue.contact_success(row, @realized_completion_statuses, @realized_failure_statuses)
  end

  defp contact_success_feedback_value(_row), do: nil

  defp station_throughput_feedback_value(%{"feedback_kind" => "contact"} = row) do
    OutcomeValue.station_throughput(row)
  end

  defp station_throughput_feedback_value(_row), do: nil

  defp observation_success_feedback_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.observation_success(
      row,
      @provider_result_map_value_keys,
      @realized_completion_statuses,
      @realized_failure_statuses
    )
  end

  defp observation_success_feedback_value(_row), do: nil

  defp image_quality_score_feedback_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.image_quality_score(row)
  end

  defp image_quality_score_feedback_value(_row), do: nil

  defp cloud_cover_feedback_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.cloud_cover(row)
  end

  defp cloud_cover_feedback_value(_row), do: nil

  defp blur_score_feedback_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.blur_score(row)
  end

  defp blur_score_feedback_value(_row), do: nil

  defp image_quality_status_feedback_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.image_quality_status(row)
  end

  defp image_quality_status_feedback_value(_row), do: nil

  defp image_quality_source_feedback_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.image_quality_source(row)
  end

  defp image_quality_source_feedback_value(_row), do: nil

  defp maneuver_success_feedback_value(%{"feedback_kind" => "maneuver"} = row) do
    OutcomeValue.maneuver_success(row, @realized_completion_statuses, @realized_failure_statuses)
  end

  defp maneuver_success_feedback_value(_row), do: nil

  defp command_success_feedback_value(%{"feedback_kind" => kind} = row)
       when kind in ["command", "health_check"] do
    OutcomeValue.command_success(row, @realized_completion_statuses, @realized_failure_statuses)
  end

  defp command_success_feedback_value(_row), do: nil

  defp weighted_average(weighted_values) do
    OutcomeValue.weighted_average(weighted_values)
  end

  defp feedback_average_weight(%{"feedback_weight" => weight}) do
    OutcomeValue.average_weight(%{"feedback_weight" => weight})
  end

  defp feedback_average_weight(_row), do: 1.0

  defp ambiguous_timeline_match_count(rows) do
    Enum.count(rows, &(&1["match_strategy"] == "ambiguous_timeline_id"))
  end

  defp ambiguous_timeline_feedback_count(rows) do
    Enum.reduce(rows, 0, fn row, count ->
      case row["ambiguous_planned_match_count"] do
        match_count when is_integer(match_count) and match_count > 1 -> count + match_count
        _other -> count
      end
    end)
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)

  defp source_activity_value(%{} = source_activity, primary_key, fallback_key) do
    Map.get(source_activity, primary_key) || Map.get(source_activity, fallback_key)
  end

  defp source_activity_value(_source_activity, _primary_key, _fallback_key), do: nil

  defp feedback_kind(planned, realized) do
    value(planned, "operational_kind") ||
      realized_operational_kind(realized) ||
      "activity"
  end

  defp realized_operational_kind(nil), do: nil
  defp realized_operational_kind(%{"type" => "command"}), do: "command"
  defp realized_operational_kind(%{"type" => "health_check"}), do: "health_check"
  defp realized_operational_kind(%{"type" => "observe"}), do: "observation"
  defp realized_operational_kind(%{"type" => "impulsive_burn"}), do: "maneuver"
  defp realized_operational_kind(%{"type" => "slew"}), do: "attitude"
  defp realized_operational_kind(%{"type" => "coast"}), do: "coast"

  defp realized_operational_kind(%{"direction" => direction})
       when direction in @command_contact_directions,
       do: "command"

  defp realized_operational_kind(%{"direction" => "health_check"}), do: "health_check"

  defp realized_operational_kind(%{"type" => type})
       when type in ["downlink", "planned_contact", "tracking"],
       do: "contact"

  defp realized_operational_kind(%{"direction" => direction})
       when direction in ["downlink", "tracking"],
       do: "contact"

  defp realized_operational_kind(%{"ground_station_id" => ground_station_id})
       when is_binary(ground_station_id) and ground_station_id != "",
       do: "contact"

  defp realized_operational_kind(%{"station_id" => station_id})
       when is_binary(station_id) and station_id != "",
       do: "contact"

  defp realized_operational_kind(_activity), do: nil

  defp activity_ground_station_id(activity) do
    [
      Map.get(activity, "ground_station_id"),
      Map.get(activity, "station_id"),
      nested_identity(activity, ["ground_station", "station"], [
        "ground_station_id",
        "station_id",
        "id"
      ])
    ]
    |> Enum.find_value(&stable_scalar_identifier/1)
  end

  defp activity_target_id(activity) do
    [
      Map.get(activity, "target_id"),
      nested_identity(activity, ["target"], ["target_id", "id"])
    ]
    |> Enum.find_value(&stable_scalar_identifier/1)
  end

  defp activity_spacecraft_id(activity) do
    [
      Map.get(activity, "spacecraft_id"),
      Map.get(activity, "satellite_id"),
      nested_identity(activity, ["spacecraft", "satellite"], [
        "spacecraft_id",
        "satellite_id",
        "id"
      ])
    ]
    |> Enum.find_value(&stable_scalar_identifier/1)
  end

  defp nested_identity(activity, object_keys, identity_keys) do
    Enum.find_value(object_keys, fn object_key ->
      case Map.get(activity, object_key) do
        %{} = object ->
          Enum.find_value(identity_keys, fn identity_key ->
            identifier(object, identity_key)
          end)

        _value ->
          nil
      end
    end)
  end

  defp provider_result_artifact_value(result),
    do: ProviderResult.artifact_value(result, @provider_result_map_value_keys)

  defp identifier(map, key), do: RealizedIdentity.identifier(map, key, @stable_id_pattern)

  defp realized_input_identity_issue(activity),
    do: RealizedIdentity.input_issue(activity, @stable_id_pattern)

  defp realized_status_supported?(activity),
    do: RealizedStatus.supported?(activity, @realized_status_policy)

  defp realized_status(activity),
    do: RealizedStatus.value(activity, @realized_status_policy)

  defp realized_feedback_status(activity),
    do: RealizedStatus.feedback_value(activity, @realized_status_policy)

  defp source_realized_activity_id(source_activity),
    do: RealizedIdentity.source_id(source_activity, @stable_id_pattern)

  defp invalid_realized_planned_activity_id(source_activity),
    do: RealizedIdentity.invalid_planned_id(source_activity, @stable_id_pattern)

  defp invalid_realized_timeline_id(source_activity),
    do: RealizedIdentity.invalid_timeline_id(source_activity, @stable_id_pattern)

  defp invalid_realized_status_reason(activity) do
    RealizedStatus.invalid_reason(activity, @realized_status_policy)
  end

  defp unsupported_realized_status(source_activity, reason),
    do: RealizedStatus.unsupported_value(source_activity, reason, @realized_status_policy)

  defp realized_id!(activity), do: RealizedIdentity.id!(activity, @stable_id_pattern)

  defp first_number(map, keys), do: Throughput.first_number(map, keys)
  defp planned_data_volume_mb(activity), do: Throughput.planned_data_volume_mb(activity)
  defp actual_data_volume_mb(activity), do: Throughput.actual_data_volume_mb(activity)
  defp actual_throughput_mb(activity), do: Throughput.actual_throughput_mb(activity)

  defp actual_data_rate_throughput_derivation(activity),
    do: Throughput.actual_data_rate_throughput_derivation(activity)

  defp normalized_feedback_weight(activity) do
    case first_number(activity, [
           "feedback_weight",
           "feedback_sample_weight",
           "sample_weight",
           "confidence_weight"
         ]) do
      value when is_number(value) and value >= 0.0 -> value * 1.0
      _value -> nil
    end
  end

  defp normalized_feedback_weight_source(activity) do
    first_string(activity, [
      "feedback_weight_source",
      "feedback_sample_weight_source",
      "sample_weight_source",
      "confidence_weight_source"
    ])
  end

  defp maneuver_delta_v_context(activity) do
    ExecutionUncertainty.maneuver_delta_v_context(activity)
  end

  defp activity_execution_uncertainty_context(activity) do
    ExecutionUncertainty.activity_context(activity)
  end

  defp execution_uncertainty_reconciliation_context(planned, realized) do
    ExecutionUncertainty.reconciliation_context(planned, realized)
  end

  defp maneuver_delta_v(activity) do
    ExecutionUncertainty.maneuver_delta_v(activity)
  end

  defp numeric_triplet(value), do: ExecutionUncertainty.numeric_triplet(value)
  defp numeric_value(value), do: ExecutionUncertainty.numeric_value(value)
  defp vector_norm(value), do: ExecutionUncertainty.vector_norm(value)

  defp realized_observation_success_factor(activity) do
    SuccessFactor.observation(activity, @provider_result_map_value_keys)
  end

  defp realized_observation_success_factor_source(activity) do
    SuccessFactor.observation_source(activity, @provider_result_map_value_keys)
  end

  defp normalized_completed_fraction(activity) do
    unit_interval_number_or_nil(Map.get(activity, "completed_fraction"))
  end

  defp first_unit_interval_number(activity, fields),
    do: SuccessFactor.first_unit_interval_number(activity, fields)

  defp realized_contact_success_factor(activity) do
    SuccessFactor.contact(activity, @command_contact_directions)
  end

  defp realized_contact_success_factor_source(activity) do
    SuccessFactor.contact_source(activity, @command_contact_directions)
  end

  defp realized_command_success_factor(activity) do
    SuccessFactor.command(activity, @command_contact_directions)
  end

  defp realized_command_success_factor_source(activity) do
    SuccessFactor.command_source(activity, @command_contact_directions)
  end

  defp unit_interval_number_or_nil(value),
    do: SuccessFactor.unit_interval_number_or_nil(value)

  defp present_string?(value), do: ArtifactValue.present_string?(value)

  defp first_identifier(map, keys),
    do: RealizedIdentity.first_identifier(map, keys, @stable_id_pattern)

  defp first_value(map, keys), do: RealizedIdentity.first_value(map, keys)

  defp normalize_id_list(value, map_keys),
    do: RealizedIdentity.normalize_list(value, map_keys, @stable_id_pattern)

  defp required_id!(map, key), do: RealizedIdentity.required_id!(map, key)

  defp stringify_keys(value), do: ArtifactValue.stringify_keys(value)
  defp stringify_scalar(value), do: ArtifactValue.stringify_scalar(value)
  defp boolean_value(value), do: ArtifactValue.boolean_value(value)
  defp compact_map(map), do: ArtifactValue.compact_map(map)
  defp maybe_put(map, key, value), do: ArtifactValue.maybe_put(map, key, value)
end
