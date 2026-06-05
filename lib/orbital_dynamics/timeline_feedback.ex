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
  @station_capacity_fraction_paths [
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["station_capacity_percent"],
    ["capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"]
  ]
  @station_capacity_value_paths [
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]}
  ]
  @command_contact_directions ~w(command uplink)
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Timeline}

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
      station_capacity_fraction_paths: @station_capacity_fraction_paths,
      station_capacity_percent_paths: @station_capacity_percent_paths,
      station_capacity_value_paths: capacity_value_path_metadata(@station_capacity_value_paths),
      source_station_capacity_fraction_paths: @station_capacity_fraction_paths,
      source_station_capacity_percent_paths: @station_capacity_percent_paths,
      source_station_capacity_value_paths:
        capacity_value_path_metadata(@station_capacity_value_paths),
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

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
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
    primary = primary_activity_state_row(rows)
    lifecycle_state = Timeline.activity_lifecycle_state(planned_activity, realized_activity)

    %{
      "schema_contract" => @activity_state_schema_contract,
      "model" => "artifact_only_timeline_activity_state",
      "validation_level" => "artifact_contract",
      "state_status" => activity_state_status(rows),
      "row_count" => length(rows),
      "status_counts" => status_counts(rows),
      "feedback_kind_counts" => count_by(rows, "feedback_kind"),
      "match_strategy_counts" => count_by(rows, "match_strategy"),
      "cadence_import_status_counts" => count_by(rows, "cadence_import_status"),
      "planned_protection_decision_counts" => count_by(rows, "planned_protection_decision"),
      "realized_provider_counts" => activity_state_count_by(rows, "realized_provider"),
      "realized_source_quality_counts" =>
        activity_state_count_by(rows, "realized_source_quality"),
      "realized_trust_boundary_status" => activity_state_realized_trust_boundary_status(rows),
      "realized_trust_boundaries" => activity_state_realized_trust_boundaries(rows),
      "activity_id" => value(primary, "activity_id"),
      "activity_ids" => activity_state_ids(rows, "activity_id"),
      "timeline_id" =>
        value(primary, "planned_timeline_id") || value(primary, "realized_timeline_id"),
      "planned_timeline_id" => value(primary, "planned_timeline_id"),
      "realized_timeline_id" => value(primary, "realized_timeline_id"),
      "timeline_identity" => value(primary, "timeline_identity"),
      "feedback_kind" => value(primary, "feedback_kind"),
      "match_strategy" => value(primary, "match_strategy"),
      "planned_status" => activity_state_planned_status(primary),
      "realized_status" => activity_state_realized_status(primary),
      "planned_status_category" => Map.get(lifecycle_state, "planned_status_category"),
      "realized_status_category" => Map.get(lifecycle_state, "realized_status_category"),
      "feedback_status" => value(primary, "feedback_status"),
      "status_transition" => value(primary, "status_transition"),
      "planned_approval_status" => Map.get(lifecycle_state, "planned_approval_status"),
      "realized_approval_status" => Map.get(lifecycle_state, "realized_approval_status"),
      "planned_approval_category" => Map.get(lifecycle_state, "planned_approval_category"),
      "realized_approval_category" => Map.get(lifecycle_state, "realized_approval_category"),
      "approval_transition" => Map.get(lifecycle_state, "approval_transition"),
      "planned_locked" => Map.get(lifecycle_state, "planned_locked"),
      "realized_locked" => Map.get(lifecycle_state, "realized_locked"),
      "planned_executed" => Map.get(lifecycle_state, "planned_executed"),
      "realized_executed" => Map.get(lifecycle_state, "realized_executed"),
      "planned_protection_decision" => value(primary, "planned_protection_decision"),
      "planned_protection_category" => value(primary, "planned_protection_category"),
      "planned_protection_reason" => value(primary, "planned_protection_reason"),
      "source_protection_decision" => value(primary, "source_protection_decision"),
      "realized_protection_decision" => Map.get(lifecycle_state, "realized_protection_decision"),
      "source_activity_context" => value(primary, "source_activity_context"),
      "realized_activity_context" => value(primary, "realized_activity_context"),
      "review_required" => activity_state_review_required?(rows),
      "review_activity_ids" => activity_state_review_ids(rows),
      "rows" => rows,
      "assumptions" => %{
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "source" => "timeline_feedback.reconcile"
      },
      "model_limits" => model_limits()
    }
    |> compact_map()
  end

  def activity_state(_planned_activity, _realized_activity, _opts) do
    raise ArgumentError, "activity state options must be a keyword list"
  end

  defp optional_activity_state_input(nil, _label), do: []
  defp optional_activity_state_input(%{} = activity, _label), do: [activity]

  defp optional_activity_state_input(_activity, label) do
    raise ArgumentError, "#{label} must be a map or nil"
  end

  defp primary_activity_state_row(rows) do
    Enum.find(rows, &(&1["status"] == "matched")) ||
      Enum.find(rows, &(&1["status"] == "planned_only")) ||
      List.first(rows, %{})
  end

  defp activity_state_status([]), do: "empty"
  defp activity_state_status([%{"status" => status}]), do: status

  defp activity_state_status(rows) do
    if Enum.any?(rows, &(&1["status"] == "matched")) do
      "matched"
    else
      "review_required"
    end
  end

  defp activity_state_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp activity_state_review_required?(rows) do
    Enum.any?(rows, fn row ->
      Map.get(row, "status") != "matched" or
        Map.get(row, "planned_protection_decision") == "review_change" or
        present_review_action?(Map.get(row, "required_operator_action")) or
        present_review_action?(get_in(row, ["status_transition", "required_operator_action"]))
    end)
  end

  defp activity_state_review_ids(rows) do
    rows
    |> Enum.filter(fn row ->
      activity_state_review_required?([row])
    end)
    |> activity_state_ids("activity_id")
  end

  defp present_review_action?(action) when action in [nil, "", "none"], do: false
  defp present_review_action?(_action), do: true

  defp activity_state_count_by(rows, field) do
    rows
    |> count_by(field)
    |> case do
      counts when map_size(counts) == 0 -> nil
      counts -> counts
    end
  end

  defp activity_state_realized_trust_boundary_status(rows) do
    if activity_state_realized_row_count(rows) == 0 do
      nil
    else
      case activity_state_realized_trust_boundary_values(rows) do
        [] -> "missing"
        _boundaries -> "declared"
      end
    end
  end

  defp activity_state_realized_trust_boundaries(rows) do
    case activity_state_realized_trust_boundary_values(rows) do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp activity_state_realized_trust_boundary_values(rows) do
    rows
    |> Enum.map(&Map.get(&1, "realized_trust_boundary"))
    |> Enum.filter(&present_string?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp activity_state_realized_row_count(rows) do
    Enum.count(rows, fn row ->
      Map.get(row, "status") in ["matched", "realized_only"] or
        present_string?(Map.get(row, "realized_activity_id")) or
        present_string?(Map.get(row, "realized_status"))
    end)
  end

  defp activity_state_planned_status(row) do
    value(row, "planned_status") || get_in(row, ["status_transition", "from"])
  end

  defp activity_state_realized_status(row) do
    value(row, "realized_status") || get_in(row, ["status_transition", "to"])
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
    input_keys = operational_feedback_data_keys(operational_feedback)
    excluded_count = Map.get(source_counts, "source_operational_feedback_excluded_count", 0)

    if input_keys == [] and excluded_count == 0 do
      nil
    else
      trust_boundaries = operational_feedback_trust_boundaries(rows)
      weighted_feedback_row_count = weighted_feedback_row_count(rows)
      feedback_weight_sources = feedback_weight_sources(rows)
      source_quality_counts = count_by(rows, "realized_source_quality")

      feedback_trust_boundaries =
        operational_feedback_trust_boundaries_by_key(rows, operational_feedback)

      source =
        source_counts
        |> Map.merge(%{
          "source" => "timeline_feedback_report.rows",
          "source_report_contract" => @schema_contract,
          "source_report_count" => 1,
          "source_report_row_count" => length(rows),
          "input_keys" => input_keys,
          "realized_activity_count" => timeline_feedback_realized_row_count(rows),
          "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
          "trust_boundaries" => trust_boundaries
        })
        |> maybe_put(
          "weighted_feedback_row_count",
          positive_integer_or_nil(weighted_feedback_row_count)
        )
        |> maybe_put(
          "feedback_weight_sources",
          if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources)
        )
        |> maybe_put(
          "source_realized_source_quality_counts",
          if(map_size(source_quality_counts) == 0, do: nil, else: source_quality_counts)
        )
        |> maybe_put(
          "feedback_trust_boundaries",
          if(map_size(feedback_trust_boundaries) == 0, do: nil, else: feedback_trust_boundaries)
        )
        |> compact_map()

      %{
        "model" => "timeline_feedback_report_rows_to_operational_feedback",
        "merge_order" => ["timeline_feedback_report.rows"],
        "input_keys" => input_keys,
        "source_count" => 1,
        "sources" => [source],
        "explicit_request_override" => false
      }
    end
  end

  defp operational_feedback_data_keys(feedback) when is_map(feedback) do
    feedback
    |> Enum.filter(fn {_key, value} -> is_map(value) and map_size(value) > 0 end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.sort()
  end

  defp timeline_feedback_realized_row_count(rows) do
    Enum.reduce(rows, 0, fn row, count ->
      case Map.get(row, "status") do
        "matched" -> count + Map.get(row, "realized_match_count", 1)
        "realized_only" -> count + Map.get(row, "realized_match_count", 1)
        _status -> count
      end
    end)
  end

  defp weighted_feedback_row_count(rows) do
    Enum.count(rows, fn row ->
      case Map.get(row, "feedback_weight") do
        weight when is_number(weight) and weight > 0.0 -> true
        _weight -> false
      end
    end)
  end

  defp positive_integer_or_nil(value) when is_integer(value) and value > 0, do: value
  defp positive_integer_or_nil(_value), do: nil

  defp feedback_weight_sources(rows) do
    rows
    |> Enum.filter(fn row ->
      case Map.get(row, "feedback_weight") do
        weight when is_number(weight) and weight > 0.0 -> true
        _weight -> false
      end
    end)
    |> Enum.map(& &1["feedback_weight_source"])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp operational_feedback_trust_boundaries(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row_feedback_trust_boundaries(row)
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp operational_feedback_trust_boundaries_by_key(rows, operational_feedback) do
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
    |> Enum.reduce(%{}, fn {field, key_fun, value_fun}, boundaries ->
      feedback = Map.get(operational_feedback, field, %{})

      if is_map(feedback) and map_size(feedback) > 0 do
        field_boundaries =
          rows
          |> Enum.reduce(%{}, fn row, field_boundaries ->
            key = row |> key_fun.() |> stringify_scalar()

            if key in [nil, ""] or is_nil(value_fun.(row)) do
              field_boundaries
            else
              case row_feedback_trust_boundaries(row) do
                [] ->
                  field_boundaries

                trust_boundaries ->
                  Map.update(field_boundaries, key, trust_boundaries, fn existing ->
                    (existing ++ trust_boundaries)
                    |> Enum.uniq()
                    |> Enum.sort()
                  end)
              end
            end
          end)
          |> Enum.reject(fn {_key, trust_boundaries} -> trust_boundaries == [] end)
          |> Map.new()

        if map_size(field_boundaries) == 0 do
          boundaries
        else
          Map.put(boundaries, field, field_boundaries)
        end
      else
        boundaries
      end
    end)
  end

  defp row_feedback_trust_boundaries(row) do
    context = Map.get(row, "realized_activity_context", %{})
    provenance = Map.get(row, "realized_provenance", %{})
    context_provenance = Map.get(context, "provenance", %{})

    [
      Map.get(row, "realized_trust_boundary"),
      Map.get(provenance, "trust_boundary"),
      Map.get(context, "trust_boundary"),
      Map.get(context_provenance, "trust_boundary")
    ]
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
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
    |> Map.merge(resource_context(activity))
    |> Map.merge(pointing_context(activity))
    |> Map.merge(attitude_context(activity))
    |> Map.merge(command_authority_context(activity))
    |> Map.merge(lighting_context(activity))
    |> Map.merge(observation_quality_context(activity))
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
    |> Map.merge(resource_context(activity))
    |> Map.merge(pointing_context(activity))
    |> Map.merge(attitude_context(activity))
    |> Map.merge(command_authority_context(activity))
    |> Map.merge(lighting_context(activity))
    |> Map.merge(observation_quality_context(activity))
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

  defp invalid_realized_feedback_unit_interval_sections(activity) do
    realized_feedback_unit_interval_paths()
    |> Enum.flat_map(fn {field, path} ->
      value = feedback_path_value(activity, path)

      case unit_interval_number_status(value) do
        {:ok, _value} ->
          []

        :missing ->
          []

        {:invalid_number, number} ->
          [
            %{
              "field" => field,
              "reason" => "entry_must_be_unit_interval_number",
              "invalid_feedback_shape" => number
            }
          ]

        {:invalid_shape, shape} ->
          [
            %{
              "field" => field,
              "reason" => "entry_must_be_unit_interval_number",
              "invalid_feedback_shape" => stringify_keys(shape)
            }
          ]
      end
    end)
  end

  defp invalid_realized_feedback_nonnegative_number_sections(activity) do
    realized_feedback_weight_paths()
    |> Enum.flat_map(fn {field, path} ->
      value = feedback_path_value(activity, path)

      case nonnegative_number_status(value) do
        {:ok, _value} ->
          []

        :missing ->
          []

        {:invalid_number, number} ->
          [
            %{
              "field" => field,
              "reason" => "entry_must_be_nonnegative_number",
              "invalid_feedback_shape" => number
            }
          ]

        {:invalid_shape, shape} ->
          [
            %{
              "field" => field,
              "reason" => "entry_must_be_nonnegative_number",
              "invalid_feedback_shape" => stringify_keys(shape)
            }
          ]
      end
    end)
  end

  defp sanitize_realized_feedback_unit_interval_values(activity) do
    realized_feedback_unit_interval_paths()
    |> Enum.reduce(activity, fn {_field, path}, sanitized ->
      value = feedback_path_value(sanitized, path)

      case unit_interval_number_status(value) do
        {:invalid_number, _number} -> delete_feedback_path(sanitized, path)
        {:invalid_shape, _shape} -> delete_feedback_path(sanitized, path)
        _status -> sanitized
      end
    end)
    |> sanitize_realized_feedback_factor_sources(activity)
    |> sanitize_realized_feedback_weight_values(activity)
  end

  defp sanitize_realized_feedback_weight_values(sanitized, source_activity) do
    sanitized =
      realized_feedback_weight_paths()
      |> Enum.reduce(sanitized, fn {_field, path}, sanitized ->
        value = feedback_path_value(sanitized, path)

        case nonnegative_number_status(value) do
          {:invalid_number, _number} -> delete_feedback_path(sanitized, path)
          {:invalid_shape, _shape} -> delete_feedback_path(sanitized, path)
          _status -> sanitized
        end
      end)

    if invalid_realized_feedback_weight?(source_activity) and
         not valid_realized_feedback_weight?(sanitized) do
      [
        ["feedback_weight_source"],
        ["feedback_sample_weight_source"],
        ["sample_weight_source"],
        ["confidence_weight_source"]
      ]
      |> Enum.reduce(sanitized, &delete_feedback_path(&2, &1))
    else
      sanitized
    end
  end

  defp sanitize_realized_feedback_factor_sources(sanitized, source_activity) do
    [
      {"contact_success_factor",
       [
         ["contact_success_factor_source"],
         ["metadata", "contact_success_factor_source"],
         ["throughput_model", "confidence_source"]
       ]},
      {"command_success_factor",
       [["command_success_factor_source"], ["metadata", "command_success_factor_source"]]},
      {"observation_success_factor",
       [["observation_success_factor_source"], ["metadata", "observation_success_factor_source"]]},
      {"maneuver_success_factor",
       [["maneuver_success_factor_source"], ["metadata", "maneuver_success_factor_source"]]}
    ]
    |> Enum.reduce(sanitized, fn {field, source_paths}, sanitized ->
      if invalid_realized_feedback_field?(source_activity, field) and
           not valid_realized_feedback_field?(sanitized, field) do
        Enum.reduce(source_paths, sanitized, &delete_feedback_path(&2, &1))
      else
        sanitized
      end
    end)
  end

  defp invalid_realized_feedback_field?(activity, field) do
    realized_feedback_unit_interval_paths()
    |> Enum.filter(fn {candidate_field, _path} -> candidate_field == field end)
    |> Enum.any?(fn {_field, path} ->
      case unit_interval_number_status(feedback_path_value(activity, path)) do
        {:invalid_number, _number} -> true
        {:invalid_shape, _shape} -> true
        _status -> false
      end
    end)
  end

  defp valid_realized_feedback_field?(activity, field) do
    realized_feedback_unit_interval_paths()
    |> Enum.filter(fn {candidate_field, _path} -> candidate_field == field end)
    |> Enum.any?(fn {_field, path} ->
      case unit_interval_number_status(feedback_path_value(activity, path)) do
        {:ok, _number} -> true
        _status -> false
      end
    end)
  end

  defp realized_feedback_unit_interval_paths do
    [
      {"contact_success_factor", ["contact_success_factor"]},
      {"contact_success_factor", ["metadata", "contact_success_factor"]},
      {"contact_success_factor", ["throughput_model", "contact_success_factor"]},
      {"command_success_factor", ["command_success_factor"]},
      {"command_success_factor", ["metadata", "command_success_factor"]},
      {"observation_success_factor", ["observation_success_factor"]},
      {"observation_success_factor", ["metadata", "observation_success_factor"]},
      {"maneuver_success_factor", ["maneuver_success_factor"]},
      {"maneuver_success_factor", ["metadata", "maneuver_success_factor"]},
      {"completed_fraction", ["completed_fraction"]},
      {"capacity_pack_capacity_fraction", ["capacity_pack_capacity_fraction"]},
      {"image_quality_score", ["image_quality_score"]},
      {"image_quality_score", ["product_quality_score"]},
      {"image_quality_score", ["quality_score"]},
      {"image_quality_score", ["metadata", "image_quality_score"]},
      {"image_quality_score", ["metadata", "product_quality_score"]},
      {"image_quality_score", ["metadata", "quality_score"]},
      {"cloud_cover_fraction", ["cloud_cover_fraction"]},
      {"cloud_cover_fraction", ["cloud_fraction"]},
      {"cloud_cover_fraction", ["cloud_cover"]},
      {"cloud_cover_fraction", ["metadata", "cloud_cover_fraction"]},
      {"cloud_cover_fraction", ["metadata", "cloud_fraction"]},
      {"cloud_cover_fraction", ["metadata", "cloud_cover"]},
      {"blur_score", ["blur_score"]},
      {"blur_score", ["image_blur_score"]},
      {"blur_score", ["sharpness_loss_fraction"]},
      {"blur_score", ["metadata", "blur_score"]},
      {"blur_score", ["metadata", "image_blur_score"]},
      {"blur_score", ["metadata", "sharpness_loss_fraction"]}
    ]
  end

  defp realized_feedback_weight_paths do
    [
      {"feedback_weight", ["feedback_weight"]},
      {"feedback_sample_weight", ["feedback_sample_weight"]},
      {"sample_weight", ["sample_weight"]},
      {"confidence_weight", ["confidence_weight"]}
    ]
  end

  defp invalid_realized_feedback_weight?(activity) do
    realized_feedback_weight_paths()
    |> Enum.any?(fn {_field, path} ->
      case nonnegative_number_status(feedback_path_value(activity, path)) do
        {:invalid_number, _number} -> true
        {:invalid_shape, _shape} -> true
        _status -> false
      end
    end)
  end

  defp valid_realized_feedback_weight?(activity) do
    realized_feedback_weight_paths()
    |> Enum.any?(fn {_field, path} ->
      case nonnegative_number_status(feedback_path_value(activity, path)) do
        {:ok, _number} -> true
        _status -> false
      end
    end)
  end

  defp put_invalid_realized_feedback_sections(row, []), do: row

  defp put_invalid_realized_feedback_sections(row, invalid_sections) do
    reason = invalid_realized_feedback_input_reason(invalid_sections)

    context =
      row
      |> Map.get("realized_activity_context", %{})
      |> Map.put("invalid_realized_feedback_input", true)
      |> Map.put("invalid_realized_feedback_input_reason", reason)
      |> Map.put("invalid_realized_feedback_sections", invalid_sections)

    row
    |> Map.put("invalid_realized_feedback_input", true)
    |> Map.put("invalid_realized_feedback_input_reason", reason)
    |> Map.put("invalid_realized_feedback_sections", invalid_sections)
    |> Map.put("realized_activity_context", context)
  end

  defp invalid_realized_feedback_input_reason(invalid_sections) do
    if Enum.all?(
         invalid_sections,
         &(&1["reason"] == "entry_must_be_unit_interval_number")
       ) do
      "realized_feedback_unit_interval_sections_invalid"
    else
      "realized_feedback_sections_invalid"
    end
  end

  defp feedback_path_value(%{} = map, [key]), do: Map.get(map, key)

  defp feedback_path_value(%{} = map, [key | rest]) do
    case Map.get(map, key) do
      %{} = nested -> feedback_path_value(nested, rest)
      _value -> nil
    end
  end

  defp feedback_path_value(_value, _path), do: nil

  defp delete_feedback_path(%{} = map, [key]), do: Map.delete(map, key)

  defp delete_feedback_path(%{} = map, [key | rest]) do
    case Map.get(map, key) do
      %{} = nested ->
        nested = delete_feedback_path(nested, rest)

        if map_size(nested) == 0 do
          Map.delete(map, key)
        else
          Map.put(map, key, nested)
        end

      _value ->
        map
    end
  end

  defp delete_feedback_path(value, _path), do: value

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
    |> Map.merge(resource_context(activity))
    |> Map.merge(pointing_context(activity))
    |> Map.merge(attitude_context(activity))
    |> Map.merge(command_authority_context(activity))
    |> Map.merge(lighting_context(activity))
    |> Map.merge(observation_quality_context(activity))
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
    |> Map.merge(resource_context(activity))
    |> Map.merge(pointing_context(activity))
    |> Map.merge(attitude_context(activity))
    |> Map.merge(command_authority_context(activity))
    |> Map.merge(lighting_context(activity))
    |> Map.merge(observation_quality_context(activity))
    |> Map.merge(thermal_context(activity))
    |> Map.merge(realized_product_context(activity))
    |> Map.merge(realized_provider_context(activity))
    |> compact_map()
  end

  defp resource_context(activity) do
    %{
      "fuel_margin" => first_number(activity, ["fuel_margin"]),
      "power_margin" => resource_power_margin(activity),
      "storage_margin" => first_number(activity, ["storage_margin"]),
      "downlink_margin" =>
        first_number(activity, ["downlink_margin", "downlink_capacity_margin"]),
      "battery_capacity_wh" => first_number(activity, ["battery_capacity_wh"]),
      "battery_energy_used_wh" => first_number(activity, ["battery_energy_used_wh"]),
      "battery_energy_generated_wh" => battery_energy_generated_wh(activity),
      "battery_state_of_charge" => first_number(activity, ["battery_state_of_charge"]),
      "spacecraft_available" =>
        first_boolean(activity, [
          "spacecraft_available",
          "spacecraft_availability",
          ["metadata", "spacecraft_available"],
          ["metadata", "spacecraft_availability"]
        ]),
      "payload_available" =>
        first_boolean(activity, [
          "payload_available",
          "payload_available?",
          ["metadata", "payload_available"],
          ["metadata", "payload_available?"]
        ]),
      "antenna_available" =>
        first_boolean(activity, [
          "antenna_available",
          "antenna_available?",
          ["metadata", "antenna_available"],
          ["metadata", "antenna_available?"]
        ]),
      "degraded" =>
        first_boolean(activity, [
          "degraded",
          "degraded?",
          ["metadata", "degraded"],
          ["metadata", "degraded?"]
        ]),
      "mode" => first_string(activity, ["mode"]),
      "incompatible_activity_types" =>
        first_value(activity, ["incompatible_activity_types"])
        |> normalize_string_list(),
      "suppressed_activity_types" =>
        first_value(activity, ["suppressed_activity_types"])
        |> normalize_string_list()
    }
    |> compact_map()
  end

  defp pointing_context(activity) do
    %{
      "pointing_mode" => first_string(activity, ["pointing_mode", "attitude_mode"]),
      "pointing_target_id" =>
        first_identifier(activity, ["pointing_target_id", "attitude_target_id"]),
      "boresight_axis" => first_string(activity, ["boresight_axis", "sensor_axis"]),
      "off_nadir_angle_deg" => first_number(activity, ["off_nadir_angle_deg", "look_angle_deg"]),
      "slew_angle_deg" => first_number(activity, ["slew_angle_deg"]),
      "slew_rate_deg_s" => first_number(activity, ["slew_rate_deg_s"]),
      "pointing_error_deg" =>
        first_number(activity, ["pointing_error_deg", "attitude_error_deg"]),
      "pointing_status" => first_string(activity, ["pointing_status", "attitude_status"]),
      "pointing_model" => first_string(activity, ["pointing_model", "attitude_model"]),
      "pointing_source" => first_string(activity, ["pointing_source", "attitude_source"]),
      "pointing_confidence" =>
        first_number(activity, ["pointing_confidence", "attitude_confidence"])
    }
    |> compact_map()
  end

  defp attitude_context(activity) do
    %{
      "attitude_mode" => first_string(activity, ["attitude_mode"]),
      "attitude_target_id" => first_identifier(activity, ["attitude_target_id"]),
      "roll_deg" => first_number(activity, ["roll_deg"]),
      "pitch_deg" => first_number(activity, ["pitch_deg"]),
      "yaw_deg" => first_number(activity, ["yaw_deg"]),
      "attitude_error_deg" => first_number(activity, ["attitude_error_deg"]),
      "attitude_status" => first_string(activity, ["attitude_status"]),
      "attitude_model" => first_string(activity, ["attitude_model"]),
      "attitude_source" => first_string(activity, ["attitude_source"]),
      "attitude_confidence" => first_number(activity, ["attitude_confidence"])
    }
    |> compact_map()
  end

  defp command_authority_context(activity) do
    %{
      "command_authority_status" =>
        first_string(activity, [
          "command_authority_status",
          "authority_status",
          ["metadata", "command_authority_status"],
          ["metadata", "authority_status"]
        ]),
      "required_authority" =>
        first_string(activity, [
          "required_authority",
          "required_escalation_authority",
          ["metadata", "required_authority"],
          ["metadata", "required_escalation_authority"]
        ]),
      "command_safety_status" =>
        first_string(activity, [
          "command_safety_status",
          "safety_status",
          ["metadata", "command_safety_status"],
          ["metadata", "safety_status"]
        ]),
      "command_authorized" =>
        first_boolean(activity, [
          "command_authorized",
          "command_authorized?",
          "authority_granted",
          ["metadata", "command_authorized"],
          ["metadata", "command_authorized?"],
          ["metadata", "authority_granted"]
        ]),
      "command_safety_checked" =>
        first_boolean(activity, [
          "command_safety_checked",
          "command_safety_checked?",
          "safety_checked",
          ["metadata", "command_safety_checked"],
          ["metadata", "command_safety_checked?"],
          ["metadata", "safety_checked"]
        ])
    }
    |> compact_map()
  end

  defp lighting_context(activity) do
    %{
      "eclipse_overlap_fraction" =>
        first_number(activity, [
          "eclipse_overlap_fraction",
          "eclipse_fraction",
          "eclipse_fraction_of_activity"
        ]),
      "eclipse_overlap_s" => first_number(activity, ["eclipse_overlap_s", "eclipse_duration_s"]),
      "lighting_condition" =>
        first_string(activity, ["lighting_condition", "illumination_condition"]),
      "lighting_condition_detail" =>
        first_string(activity, ["lighting_condition_detail", "illumination_detail"]),
      "lighting_condition_model" =>
        first_string(activity, ["lighting_condition_model", "illumination_model"]),
      "lighting_detail_model" =>
        first_string(activity, ["lighting_detail_model", "illumination_detail_model"]),
      "lighting_confidence" =>
        first_number(activity, ["lighting_confidence", "illumination_confidence"])
    }
    |> compact_map()
  end

  defp observation_quality_context(activity) do
    %{
      "image_quality_score" =>
        first_number(activity, [
          "image_quality_score",
          "product_quality_score",
          "quality_score",
          ["metadata", "image_quality_score"],
          ["metadata", "product_quality_score"],
          ["metadata", "quality_score"]
        ]),
      "image_quality_status" =>
        first_string(activity, [
          "image_quality_status",
          "product_quality_status",
          "quality_status"
        ]),
      "image_quality_source" =>
        first_string(activity, [
          "image_quality_source",
          "product_quality_source",
          "quality_source"
        ]),
      "cloud_cover_fraction" =>
        first_unit_interval_number(activity, [
          "cloud_cover_fraction",
          "cloud_fraction",
          "cloud_cover",
          ["metadata", "cloud_cover_fraction"],
          ["metadata", "cloud_fraction"],
          ["metadata", "cloud_cover"]
        ]),
      "blur_score" =>
        first_unit_interval_number(activity, [
          "blur_score",
          "image_blur_score",
          "sharpness_loss_fraction",
          ["metadata", "blur_score"],
          ["metadata", "image_blur_score"],
          ["metadata", "sharpness_loss_fraction"]
        ])
    }
    |> compact_map()
  end

  defp thermal_context(activity) do
    planned_temperature_c = planned_temperature_c(activity)
    actual_temperature_c = actual_temperature_c(activity)

    observed_temperature_c =
      actual_temperature_c || planned_temperature_c || temperature_c(activity)

    %{
      "thermal_zone_id" =>
        first_identifier(activity, [
          "thermal_zone_id",
          "thermal_component_id",
          "thermal_node_id"
        ]),
      "temperature_c" => temperature_c(activity),
      "planned_temperature_c" => planned_temperature_c,
      "actual_temperature_c" => actual_temperature_c,
      "temperature_delta_c" => delta(actual_temperature_c, planned_temperature_c),
      "min_operating_temperature_c" => min_operating_temperature_c(activity),
      "max_operating_temperature_c" => max_operating_temperature_c(activity),
      "thermal_margin_c" => thermal_margin_c(activity, observed_temperature_c),
      "thermal_status" => first_string(activity, ["thermal_status", "temperature_status"]),
      "thermal_model" => first_string(activity, ["thermal_model", "temperature_model"]),
      "thermal_source" => first_string(activity, ["thermal_source", "temperature_source"]),
      "thermal_confidence" =>
        first_number(activity, ["thermal_confidence", "temperature_confidence"])
    }
    |> compact_map()
  end

  defp temperature_c(activity) do
    first_number(activity, ["temperature_c", "temp_c"])
  end

  defp planned_temperature_c(activity) do
    first_number(activity, [
      "planned_temperature_c",
      "planned_temp_c",
      "predicted_temperature_c",
      "estimated_temperature_c"
    ])
  end

  defp actual_temperature_c(activity) do
    first_number(activity, [
      "actual_temperature_c",
      "actual_temp_c",
      "measured_temperature_c",
      "measured_temp_c"
    ])
  end

  defp min_operating_temperature_c(activity) do
    first_number(activity, [
      "min_operating_temperature_c",
      "minimum_operating_temperature_c",
      "min_temperature_c"
    ])
  end

  defp max_operating_temperature_c(activity) do
    first_number(activity, [
      "max_operating_temperature_c",
      "maximum_operating_temperature_c",
      "max_temperature_c"
    ])
  end

  defp thermal_margin_c(activity, observed_temperature_c) do
    first_number(activity, ["thermal_margin_c", "temperature_margin_c"]) ||
      derived_thermal_margin_c(
        observed_temperature_c,
        min_operating_temperature_c(activity),
        max_operating_temperature_c(activity)
      )
  end

  defp derived_thermal_margin_c(temperature_c, min_c, max_c)
       when is_number(temperature_c) and is_number(min_c) and is_number(max_c) do
    min(temperature_c - min_c, max_c - temperature_c)
  end

  defp derived_thermal_margin_c(temperature_c, nil, max_c)
       when is_number(temperature_c) and is_number(max_c),
       do: max_c - temperature_c

  defp derived_thermal_margin_c(temperature_c, min_c, nil)
       when is_number(temperature_c) and is_number(min_c),
       do: temperature_c - min_c

  defp derived_thermal_margin_c(_temperature_c, _min_c, _max_c), do: nil

  defp link_context(activity) do
    %{
      "link_protocol" =>
        first_string(activity, [
          "link_protocol",
          "protocol",
          ["link", "protocol"],
          ["communications", "protocol"],
          ["metadata", "link_protocol"]
        ]),
      "frequency_band" =>
        first_string(activity, [
          "frequency_band",
          "rf_band",
          ["link", "frequency_band"],
          ["communications", "frequency_band"],
          ["metadata", "frequency_band"]
        ]),
      "modulation" =>
        first_string(activity, [
          "modulation",
          "modulation_scheme",
          ["link", "modulation"],
          ["communications", "modulation"],
          ["metadata", "modulation"]
        ]),
      "coding_scheme" =>
        first_string(activity, [
          "coding_scheme",
          "coding",
          ["link", "coding_scheme"],
          ["communications", "coding_scheme"],
          ["metadata", "coding_scheme"]
        ]),
      "polarization" =>
        first_string(activity, [
          "polarization",
          ["link", "polarization"],
          ["communications", "polarization"],
          ["metadata", "polarization"]
        ]),
      "data_rate_mbps" => data_rate_mbps(activity),
      "link_margin_db" =>
        first_number(activity, [
          "link_margin_db",
          "link_margin_d_b",
          ["link", "link_margin_db"],
          ["communications", "link_margin_db"],
          ["metadata", "link_margin_db"]
        ]),
      "snr_db" =>
        first_number(activity, [
          "snr_db",
          "signal_to_noise_db",
          ["link", "snr_db"],
          ["communications", "snr_db"],
          ["metadata", "snr_db"]
        ]),
      "eb_no_db" =>
        first_number(activity, [
          "eb_no_db",
          "ebn0_db",
          "eb_no_d_b",
          ["link", "eb_no_db"],
          ["communications", "eb_no_db"],
          ["metadata", "eb_no_db"]
        ]),
      "bit_error_rate" =>
        first_number(activity, [
          "bit_error_rate",
          "ber",
          ["link", "bit_error_rate"],
          ["communications", "bit_error_rate"],
          ["metadata", "bit_error_rate"]
        ]),
      "packet_loss_rate" =>
        first_number(activity, [
          "packet_loss_rate",
          ["link", "packet_loss_rate"],
          ["communications", "packet_loss_rate"],
          ["metadata", "packet_loss_rate"]
        ]),
      "frame_loss_rate" =>
        first_number(activity, [
          "frame_loss_rate",
          ["link", "frame_loss_rate"],
          ["communications", "frame_loss_rate"],
          ["metadata", "frame_loss_rate"]
        ]),
      "carrier_lock" =>
        first_boolean(activity, [
          "carrier_lock",
          "carrier_locked",
          ["link", "carrier_lock"],
          ["communications", "carrier_lock"],
          ["metadata", "carrier_lock"]
        ]),
      "symbol_lock" =>
        first_boolean(activity, [
          "symbol_lock",
          "symbol_locked",
          ["link", "symbol_lock"],
          ["communications", "symbol_lock"],
          ["metadata", "symbol_lock"]
        ]),
      "link_quality_status" =>
        first_string(activity, [
          "link_quality_status",
          "rf_status",
          ["link", "quality_status"],
          ["communications", "link_quality_status"],
          ["metadata", "link_quality_status"]
        ])
    }
    |> compact_map()
  end

  defp station_calendar_context(activity) do
    capacity_context = station_capacity_context(activity)

    %{
      "station_availability" => Map.get(activity, "station_availability"),
      "station_contention_status" => Map.get(activity, "station_contention_status"),
      "capacity_fraction" => capacity_context["capacity_fraction"],
      "capacity_fraction_min" => capacity_context["capacity_fraction_min"],
      "capacity_fraction_max" => capacity_context["capacity_fraction_max"],
      "station_calendar_entry_id" => Map.get(activity, "station_calendar_entry_id"),
      "station_calendar_provider_id" =>
        first_identifier(activity, ["station_calendar_provider_id"]),
      "station_calendar_provider_entry_id" =>
        first_identifier(activity, ["station_calendar_provider_entry_id"]),
      "station_calendar_directions" =>
        normalize_string_list(Map.get(activity, "station_calendar_directions")),
      "station_calendar_status" => Map.get(activity, "station_calendar_status"),
      "station_calendar_overlap_count" => Map.get(activity, "station_calendar_overlap_count"),
      "station_calendar_overlap_entry_ids" =>
        Map.get(activity, "station_calendar_overlap_entry_ids"),
      "station_calendar_overlap_availabilities" =>
        normalize_string_list(Map.get(activity, "station_calendar_overlap_availabilities")),
      "station_calendar_entry_ambiguous" => Map.get(activity, "station_calendar_entry_ambiguous"),
      "station_calendar_ambiguous_entry_count" =>
        Map.get(activity, "station_calendar_ambiguous_entry_count"),
      "station_calendar_ambiguous_entry_ids" =>
        Map.get(activity, "station_calendar_ambiguous_entry_ids"),
      "station_calendar_reservation_overlap_count" =>
        Map.get(activity, "station_calendar_reservation_overlap_count"),
      "station_calendar_reservation_ids" => Map.get(activity, "station_calendar_reservation_ids"),
      "station_calendar_reservation_expires_at_s" =>
        station_calendar_reservation_expires_at_s(activity),
      "station_calendar_reserved_by" =>
        normalize_string_list(Map.get(activity, "station_calendar_reserved_by")),
      "station_calendar_reservation_statuses" =>
        normalize_string_list(Map.get(activity, "station_calendar_reservation_statuses")),
      "station_calendar_trust_boundary_status" =>
        Map.get(activity, "station_calendar_trust_boundary_status"),
      "source_station_calendar_entry" => Map.get(activity, "source_station_calendar_entry"),
      "source_station_calendar_overlaps" => Map.get(activity, "source_station_calendar_overlaps"),
      "station_reservation_id" => Map.get(activity, "station_reservation_id"),
      "station_reservation_expires_at_s" => station_reservation_expires_at_s(activity),
      "station_reserved_by" => Map.get(activity, "station_reserved_by"),
      "station_reservation_status" => Map.get(activity, "station_reservation_status"),
      "station_reservation_match_status" => Map.get(activity, "station_reservation_match_status")
    }
    |> compact_map()
  end

  defp station_capacity_context(activity) do
    case station_capacity_fractions(activity) do
      [] ->
        %{}

      fractions ->
        %{
          "capacity_fraction" => Enum.min(fractions),
          "capacity_fraction_min" => Enum.min(fractions),
          "capacity_fraction_max" => Enum.max(fractions)
        }
    end
  end

  defp station_capacity_fractions(activity) do
    activity
    |> station_capacity_fraction_candidates()
    |> Enum.map(&unit_interval_number/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_capacity_fraction_candidates(activity) do
    capacity_value_candidates(activity, @station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(activity["source_station_calendar_entry"]) ++
      source_station_capacity_fraction_candidates(activity["source_station_calendar_overlaps"])
  end

  defp source_station_capacity_fraction_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates/1)

  defp source_station_capacity_fraction_candidates(%{} = source) do
    capacity_value_candidates(source, @station_capacity_value_paths)
  end

  defp source_station_capacity_fraction_candidates(_source), do: []

  defp capacity_value_candidates(value, paths) do
    Enum.map(paths, fn
      {:fraction, path} ->
        path_value(value, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(value, path))
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp capacity_percent_fraction(value) do
    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp unit_interval_number(value) do
    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp resource_power_margin(activity) do
    first_number(activity, ["power_margin"]) ||
      first_number(activity, ["battery_state_of_charge"])
  end

  defp battery_energy_generated_wh(activity) do
    first_number(activity, [
      "battery_energy_generated_wh",
      "energy_generated_wh",
      "estimated_energy_generated_wh",
      "estimated_battery_energy_generated_wh",
      "planned_energy_generated_wh",
      ["metadata", "battery_energy_generated_wh"],
      ["metadata", "energy_generated_wh"],
      ["metadata", "estimated_energy_generated_wh"],
      ["metadata", "estimated_battery_energy_generated_wh"],
      ["metadata", "planned_energy_generated_wh"]
    ])
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

  defp normalize_string_list(nil), do: nil

  defp normalize_string_list(values) when is_list(values) do
    values
    |> Enum.map(&stringify_scalar/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp normalize_string_list(value), do: normalize_string_list([value])

  defp station_reservation_expires_at_s(activity) do
    first_numeric_value([
      Map.get(activity, "station_reservation_expires_at_s"),
      Map.get(activity, "reservation_expires_at_s"),
      get_in(activity, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(activity, ["source_station_calendar_entry", "reservation_expires_at_s"])
    ])
  end

  defp station_calendar_reservation_expires_at_s(activity) do
    [
      Map.get(activity, "station_calendar_reservation_expires_at_s"),
      station_reservation_expires_at_s(activity),
      get_in(activity, [
        "source_station_calendar_entry",
        "station_calendar_reservation_expires_at_s"
      ]),
      get_in(activity, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(activity, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      source_station_calendar_overlap_values(
        activity,
        "station_calendar_reservation_expires_at_s"
      ),
      source_station_calendar_overlap_values(activity, "station_reservation_expires_at_s"),
      source_station_calendar_overlap_values(activity, "reservation_expires_at_s")
    ]
    |> normalize_number_list()
  end

  defp first_numeric_value(values), do: Enum.find_value(values, &numeric_value/1)

  defp source_station_calendar_overlap_values(activity, field) do
    activity
    |> Map.get("source_station_calendar_overlaps")
    |> List.wrap()
    |> Enum.flat_map(fn
      %{} = overlap -> [Map.get(overlap, field)]
      _overlap -> []
    end)
  end

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&number_values/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value), do: normalize_number_list([value])

  defp number_values(%{} = value) do
    [
      Map.get(value, "station_calendar_reservation_expires_at_s"),
      Map.get(value, "station_reservation_expires_at_s"),
      Map.get(value, "reservation_expires_at_s")
    ]
    |> normalize_number_list()
    |> List.wrap()
  end

  defp number_values(values) when is_list(values), do: Enum.flat_map(values, &number_values/1)

  defp number_values(value) do
    case numeric_value(value) do
      nil -> []
      number -> [number]
    end
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
    planned_throughput = value(planned, "estimated_throughput_mb")

    throughput_denominator =
      planned_throughput || value(planned, "required_downlink_mb") ||
        value(realized, "required_downlink_mb")

    actual_throughput = value(realized, "actual_throughput_mb")
    planned_data_volume_mb = value(planned, "planned_data_volume_mb")
    actual_data_volume_mb = value(realized, "actual_data_volume_mb")
    planned_delta_v = value(planned, "delta_v_km_s")
    realized_delta_v = value(realized, "delta_v_km_s")
    planned_delta_v_magnitude = value(planned, "delta_v_magnitude_km_s")
    realized_delta_v_magnitude = value(realized, "delta_v_magnitude_km_s")

    execution_uncertainty_context =
      execution_uncertainty_reconciliation_context(planned, realized)

    match_strategy = value(realized, "match_strategy") || "unmatched_planned"
    protection_decision = feedback_protection_decision(planned, realized)
    start_delta_s = delta(value(realized, "actual_starts_at_s"), value(planned, "starts_at_s"))
    end_delta_s = delta(value(realized, "actual_ends_at_s"), value(planned, "ends_at_s"))
    max_timing_delta_s = max_abs_timing_delta_s(start_delta_s, end_delta_s)

    %{
      "activity_id" => id,
      "status" => row_status(planned, realized),
      "match_strategy" => match_strategy,
      "ambiguous_planned_timeline_id" => value(realized, "ambiguous_planned_timeline_id"),
      "ambiguous_planned_match_count" => value(realized, "ambiguous_planned_match_count"),
      "ambiguous_planned_activity_ids" => value(realized, "ambiguous_planned_activity_ids"),
      "ambiguous_planned_activities" => value(realized, "ambiguous_planned_activities"),
      "feedback_kind" => feedback_kind,
      "planned_timeline_id" => value(planned, "timeline_id"),
      "timeline_identity" => value(planned, "timeline_identity"),
      "realized_timeline_id" => value(realized, "timeline_id"),
      "realized_activity_id" => value(realized, "realized_activity_id"),
      "realized_source" => value(realized, "source"),
      "realized_provider" => value(realized, "provider"),
      "realized_source_quality" => value(realized, "source_quality"),
      "realized_adapter" => value(realized, "adapter"),
      "realized_adapter_version" => value(realized, "adapter_version"),
      "realized_external_id" => value(realized, "external_id"),
      "realized_schema_contract" => value(realized, "schema_contract"),
      "realized_trust_boundary" => value(realized, "trust_boundary"),
      "realized_received_at" => value(realized, "received_at"),
      "realized_ingested_at" => value(realized, "ingested_at"),
      "realized_provenance" => value(realized, "provenance"),
      "invalid_realized_feedback_input" => value(realized, "invalid_realized_feedback_input"),
      "invalid_realized_feedback_input_reason" =>
        value(realized, "invalid_realized_feedback_input_reason"),
      "invalid_realized_feedback_sections" =>
        value(realized, "invalid_realized_feedback_sections"),
      "unsupported_realized_status" => value(realized, "unsupported_realized_status"),
      "invalid_cadence_import" => value(realized, "invalid_cadence_import"),
      "invalid_cadence_import_reason" => value(realized, "invalid_cadence_import_reason"),
      "source_cadence_import" => value(realized, "source_cadence_import"),
      "planned_type" => value(planned, "type"),
      "realized_type" => value(realized, "type"),
      "planned_status" => value(planned, "status"),
      "realized_status" => value(realized, "status"),
      "feedback_status" => value(realized, "feedback_status"),
      "status_transition" => feedback_status_transition(planned, realized),
      "planned_protection_decision" => value(protection_decision, "protection_decision"),
      "planned_protection_category" => value(protection_decision, "protection_category"),
      "planned_protection_reason" => value(protection_decision, "reason"),
      "source_protection_decision" => protection_decision,
      "planned_activity" => value(planned, "source_activity"),
      "realized_activity" => value(realized, "source_activity"),
      "source_activity_context" => feedback_source_activity_context(planned),
      "realized_activity_context" => value(realized, "realized_activity_context"),
      "planned_starts_at_s" => value(planned, "starts_at_s"),
      "planned_ends_at_s" => value(planned, "ends_at_s"),
      "actual_starts_at_s" => value(realized, "actual_starts_at_s"),
      "actual_ends_at_s" => value(realized, "actual_ends_at_s"),
      "start_delta_s" => start_delta_s,
      "end_delta_s" => end_delta_s,
      "max_timing_delta_s" => if(is_number(timing_variance_threshold_s), do: max_timing_delta_s),
      "timing_variance_threshold_s" => timing_variance_threshold_s,
      "timing_variance_status" =>
        timing_variance_status(max_timing_delta_s, timing_variance_threshold_s),
      "direction" => value(planned, "direction") || value(realized, "direction"),
      "planned_direction" => value(planned, "direction"),
      "realized_direction" => value(realized, "direction"),
      "direction_match_status" =>
        match_status(value(planned, "direction"), value(realized, "direction")),
      "ground_station_id" =>
        value(planned, "ground_station_id") || value(realized, "ground_station_id"),
      "planned_ground_station_id" => value(planned, "ground_station_id"),
      "realized_ground_station_id" => value(realized, "ground_station_id"),
      "ground_station_match_status" =>
        match_status(value(planned, "ground_station_id"), value(realized, "ground_station_id")),
      "spacecraft_id" => value(planned, "spacecraft_id") || value(realized, "spacecraft_id"),
      "target_id" => value(planned, "target_id") || value(realized, "target_id"),
      "planned_target_id" => value(planned, "target_id"),
      "realized_target_id" => value(realized, "target_id"),
      "target_match_status" =>
        match_status(value(planned, "target_id"), value(realized, "target_id")),
      "resource_id" => value(planned, "resource_id") || value(realized, "resource_id"),
      "planned_resource_id" => value(planned, "resource_id"),
      "realized_resource_id" => value(realized, "resource_id"),
      "resource_match_status" =>
        match_status(value(planned, "resource_id"), value(realized, "resource_id")),
      "collection_id" => value(planned, "collection_id") || value(realized, "collection_id"),
      "planned_collection_id" => value(planned, "collection_id"),
      "realized_collection_id" => value(realized, "collection_id"),
      "collection_match_status" =>
        match_status(value(planned, "collection_id"), value(realized, "collection_id")),
      "product_id" => value(planned, "product_id") || value(realized, "product_id"),
      "planned_product_id" => value(planned, "product_id"),
      "realized_product_id" => value(realized, "product_id"),
      "product_match_status" =>
        match_status(value(planned, "product_id"), value(realized, "product_id")),
      "product_ids" => value(planned, "product_ids") || value(realized, "product_ids"),
      "planned_product_ids" => value(planned, "product_ids"),
      "realized_product_ids" => value(realized, "product_ids"),
      "product_ids_match_status" =>
        match_status(value(planned, "product_ids"), value(realized, "product_ids")),
      "payload_id" => value(planned, "payload_id") || value(realized, "payload_id"),
      "planned_payload_id" => value(planned, "payload_id"),
      "realized_payload_id" => value(realized, "payload_id"),
      "payload_match_status" =>
        match_status(value(planned, "payload_id"), value(realized, "payload_id")),
      "instrument_id" => value(planned, "instrument_id") || value(realized, "instrument_id"),
      "planned_instrument_id" => value(planned, "instrument_id"),
      "realized_instrument_id" => value(realized, "instrument_id"),
      "instrument_match_status" =>
        match_status(value(planned, "instrument_id"), value(realized, "instrument_id")),
      "pointing_target_id" =>
        value(planned, "pointing_target_id") || value(realized, "pointing_target_id"),
      "planned_pointing_target_id" => value(planned, "pointing_target_id"),
      "realized_pointing_target_id" => value(realized, "pointing_target_id"),
      "pointing_target_match_status" =>
        match_status(value(planned, "pointing_target_id"), value(realized, "pointing_target_id")),
      "pointing_mode" => value(planned, "pointing_mode") || value(realized, "pointing_mode"),
      "planned_pointing_mode" => value(planned, "pointing_mode"),
      "realized_pointing_mode" => value(realized, "pointing_mode"),
      "pointing_mode_match_status" =>
        match_status(value(planned, "pointing_mode"), value(realized, "pointing_mode")),
      "attitude_target_id" =>
        value(planned, "attitude_target_id") || value(realized, "attitude_target_id"),
      "planned_attitude_target_id" => value(planned, "attitude_target_id"),
      "realized_attitude_target_id" => value(realized, "attitude_target_id"),
      "attitude_target_match_status" =>
        match_status(value(planned, "attitude_target_id"), value(realized, "attitude_target_id")),
      "attitude_mode" => value(planned, "attitude_mode") || value(realized, "attitude_mode"),
      "planned_attitude_mode" => value(planned, "attitude_mode"),
      "realized_attitude_mode" => value(realized, "attitude_mode"),
      "attitude_mode_match_status" =>
        match_status(value(planned, "attitude_mode"), value(realized, "attitude_mode")),
      "link_protocol" => value(planned, "link_protocol") || value(realized, "link_protocol"),
      "planned_link_protocol" => value(planned, "link_protocol"),
      "realized_link_protocol" => value(realized, "link_protocol"),
      "link_protocol_match_status" =>
        match_status(value(planned, "link_protocol"), value(realized, "link_protocol")),
      "frequency_band" => value(planned, "frequency_band") || value(realized, "frequency_band"),
      "planned_frequency_band" => value(planned, "frequency_band"),
      "realized_frequency_band" => value(realized, "frequency_band"),
      "frequency_band_match_status" =>
        match_status(value(planned, "frequency_band"), value(realized, "frequency_band")),
      "modulation" => value(planned, "modulation") || value(realized, "modulation"),
      "planned_modulation" => value(planned, "modulation"),
      "realized_modulation" => value(realized, "modulation"),
      "modulation_match_status" =>
        match_status(value(planned, "modulation"), value(realized, "modulation")),
      "coding_scheme" => value(planned, "coding_scheme") || value(realized, "coding_scheme"),
      "planned_coding_scheme" => value(planned, "coding_scheme"),
      "realized_coding_scheme" => value(realized, "coding_scheme"),
      "coding_scheme_match_status" =>
        match_status(value(planned, "coding_scheme"), value(realized, "coding_scheme")),
      "polarization" => value(planned, "polarization") || value(realized, "polarization"),
      "planned_polarization" => value(planned, "polarization"),
      "realized_polarization" => value(realized, "polarization"),
      "polarization_match_status" =>
        match_status(value(planned, "polarization"), value(realized, "polarization")),
      "data_rate_mbps" => realized_or_planned(realized, planned, "data_rate_mbps"),
      "planned_data_rate_mbps" => value(planned, "data_rate_mbps"),
      "realized_data_rate_mbps" => value(realized, "data_rate_mbps"),
      "data_rate_delta_mbps" =>
        delta(value(realized, "data_rate_mbps"), value(planned, "data_rate_mbps")),
      "link_margin_db" => realized_or_planned(realized, planned, "link_margin_db"),
      "planned_link_margin_db" => value(planned, "link_margin_db"),
      "realized_link_margin_db" => value(realized, "link_margin_db"),
      "link_margin_delta_db" =>
        delta(value(realized, "link_margin_db"), value(planned, "link_margin_db")),
      "snr_db" => realized_or_planned(realized, planned, "snr_db"),
      "planned_snr_db" => value(planned, "snr_db"),
      "realized_snr_db" => value(realized, "snr_db"),
      "snr_delta_db" => delta(value(realized, "snr_db"), value(planned, "snr_db")),
      "eb_no_db" => realized_or_planned(realized, planned, "eb_no_db"),
      "planned_eb_no_db" => value(planned, "eb_no_db"),
      "realized_eb_no_db" => value(realized, "eb_no_db"),
      "eb_no_delta_db" => delta(value(realized, "eb_no_db"), value(planned, "eb_no_db")),
      "bit_error_rate" => realized_or_planned(realized, planned, "bit_error_rate"),
      "planned_bit_error_rate" => value(planned, "bit_error_rate"),
      "realized_bit_error_rate" => value(realized, "bit_error_rate"),
      "packet_loss_rate" => realized_or_planned(realized, planned, "packet_loss_rate"),
      "planned_packet_loss_rate" => value(planned, "packet_loss_rate"),
      "realized_packet_loss_rate" => value(realized, "packet_loss_rate"),
      "frame_loss_rate" => realized_or_planned(realized, planned, "frame_loss_rate"),
      "planned_frame_loss_rate" => value(planned, "frame_loss_rate"),
      "realized_frame_loss_rate" => value(realized, "frame_loss_rate"),
      "carrier_lock" => realized_or_planned(realized, planned, "carrier_lock"),
      "planned_carrier_lock" => value(planned, "carrier_lock"),
      "realized_carrier_lock" => value(realized, "carrier_lock"),
      "symbol_lock" => realized_or_planned(realized, planned, "symbol_lock"),
      "planned_symbol_lock" => value(planned, "symbol_lock"),
      "realized_symbol_lock" => value(realized, "symbol_lock"),
      "link_quality_status" => realized_or_planned(realized, planned, "link_quality_status"),
      "planned_link_quality_status" => value(planned, "link_quality_status"),
      "realized_link_quality_status" => value(realized, "link_quality_status"),
      "boresight_axis" => value(planned, "boresight_axis") || value(realized, "boresight_axis"),
      "planned_off_nadir_angle_deg" => value(planned, "off_nadir_angle_deg"),
      "realized_off_nadir_angle_deg" => value(realized, "off_nadir_angle_deg"),
      "off_nadir_angle_delta_deg" =>
        delta(value(realized, "off_nadir_angle_deg"), value(planned, "off_nadir_angle_deg")),
      "planned_slew_angle_deg" => value(planned, "slew_angle_deg"),
      "realized_slew_angle_deg" => value(realized, "slew_angle_deg"),
      "slew_angle_delta_deg" =>
        delta(value(realized, "slew_angle_deg"), value(planned, "slew_angle_deg")),
      "pointing_error_deg" => realized_or_planned(realized, planned, "pointing_error_deg"),
      "pointing_status" => realized_or_planned(realized, planned, "pointing_status"),
      "pointing_model" => realized_or_planned(realized, planned, "pointing_model"),
      "pointing_source" => realized_or_planned(realized, planned, "pointing_source"),
      "pointing_confidence" => realized_or_planned(realized, planned, "pointing_confidence"),
      "planned_roll_deg" => value(planned, "roll_deg"),
      "realized_roll_deg" => value(realized, "roll_deg"),
      "roll_delta_deg" => delta(value(realized, "roll_deg"), value(planned, "roll_deg")),
      "planned_pitch_deg" => value(planned, "pitch_deg"),
      "realized_pitch_deg" => value(realized, "pitch_deg"),
      "pitch_delta_deg" => delta(value(realized, "pitch_deg"), value(planned, "pitch_deg")),
      "planned_yaw_deg" => value(planned, "yaw_deg"),
      "realized_yaw_deg" => value(realized, "yaw_deg"),
      "yaw_delta_deg" => delta(value(realized, "yaw_deg"), value(planned, "yaw_deg")),
      "attitude_error_deg" => realized_or_planned(realized, planned, "attitude_error_deg"),
      "attitude_status" => realized_or_planned(realized, planned, "attitude_status"),
      "attitude_model" => realized_or_planned(realized, planned, "attitude_model"),
      "attitude_source" => realized_or_planned(realized, planned, "attitude_source"),
      "attitude_confidence" => realized_or_planned(realized, planned, "attitude_confidence"),
      "command_authority_status" =>
        value(planned, "command_authority_status") ||
          value(realized, "command_authority_status"),
      "planned_command_authority_status" => value(planned, "command_authority_status"),
      "realized_command_authority_status" => value(realized, "command_authority_status"),
      "command_authority_status_match_status" =>
        match_status(
          value(planned, "command_authority_status"),
          value(realized, "command_authority_status")
        ),
      "required_authority" =>
        value(planned, "required_authority") || value(realized, "required_authority"),
      "planned_required_authority" => value(planned, "required_authority"),
      "realized_required_authority" => value(realized, "required_authority"),
      "required_authority_match_status" =>
        match_status(value(planned, "required_authority"), value(realized, "required_authority")),
      "command_safety_status" =>
        value(planned, "command_safety_status") || value(realized, "command_safety_status"),
      "planned_command_safety_status" => value(planned, "command_safety_status"),
      "realized_command_safety_status" => value(realized, "command_safety_status"),
      "command_safety_status_match_status" =>
        match_status(
          value(planned, "command_safety_status"),
          value(realized, "command_safety_status")
        ),
      "command_authorized" => realized_or_planned(realized, planned, "command_authorized"),
      "planned_command_authorized" => value(planned, "command_authorized"),
      "realized_command_authorized" => value(realized, "command_authorized"),
      "command_authorized_match_status" =>
        match_status(value(planned, "command_authorized"), value(realized, "command_authorized")),
      "command_safety_checked" =>
        realized_or_planned(realized, planned, "command_safety_checked"),
      "planned_command_safety_checked" => value(planned, "command_safety_checked"),
      "realized_command_safety_checked" => value(realized, "command_safety_checked"),
      "command_safety_checked_match_status" =>
        match_status(
          value(planned, "command_safety_checked"),
          value(realized, "command_safety_checked")
        ),
      "eclipse_overlap_fraction" =>
        realized_or_planned(realized, planned, "eclipse_overlap_fraction"),
      "planned_eclipse_overlap_fraction" => value(planned, "eclipse_overlap_fraction"),
      "realized_eclipse_overlap_fraction" => value(realized, "eclipse_overlap_fraction"),
      "eclipse_overlap_s" => realized_or_planned(realized, planned, "eclipse_overlap_s"),
      "planned_eclipse_overlap_s" => value(planned, "eclipse_overlap_s"),
      "realized_eclipse_overlap_s" => value(realized, "eclipse_overlap_s"),
      "lighting_condition" =>
        value(planned, "lighting_condition") || value(realized, "lighting_condition"),
      "planned_lighting_condition" => value(planned, "lighting_condition"),
      "realized_lighting_condition" => value(realized, "lighting_condition"),
      "lighting_condition_match_status" =>
        match_status(value(planned, "lighting_condition"), value(realized, "lighting_condition")),
      "lighting_condition_detail" =>
        realized_or_planned(realized, planned, "lighting_condition_detail"),
      "lighting_condition_model" =>
        realized_or_planned(realized, planned, "lighting_condition_model"),
      "lighting_detail_model" => realized_or_planned(realized, planned, "lighting_detail_model"),
      "lighting_confidence" => realized_or_planned(realized, planned, "lighting_confidence"),
      "image_quality_score" => realized_or_planned(realized, planned, "image_quality_score"),
      "planned_image_quality_score" => value(planned, "image_quality_score"),
      "realized_image_quality_score" => value(realized, "image_quality_score"),
      "image_quality_score_delta" =>
        delta(value(realized, "image_quality_score"), value(planned, "image_quality_score")),
      "image_quality_status" => realized_or_planned(realized, planned, "image_quality_status"),
      "planned_image_quality_status" => value(planned, "image_quality_status"),
      "realized_image_quality_status" => value(realized, "image_quality_status"),
      "image_quality_status_match_status" =>
        match_status(
          value(planned, "image_quality_status"),
          value(realized, "image_quality_status")
        ),
      "image_quality_source" => realized_or_planned(realized, planned, "image_quality_source"),
      "cloud_cover_fraction" => realized_or_planned(realized, planned, "cloud_cover_fraction"),
      "planned_cloud_cover_fraction" => value(planned, "cloud_cover_fraction"),
      "realized_cloud_cover_fraction" => value(realized, "cloud_cover_fraction"),
      "cloud_cover_fraction_delta" =>
        delta(value(realized, "cloud_cover_fraction"), value(planned, "cloud_cover_fraction")),
      "blur_score" => realized_or_planned(realized, planned, "blur_score"),
      "planned_blur_score" => value(planned, "blur_score"),
      "realized_blur_score" => value(realized, "blur_score"),
      "blur_score_delta" => delta(value(realized, "blur_score"), value(planned, "blur_score")),
      "thermal_zone_id" =>
        value(planned, "thermal_zone_id") || value(realized, "thermal_zone_id"),
      "planned_temperature_c" => value(planned, "planned_temperature_c"),
      "actual_temperature_c" => value(realized, "actual_temperature_c"),
      "temperature_delta_c" =>
        delta(value(realized, "actual_temperature_c"), value(planned, "planned_temperature_c")),
      "min_operating_temperature_c" =>
        realized_or_planned(realized, planned, "min_operating_temperature_c"),
      "max_operating_temperature_c" =>
        realized_or_planned(realized, planned, "max_operating_temperature_c"),
      "thermal_margin_c" => realized_or_planned(realized, planned, "thermal_margin_c"),
      "thermal_status" => realized_or_planned(realized, planned, "thermal_status"),
      "thermal_model" => realized_or_planned(realized, planned, "thermal_model"),
      "thermal_source" => realized_or_planned(realized, planned, "thermal_source"),
      "thermal_confidence" => realized_or_planned(realized, planned, "thermal_confidence"),
      "source_window_id" =>
        value(planned, "source_window_id") || value(realized, "source_window_id"),
      "planned_source_window_id" => value(planned, "source_window_id"),
      "realized_source_window_id" => value(realized, "source_window_id"),
      "source_window_match_status" =>
        match_status(value(planned, "source_window_id"), value(realized, "source_window_id")),
      "source_window_type" => value(planned, "source_window_type"),
      "contact_success_factor" =>
        value(realized, "contact_success_factor") || value(planned, "contact_success_factor"),
      "contact_success_factor_source" =>
        value(realized, "contact_success_factor_source") ||
          value(planned, "contact_success_factor_source"),
      "command_success_factor" =>
        value(realized, "command_success_factor") || value(planned, "command_success_factor"),
      "command_success_factor_source" =>
        value(realized, "command_success_factor_source") ||
          value(planned, "command_success_factor_source"),
      "observation_success_factor" =>
        value(realized, "observation_success_factor") ||
          value(planned, "observation_success_factor"),
      "observation_success_factor_source" =>
        value(realized, "observation_success_factor_source") ||
          value(planned, "observation_success_factor_source"),
      "feedback_weight" => feedback_weight(planned, realized),
      "feedback_weight_source" => feedback_weight_source(planned, realized),
      "maneuver_success_factor" =>
        value(realized, "maneuver_success_factor") || value(planned, "maneuver_success_factor"),
      "maneuver_success_factor_source" =>
        value(realized, "maneuver_success_factor_source") ||
          value(planned, "maneuver_success_factor_source"),
      "dependency_activity_ids" => value(planned, "dependency_activity_ids"),
      "dependency_timeline_ids" => value(planned, "dependency_timeline_ids"),
      "exclusive_with_activity_ids" => value(planned, "exclusive_with_activity_ids"),
      "exclusive_with_timeline_ids" => value(planned, "exclusive_with_timeline_ids"),
      "cadence_import_status" => value(planned, "cadence_import_status"),
      "cadence_import_type" => value(planned, "cadence_import_type"),
      "cadence_import_id" => value(planned, "cadence_import_id"),
      "cadence_import_contract" => value(planned, "cadence_import_contract"),
      "has_cadence_import" => value(planned, "has_cadence_import"),
      "planned_operator_action" => value(planned, "required_operator_action"),
      "planned_operator_action_reason" => value(planned, "operator_action_reason"),
      "superseded_planned_operator_action" =>
        value(planned, "superseded_required_operator_action"),
      "superseded_planned_operator_action_reason" =>
        value(planned, "superseded_operator_action_reason"),
      "timeline_integrity_status" => value(planned, "timeline_integrity_status"),
      "timeline_integrity_issue_count" => value(planned, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" => value(planned, "timeline_integrity_issue_types"),
      "timeline_integrity_issues" => value(planned, "timeline_integrity_issues"),
      "invalid_activity_input" => value(planned, "invalid_activity_input"),
      "invalid_activity_input_reason" => value(planned, "invalid_activity_input_reason"),
      "missing_dependency_activity_ids" => value(planned, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" => value(planned, "missing_dependency_timeline_ids"),
      "dependency_cycle_activity_ids" => value(planned, "dependency_cycle_activity_ids"),
      "dependency_cycle_timeline_ids" => value(planned, "dependency_cycle_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        value(planned, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        value(planned, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        value(planned, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        value(planned, "exclusivity_violation_timeline_ids"),
      "exclusivity_violation_group" => value(planned, "exclusivity_violation_group"),
      "planned_estimated_throughput_mb" => planned_throughput,
      "actual_throughput_mb" => actual_throughput,
      "actual_data_rate_throughput_derivation" =>
        value(realized, "actual_data_rate_throughput_derivation"),
      "throughput_delta_mb" => delta(actual_throughput, planned_throughput),
      "throughput_completion_fraction" =>
        throughput_fraction(actual_throughput, throughput_denominator),
      "planned_data_volume_mb" => planned_data_volume_mb,
      "actual_data_volume_mb" => actual_data_volume_mb,
      "data_volume_delta_mb" => delta(actual_data_volume_mb, planned_data_volume_mb),
      "data_volume_completion_fraction" =>
        throughput_fraction(actual_data_volume_mb, planned_data_volume_mb),
      "required_downlink_mb" =>
        value(planned, "required_downlink_mb") || value(realized, "required_downlink_mb"),
      "planned_delta_v_km_s" => planned_delta_v,
      "realized_delta_v_km_s" => realized_delta_v,
      "delta_v_delta_km_s" => vector_delta(realized_delta_v, planned_delta_v),
      "planned_delta_v_magnitude_km_s" => planned_delta_v_magnitude,
      "realized_delta_v_magnitude_km_s" => realized_delta_v_magnitude,
      "delta_v_magnitude_delta_km_s" =>
        delta(realized_delta_v_magnitude, planned_delta_v_magnitude),
      "delta_v_match_status" => match_status(planned_delta_v, realized_delta_v),
      "contact_success" =>
        contact_success(
          feedback_kind,
          value(realized, "status"),
          value(realized, "contact_success"),
          value(realized, "contact_result")
        ),
      "contact_result" => provider_result_artifact_value(value(realized, "contact_result")),
      "command_success" =>
        command_success(
          feedback_kind,
          value(realized, "status"),
          value(realized, "command_success"),
          value(realized, "command_result")
        ),
      "command_result" => provider_result_artifact_value(value(realized, "command_result")),
      "observation_success" =>
        observation_success(
          feedback_kind,
          value(realized, "status"),
          value(realized, "observation_success"),
          value(realized, "observation_result")
        ),
      "observation_result" =>
        provider_result_artifact_value(value(realized, "observation_result")),
      "maneuver_success" =>
        maneuver_success(
          feedback_kind,
          value(realized, "status"),
          value(realized, "maneuver_success"),
          value(realized, "maneuver_result")
        ),
      "maneuver_result" => provider_result_artifact_value(value(realized, "maneuver_result")),
      "completed_fraction" => value(realized, "completed_fraction"),
      "fuel_margin" => realized_or_planned(realized, planned, "fuel_margin"),
      "power_margin" => realized_or_planned(realized, planned, "power_margin"),
      "storage_margin" => realized_or_planned(realized, planned, "storage_margin"),
      "downlink_margin" => realized_or_planned(realized, planned, "downlink_margin"),
      "battery_capacity_wh" => realized_or_planned(realized, planned, "battery_capacity_wh"),
      "battery_energy_used_wh" =>
        realized_or_planned(realized, planned, "battery_energy_used_wh"),
      "battery_energy_generated_wh" =>
        realized_or_planned(realized, planned, "battery_energy_generated_wh"),
      "battery_state_of_charge" =>
        realized_or_planned(realized, planned, "battery_state_of_charge"),
      "spacecraft_available" => realized_or_planned(realized, planned, "spacecraft_available"),
      "planned_spacecraft_available" => value(planned, "spacecraft_available"),
      "realized_spacecraft_available" => value(realized, "spacecraft_available"),
      "spacecraft_available_match_status" =>
        match_status(
          value(planned, "spacecraft_available"),
          value(realized, "spacecraft_available")
        ),
      "payload_available" => realized_or_planned(realized, planned, "payload_available"),
      "planned_payload_available" => value(planned, "payload_available"),
      "realized_payload_available" => value(realized, "payload_available"),
      "payload_available_match_status" =>
        match_status(value(planned, "payload_available"), value(realized, "payload_available")),
      "antenna_available" => realized_or_planned(realized, planned, "antenna_available"),
      "planned_antenna_available" => value(planned, "antenna_available"),
      "realized_antenna_available" => value(realized, "antenna_available"),
      "antenna_available_match_status" =>
        match_status(value(planned, "antenna_available"), value(realized, "antenna_available")),
      "degraded" => realized_or_planned(realized, planned, "degraded"),
      "planned_degraded" => value(planned, "degraded"),
      "realized_degraded" => value(realized, "degraded"),
      "degraded_match_status" =>
        match_status(value(planned, "degraded"), value(realized, "degraded")),
      "mode" => realized_or_planned(realized, planned, "mode"),
      "planned_mode" => value(planned, "mode"),
      "realized_mode" => value(realized, "mode"),
      "mode_match_status" => match_status(value(planned, "mode"), value(realized, "mode")),
      "incompatible_activity_types" =>
        realized_or_planned(realized, planned, "incompatible_activity_types"),
      "suppressed_activity_types" =>
        realized_or_planned(realized, planned, "suppressed_activity_types"),
      "station_availability" => realized_or_planned(realized, planned, "station_availability"),
      "station_contention_status" =>
        realized_or_planned(realized, planned, "station_contention_status"),
      "capacity_fraction" => realized_or_planned(realized, planned, "capacity_fraction"),
      "capacity_fraction_min" => realized_or_planned(realized, planned, "capacity_fraction_min"),
      "capacity_fraction_max" => realized_or_planned(realized, planned, "capacity_fraction_max"),
      "station_calendar_entry_id" =>
        realized_or_planned(realized, planned, "station_calendar_entry_id"),
      "station_calendar_provider_id" =>
        realized_or_planned(realized, planned, "station_calendar_provider_id"),
      "station_calendar_provider_entry_id" =>
        realized_or_planned(realized, planned, "station_calendar_provider_entry_id"),
      "station_calendar_directions" =>
        realized_or_planned(realized, planned, "station_calendar_directions"),
      "station_calendar_status" =>
        realized_or_planned(realized, planned, "station_calendar_status"),
      "station_calendar_overlap_count" =>
        realized_or_planned(realized, planned, "station_calendar_overlap_count"),
      "station_calendar_overlap_entry_ids" =>
        realized_or_planned(realized, planned, "station_calendar_overlap_entry_ids"),
      "station_calendar_overlap_availabilities" =>
        realized_or_planned(realized, planned, "station_calendar_overlap_availabilities"),
      "station_calendar_entry_ambiguous" =>
        realized_or_planned(realized, planned, "station_calendar_entry_ambiguous"),
      "station_calendar_ambiguous_entry_count" =>
        realized_or_planned(realized, planned, "station_calendar_ambiguous_entry_count"),
      "station_calendar_ambiguous_entry_ids" =>
        realized_or_planned(realized, planned, "station_calendar_ambiguous_entry_ids"),
      "station_calendar_reservation_overlap_count" =>
        realized_or_planned(realized, planned, "station_calendar_reservation_overlap_count"),
      "station_calendar_reservation_ids" =>
        realized_or_planned(realized, planned, "station_calendar_reservation_ids"),
      "station_calendar_reservation_expires_at_s" =>
        realized_or_planned(realized, planned, "station_calendar_reservation_expires_at_s"),
      "station_calendar_reserved_by" =>
        realized_or_planned(realized, planned, "station_calendar_reserved_by"),
      "station_calendar_reservation_statuses" =>
        realized_or_planned(realized, planned, "station_calendar_reservation_statuses"),
      "station_calendar_trust_boundary_status" =>
        realized_or_planned(realized, planned, "station_calendar_trust_boundary_status"),
      "source_station_calendar_entry" =>
        realized_or_planned(realized, planned, "source_station_calendar_entry"),
      "source_station_calendar_overlaps" =>
        realized_or_planned(realized, planned, "source_station_calendar_overlaps"),
      "station_reservation_id" =>
        realized_or_planned(realized, planned, "station_reservation_id"),
      "station_reservation_expires_at_s" =>
        realized_or_planned(realized, planned, "station_reservation_expires_at_s"),
      "station_reserved_by" => realized_or_planned(realized, planned, "station_reserved_by"),
      "station_reservation_status" =>
        realized_or_planned(realized, planned, "station_reservation_status"),
      "station_reservation_match_status" =>
        realized_or_planned(realized, planned, "station_reservation_match_status"),
      "reason" => value(realized, "reason")
    }
    |> Map.merge(execution_uncertainty_context)
    |> put_duplicate_realized_feedback(realized_matches)
    |> put_identity_mismatch_summary()
    |> put_operational_feedback_exclusion()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp realized_or_planned(realized, planned, field) do
    case value(realized, field) do
      nil -> value(planned, field)
      value -> value
    end
  end

  defp put_identity_mismatch_summary(row) do
    mismatch_fields =
      [
        {"direction", "direction_match_status"},
        {"ground_station", "ground_station_match_status"},
        {"target", "target_match_status"},
        {"resource", "resource_match_status"},
        {"collection", "collection_match_status"},
        {"product", "product_match_status"},
        {"product_ids", "product_ids_match_status"},
        {"payload", "payload_match_status"},
        {"instrument", "instrument_match_status"},
        {"pointing_target", "pointing_target_match_status"},
        {"link_protocol", "link_protocol_match_status"},
        {"frequency_band", "frequency_band_match_status"},
        {"modulation", "modulation_match_status"},
        {"coding_scheme", "coding_scheme_match_status"},
        {"polarization", "polarization_match_status"},
        {"source_window", "source_window_match_status"}
      ]
      |> Enum.filter(fn {_field, status_field} -> row[status_field] == "mismatch" end)
      |> Enum.map(fn {field, _status_field} -> field end)

    if mismatch_fields == [] do
      row
    else
      row
      |> Map.put("identity_mismatch_fields", mismatch_fields)
      |> Map.put("identity_mismatch_count", length(mismatch_fields))
      |> Map.put("identity_match_status", "mismatch")
    end
  end

  defp put_operational_feedback_exclusion(row) do
    case operational_feedback_exclusion_reason(row) do
      nil ->
        row

      reason ->
        status =
          case reason do
            "contact_link_quality_review_required" -> "review_only_link_quality"
            "feedback_weight_invalid_review_required" -> "review_only_invalid_feedback_weight"
            "resource_availability_variance_review_required" -> "review_only_resource_variance"
            _reason -> "review_only_identity_mismatch"
          end

        row
        |> Map.put("operational_feedback_excluded", true)
        |> Map.put("operational_feedback_status", status)
        |> Map.put("operational_feedback_exclusion_reason", reason)
    end
  end

  defp operational_feedback_exclusion_reason(%{} = row) do
    cond do
      invalid_feedback_weight_section?(row) ->
        "feedback_weight_invalid_review_required"

      resource_availability_variance?(row) ->
        "resource_availability_variance_review_required"

      true ->
        operational_feedback_exclusion_reason_for_kind(row)
    end
  end

  defp resource_availability_variance?(row) do
    [
      "spacecraft_available_match_status",
      "payload_available_match_status",
      "antenna_available_match_status",
      "degraded_match_status",
      "mode_match_status"
    ]
    |> Enum.any?(&(row[&1] == "mismatch"))
  end

  defp operational_feedback_exclusion_reason_for_kind(%{"feedback_kind" => kind} = row)
       when kind in ["contact", "command", "health_check"] do
    operational_feedback_contact_exclusion_reason(row)
  end

  defp operational_feedback_exclusion_reason_for_kind(%{"feedback_kind" => "observation"} = row) do
    if row["target_match_status"] == "mismatch" or
         row["pointing_target_match_status"] == "mismatch" do
      "target_identity_mismatch_review_required"
    end
  end

  defp operational_feedback_exclusion_reason_for_kind(_row), do: nil

  defp invalid_feedback_weight_section?(row) do
    row
    |> Map.get("invalid_realized_feedback_sections")
    |> list_value()
    |> Enum.any?(
      &(&1["field"] in [
          "feedback_weight",
          "feedback_sample_weight",
          "sample_weight",
          "confidence_weight"
        ])
    )
  end

  defp list_value(value) when is_list(value), do: value
  defp list_value(_value), do: []

  defp operational_feedback_contact_exclusion_reason(row) do
    if Enum.any?(
         [
           row["direction_match_status"],
           row["ground_station_match_status"],
           row["source_window_match_status"],
           row["link_protocol_match_status"],
           row["frequency_band_match_status"],
           row["modulation_match_status"],
           row["coding_scheme_match_status"],
           row["polarization_match_status"]
         ],
         &(&1 == "mismatch")
       ) do
      "contact_identity_mismatch_review_required"
    else
      if contact_link_quality_review_required?(row) do
        "contact_link_quality_review_required"
      end
    end
  end

  defp contact_link_quality_review_required?(row) do
    row["realized_carrier_lock"] == false or
      row["realized_symbol_lock"] == false or
      negative_number?(row["realized_link_margin_db"]) or
      link_quality_failure_status?(row["realized_link_quality_status"])
  end

  defp link_quality_failure_status?(status) when is_binary(status) do
    status
    |> normalize_status()
    |> then(
      &(&1 in [
          "below_threshold",
          "degraded",
          "failed",
          "link_failed",
          "lock_lost",
          "low_margin",
          "no_lock",
          "poor",
          "unusable"
        ])
    )
  end

  defp link_quality_failure_status?(_status), do: false

  defp negative_number?(value), do: is_number(value) and value < 0.0

  defp normalize_status(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_status(status) when is_atom(status),
    do: status |> Atom.to_string() |> normalize_status()

  defp normalize_status(_status), do: nil

  defp put_duplicate_realized_feedback(row, realized_matches) when length(realized_matches) > 1 do
    row
    |> Map.put("realized_match_count", length(realized_matches))
    |> Map.put("realized_activity_ids", Enum.map(realized_matches, & &1["realized_activity_id"]))
    |> Map.put("realized_statuses", Enum.map(realized_matches, & &1["status"]))
    |> Map.put("realized_match_strategies", Enum.map(realized_matches, & &1["match_strategy"]))
    |> Map.put("realized_activities", Enum.map(realized_matches, & &1["source_activity"]))
  end

  defp put_duplicate_realized_feedback(row, _realized_matches), do: row

  defp row_status(nil, %{}), do: "realized_only"
  defp row_status(%{}, nil), do: "planned_only"
  defp row_status(%{}, %{}), do: "matched"

  defp feedback_status_transition(nil, nil), do: nil

  defp feedback_status_transition(planned, realized) do
    Timeline.status_transition(
      value(planned, "source_activity"),
      realized_source_activity_for_transition(realized)
    )
  end

  defp realized_source_activity_for_transition(nil), do: nil

  defp realized_source_activity_for_transition(%{} = realized) do
    case value(realized, "source_activity") do
      %{} = source_activity -> Map.put(source_activity, "status", value(realized, "status"))
      source_activity -> source_activity
    end
  end

  defp feedback_protection_decision(nil, _realized), do: nil

  defp feedback_protection_decision(%{"invalid_activity_input" => true}, _realized), do: nil

  defp feedback_protection_decision(planned, realized) do
    opts =
      case value(realized, "status") do
        nil -> []
        status -> [realized_status: status]
      end

    planned
    |> value("source_activity")
    |> Timeline.protection_decision(opts)
  end

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

  defp operational_feedback_excluded?(%{"operational_feedback_excluded" => true}), do: true
  defp operational_feedback_excluded?(%{} = row), do: invalid_operational_feedback_identity?(row)
  defp operational_feedback_excluded?(_row), do: false

  defp invalid_operational_feedback_identity?(row) do
    ["activity_id", "ground_station_id", "target_id", "spacecraft_id", "resource_id"]
    |> Enum.any?(fn field ->
      case Map.get(row, field) do
        value when value in [nil, ""] -> false
        value -> is_nil(stable_scalar_identifier(value))
      end
    end)
  end

  defp feedback_average_by(rows, key_fun, value_fun) do
    rows
    |> Enum.reject(&operational_feedback_excluded?/1)
    |> Enum.reduce(%{}, fn row, grouped ->
      key = stable_scalar_identifier(key_fun.(row))
      value = value_fun.(row)
      weight = feedback_average_weight(row)

      if is_binary(key) and key != "" and is_number(value) and is_number(weight) and
           weight > 0.0 do
        Map.update(grouped, key, [{value, weight}], &[{value, weight} | &1])
      else
        grouped
      end
    end)
    |> Enum.map(fn {key, weighted_values} ->
      average =
        weighted_average(weighted_values)
        |> clamp_unit_interval()

      {key, average}
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new()
  end

  defp feedback_text_by(rows, key_fun, value_fun) do
    rows
    |> Enum.reject(&operational_feedback_excluded?/1)
    |> Enum.reduce(%{}, fn row, grouped ->
      key = stable_scalar_identifier(key_fun.(row))
      value = value_fun.(row)

      if is_binary(key) and key != "" and is_binary(value) and value != "" do
        Map.update(grouped, key, [value], &[value | &1])
      else
        grouped
      end
    end)
    |> Enum.map(fn {key, values} ->
      value =
        values
        |> Enum.uniq()
        |> Enum.sort()
        |> List.first()

      {key, value}
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new()
  end

  defp downlink_demand_feedback(rows) do
    rows
    |> Enum.reject(&operational_feedback_excluded?/1)
    |> Enum.reduce(%{}, fn row, demands ->
      case downlink_demand_feedback_entry(row) do
        {key, demand_mb} when is_binary(key) and is_number(demand_mb) and demand_mb > 0.0 ->
          weight = feedback_average_weight(row)
          weighted_demand_mb = demand_mb * weight

          if weight > 0.0 and weighted_demand_mb > 0.0 do
            Map.update(demands, key, weighted_demand_mb, &(&1 + weighted_demand_mb))
          else
            demands
          end

        _entry ->
          demands
      end
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new()
  end

  defp downlink_demand_feedback_entry(%{"feedback_kind" => "observation"} = row) do
    actual_data_volume_mb = numeric_value(row["actual_data_volume_mb"])
    planned_data_volume_mb = numeric_value(row["planned_data_volume_mb"])
    completed_fraction = unit_interval_number_or_nil(row["completed_fraction"])

    cond do
      is_number(actual_data_volume_mb) ->
        {"default", max(actual_data_volume_mb, 0.0)}

      is_number(planned_data_volume_mb) and is_number(completed_fraction) ->
        {"default", planned_data_volume_mb * completed_fraction}

      true ->
        nil
    end
  end

  defp downlink_demand_feedback_entry(%{"feedback_kind" => "contact"} = row) do
    station_key = downlink_demand_station_key(row)

    case contact_downlink_demand_mb(row) do
      demand_mb when is_binary(station_key) and is_number(demand_mb) and demand_mb > 0.0 ->
        {station_key, demand_mb}

      _demand ->
        nil
    end
  end

  defp downlink_demand_feedback_entry(_row), do: nil

  defp downlink_demand_feedback_trust_key(row) do
    case downlink_demand_feedback_entry(row) do
      {key, demand_mb} when is_binary(key) and is_number(demand_mb) and demand_mb > 0.0 ->
        key

      _entry ->
        nil
    end
  end

  defp downlink_demand_feedback_trust_value(row) do
    if operational_feedback_excluded?(row) do
      nil
    else
      case downlink_demand_feedback_entry(row) do
        {_key, demand_mb} when is_number(demand_mb) and demand_mb > 0.0 ->
          weight = feedback_average_weight(row)

          if weight > 0.0 and demand_mb * weight > 0.0 do
            demand_mb * weight
          end

        _entry ->
          nil
      end
    end
  end

  defp downlink_demand_sources_feedback_trust_value(row) do
    case downlink_demand_feedback_trust_value(row) do
      value when is_number(value) ->
        case downlink_demand_feedback_sources(row) do
          [] -> nil
          sources -> sources
        end

      _value ->
        nil
    end
  end

  defp downlink_demand_station_key(row) do
    case Map.get(row, "ground_station_id") do
      value when value in [nil, ""] -> "default"
      value -> stable_scalar_identifier(value)
    end
  end

  defp downlink_demand_sources_feedback(rows) do
    rows
    |> Enum.reject(&operational_feedback_excluded?/1)
    |> Enum.reduce(%{}, fn row, sources ->
      case downlink_demand_feedback_entry(row) do
        {key, demand_mb} when is_binary(key) and is_number(demand_mb) and demand_mb > 0.0 ->
          weight = feedback_average_weight(row)
          weighted_demand_mb = demand_mb * weight
          row_sources = downlink_demand_feedback_sources(row)

          if weight > 0.0 and weighted_demand_mb > 0.0 and row_sources != [] do
            Map.update(sources, key, row_sources, fn existing ->
              existing
              |> Kernel.++(row_sources)
              |> Enum.uniq()
              |> Enum.sort()
            end)
          else
            sources
          end

        _entry ->
          sources
      end
    end)
    |> Enum.sort_by(fn {key, _sources} -> key end)
    |> Map.new()
  end

  defp downlink_demand_feedback_sources(row) do
    row
    |> downlink_demand_feedback_source_values()
    |> Enum.map(&stringify_scalar/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp downlink_demand_feedback_source_values(%{"feedback_kind" => "contact"} = row) do
    [
      timeline_feedback_demand_source(
        "timeline_feedback.contact.required_downlink_mb",
        row["activity_id"] || row["id"]
      ),
      row["realized_activity_id"] &&
        timeline_feedback_demand_source(
          "timeline_feedback.realized_activity",
          row["realized_activity_id"]
        )
    ]
  end

  defp downlink_demand_feedback_source_values(%{"feedback_kind" => "observation"} = row) do
    [
      timeline_feedback_demand_source(
        "timeline_feedback.observation.data_volume",
        row["activity_id"] || row["id"]
      ),
      row["realized_activity_id"] &&
        timeline_feedback_demand_source(
          "timeline_feedback.realized_activity",
          row["realized_activity_id"]
        )
    ]
  end

  defp downlink_demand_feedback_source_values(row) do
    [timeline_feedback_demand_source("timeline_feedback.row", row["id"])]
  end

  defp timeline_feedback_demand_source(_prefix, id) when id in [nil, ""], do: nil

  defp timeline_feedback_demand_source(prefix, id) do
    "#{prefix}:#{id}"
  end

  defp contact_downlink_demand_mb(%{"required_downlink_mb" => raw_required_downlink_mb} = row) do
    case numeric_value(raw_required_downlink_mb) do
      required_downlink_mb when is_number(required_downlink_mb) and required_downlink_mb > 0.0 ->
        actual_throughput_mb = actual_throughput_mb(row)
        completed_fraction = unit_interval_number_or_nil(row["completed_fraction"])

        cond do
          is_number(actual_throughput_mb) ->
            max(required_downlink_mb - actual_throughput_mb, 0.0)

          is_number(completed_fraction) ->
            required_downlink_mb * (1.0 - completed_fraction)

          row["realized_status"] in [
            "missed",
            "failed",
            "delayed",
            "partial",
            "canceled",
            "cancelled",
            "rejected"
          ] ->
            required_downlink_mb

          row["contact_success"] == false ->
            required_downlink_mb

          true ->
            nil
        end

      _required_downlink_mb ->
        nil
    end
  end

  defp contact_downlink_demand_mb(_row), do: nil

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

  defp resource_margin_feedback(rows) do
    rows
    |> Enum.reject(&operational_feedback_excluded?/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      spacecraft_id = resource_feedback_spacecraft_id(row)
      margins = resource_margin_values(row)

      if spacecraft_id in [nil, ""] or margins == %{} do
        feedback
      else
        Map.update(feedback, spacecraft_id, margins, &merge_resource_margin_feedback(&1, margins))
      end
    end)
    |> sort_nested_feedback_map()
  end

  defp resource_margin_values(row) do
    %{
      "fuel_margin" => first_feedback_resource_number(row, ["fuel_margin"]),
      "power_margin" => first_feedback_resource_number(row, ["power_margin"]),
      "storage_margin" => first_feedback_resource_number(row, ["storage_margin"]),
      "downlink_margin" =>
        first_feedback_resource_number(row, ["downlink_margin", "downlink_capacity_margin"]),
      "thermal_margin_c" => first_feedback_resource_number(row, ["thermal_margin_c"]),
      "battery_capacity_wh" => first_feedback_resource_number(row, ["battery_capacity_wh"]),
      "battery_energy_used_wh" => first_feedback_resource_number(row, ["battery_energy_used_wh"]),
      "battery_energy_generated_wh" =>
        first_feedback_resource_number(row, ["battery_energy_generated_wh"]),
      "battery_state_of_charge" =>
        first_feedback_resource_number(row, ["battery_state_of_charge"])
    }
    |> Enum.reject(fn {_field, value} -> not is_number(value) end)
    |> Map.new(fn {field, value} -> {field, value * 1.0} end)
  end

  defp resource_margin_feedback_trust_value(row) do
    if operational_feedback_excluded?(row) do
      nil
    else
      case resource_margin_values(row) do
        values when map_size(values) > 0 -> values
        _values -> nil
      end
    end
  end

  defp merge_resource_margin_feedback(existing, incoming) do
    Map.merge(existing, incoming, fn field, current, candidate ->
      merge_resource_margin_value(field, current, candidate)
    end)
  end

  defp merge_resource_margin_value(field, current, candidate)
       when field in ["battery_energy_used_wh", "battery_energy_generated_wh"],
       do: max(current, candidate)

  defp merge_resource_margin_value(_field, current, candidate), do: min(current, candidate)

  defp resource_availability_feedback(rows) do
    rows
    |> Enum.reject(&operational_feedback_excluded?/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      spacecraft_id = resource_feedback_spacecraft_id(row)
      availability = resource_availability_values(row)

      if spacecraft_id in [nil, ""] or availability == %{} do
        feedback
      else
        Map.update(
          feedback,
          spacecraft_id,
          availability,
          &merge_resource_availability_feedback(&1, availability)
        )
      end
    end)
    |> sort_nested_feedback_map()
  end

  defp resource_availability_feedback_trust_value(row) do
    if operational_feedback_excluded?(row) do
      nil
    else
      case resource_availability_values(row) do
        values when map_size(values) > 0 -> values
        _values -> nil
      end
    end
  end

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

  defp resource_availability_values(row) do
    %{
      "payload_available" =>
        first_feedback_resource_boolean(row, ["payload_available", "payload_available?"]),
      "antenna_available" =>
        first_feedback_resource_boolean(row, ["antenna_available", "antenna_available?"]),
      "degraded" => first_feedback_resource_boolean(row, ["degraded", "degraded?"]),
      "spacecraft_available" => first_feedback_resource_boolean(row, ["spacecraft_available"]),
      "spacecraft_availability" =>
        first_feedback_resource_boolean(row, ["spacecraft_availability"]),
      "mode" => first_feedback_resource_value(row, ["mode"]),
      "incompatible_activity_types" =>
        first_feedback_resource_value(row, ["incompatible_activity_types"]),
      "suppressed_activity_types" =>
        first_feedback_resource_value(row, ["suppressed_activity_types"])
    }
    |> Enum.reject(fn
      {_field, nil} -> true
      {_field, ""} -> true
      {_field, []} -> true
      {_field, _value} -> false
    end)
    |> Map.new()
  end

  defp merge_resource_availability_feedback(existing, incoming) do
    Map.merge(existing, incoming, fn
      field, current, candidate when field in ["payload_available", "antenna_available"] ->
        current != false and candidate != false

      field, current, candidate
      when field in ["spacecraft_available", "spacecraft_availability"] ->
        current != false and candidate != false

      "degraded", current, candidate ->
        truthy?(current) or truthy?(candidate)

      field, current, candidate
      when field in ["incompatible_activity_types", "suppressed_activity_types"] ->
        merge_string_lists(current, candidate)

      "mode", current, candidate ->
        degraded_mode_preference(current, candidate)

      _field, _current, candidate ->
        candidate
    end)
  end

  defp resource_feedback_spacecraft_id(row) do
    [
      row,
      Map.get(row, "realized_activity_context", %{}),
      Map.get(row, "realized_activity", %{})
    ]
    |> Enum.find_value(fn source ->
      [
        Map.get(source, "spacecraft_id"),
        Map.get(source, "scenario_id"),
        Map.get(source, "resource_spacecraft_id"),
        get_in(source, ["metadata", "spacecraft_id"]),
        get_in(source, ["provenance", "spacecraft_id"])
      ]
      |> Enum.find_value(&stable_scalar_identifier/1)
    end)
  end

  defp first_feedback_resource_number(row, fields) do
    case first_feedback_resource_value(row, fields) do
      value -> numeric_value(value)
    end
  end

  defp feedback_number(value) do
    unit_interval_number_or_nil(value)
  end

  defp first_feedback_resource_boolean(row, fields) do
    case first_feedback_resource_value(row, fields) |> boolean_value() do
      value when is_boolean(value) -> value
      nil -> nil
    end
  end

  defp first_feedback_resource_value(row, fields) do
    sources = [
      row,
      Map.get(row, "realized_activity_context", %{}),
      Map.get(row, "realized_activity", %{})
    ]

    Enum.reduce_while(sources, nil, fn source, _value ->
      case first_feedback_resource_source_value(source, fields) do
        {:ok, value} -> {:halt, value}
        :error -> {:cont, nil}
      end
    end)
  end

  defp first_feedback_resource_source_value(source, fields) do
    Enum.reduce_while(fields, :error, fn field, _value ->
      case feedback_resource_value(source, field) do
        nil -> {:cont, :error}
        value -> {:halt, {:ok, value}}
      end
    end)
  end

  defp feedback_resource_value(%{} = source, field) when is_list(field), do: get_in(source, field)
  defp feedback_resource_value(%{} = source, field), do: Map.get(source, field)
  defp feedback_resource_value(_source, _field), do: nil

  defp stable_scalar_identifier(value) do
    value
    |> stringify_scalar()
    |> stable_identifier()
  end

  defp merge_string_lists(current, candidate) do
    [current, candidate]
    |> List.flatten()
    |> Enum.map(&stringify_scalar/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp degraded_mode_preference(current, candidate) do
    Enum.find(
      [current, candidate],
      &(stringify_scalar(&1) in ["safe", "degraded", "degraded_mode"])
    ) ||
      candidate ||
      current
  end

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
    realized_context_feedback_number(row, "contact_success_factor") ||
      boolean_success_value(row["contact_success"]) ||
      first_feedback_number(row, ["contact_success_factor"]) ||
      station_throughput_feedback_value(row) ||
      status_success_value(row)
  end

  defp contact_success_feedback_value(_row), do: nil

  defp station_throughput_feedback_value(%{"feedback_kind" => "contact"} = row) do
    feedback_number(row["throughput_completion_fraction"]) ||
      derived_throughput_completion_fraction(row)
  end

  defp station_throughput_feedback_value(_row), do: nil

  defp observation_success_feedback_value(%{"feedback_kind" => "observation"} = row) do
    realized_context_feedback_number(row, "observation_success_factor") ||
      provider_result_feedback_value(row["observation_result"], row) ||
      first_feedback_number(row, ["observation_success_factor"]) ||
      realized_context_feedback_number(row, "image_quality_score") ||
      first_feedback_number(row, ["realized_image_quality_score"]) ||
      boolean_success_value(row["observation_success"]) ||
      status_success_value(row)
  end

  defp observation_success_feedback_value(_row), do: nil

  defp image_quality_score_feedback_value(%{"feedback_kind" => "observation"} = row) do
    realized_context_feedback_number(row, "image_quality_score") ||
      first_feedback_number(row, ["realized_image_quality_score", "image_quality_score"])
  end

  defp image_quality_score_feedback_value(_row), do: nil

  defp cloud_cover_feedback_value(%{"feedback_kind" => "observation"} = row) do
    realized_context_feedback_number(row, "cloud_cover_fraction") ||
      first_feedback_number(row, ["realized_cloud_cover_fraction", "cloud_cover_fraction"])
  end

  defp cloud_cover_feedback_value(_row), do: nil

  defp blur_score_feedback_value(%{"feedback_kind" => "observation"} = row) do
    realized_context_feedback_number(row, "blur_score") ||
      first_feedback_number(row, ["realized_blur_score", "blur_score"])
  end

  defp blur_score_feedback_value(_row), do: nil

  defp image_quality_status_feedback_value(%{"feedback_kind" => "observation"} = row) do
    first_feedback_string(row, [
      ["realized_activity_context", "image_quality_status"],
      "realized_image_quality_status",
      "image_quality_status"
    ])
  end

  defp image_quality_status_feedback_value(_row), do: nil

  defp image_quality_source_feedback_value(%{"feedback_kind" => "observation"} = row) do
    first_feedback_string(row, [
      ["realized_activity_context", "image_quality_source"],
      "image_quality_source"
    ])
  end

  defp image_quality_source_feedback_value(_row), do: nil

  defp maneuver_success_feedback_value(%{"feedback_kind" => "maneuver"} = row) do
    realized_context_feedback_number(row, "maneuver_success_factor") ||
      boolean_success_value(row["maneuver_success"]) ||
      first_feedback_number(row, ["maneuver_success_factor"]) ||
      status_success_value(row)
  end

  defp maneuver_success_feedback_value(_row), do: nil

  defp command_success_feedback_value(%{"feedback_kind" => kind} = row)
       when kind in ["command", "health_check"] do
    realized_context_feedback_number(row, "command_success_factor") ||
      boolean_success_value(row["command_success"]) ||
      first_feedback_number(row, ["command_success_factor"]) ||
      status_success_value(row)
  end

  defp command_success_feedback_value(_row), do: nil

  defp first_feedback_number(row, fields) do
    Enum.find_value(fields, fn field ->
      feedback_number(row[field])
    end)
  end

  defp first_feedback_string(row, fields) do
    Enum.find_value(fields, fn field ->
      value =
        case field do
          path when is_list(path) -> get_in(row, path)
          field -> Map.get(row, field)
        end

      case stringify_scalar(value) do
        value when is_binary(value) and value != "" -> value
        _value -> nil
      end
    end)
  end

  defp realized_context_feedback_number(row, field) do
    feedback_number(get_in(row, ["realized_activity_context", field]))
  end

  defp boolean_success_value(true), do: 1.0
  defp boolean_success_value(false), do: 0.0
  defp boolean_success_value(_value), do: nil

  defp status_success_value(%{"realized_status" => status} = row)
       when status in @realized_completion_statuses do
    completed_fraction_success_value(row, 1.0)
  end

  defp status_success_value(%{"realized_status" => "partial"} = row),
    do: completed_fraction_success_value(row, 0.5)

  defp status_success_value(%{"realized_status" => "delayed"}), do: 0.5

  defp status_success_value(%{"realized_status" => status})
       when status in @realized_failure_statuses,
       do: 0.0

  defp status_success_value(_row), do: nil

  defp completed_fraction_success_value(row, default) do
    case unit_interval_number_or_nil(row["completed_fraction"]) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp clamp_unit_interval(value) when is_number(value) do
    value
    |> max(0.0)
    |> min(1.0)
  end

  defp weighted_average(weighted_values) do
    {weighted_sum, total_weight} =
      Enum.reduce(weighted_values, {0.0, 0.0}, fn {value, weight}, {sum, total} ->
        {sum + value * weight, total + weight}
      end)

    weighted_sum / total_weight
  end

  defp feedback_average_weight(%{"feedback_weight" => weight}) do
    case numeric_value(weight) do
      weight when is_number(weight) and weight >= 0.0 -> weight * 1.0
      _weight -> 1.0
    end
  end

  defp feedback_average_weight(_row), do: 1.0

  defp feedback_weight(planned, realized) do
    Enum.find_value([value(realized, "feedback_weight"), value(planned, "feedback_weight")], fn
      weight when is_number(weight) and weight >= 0.0 -> weight * 1.0
      _weight -> nil
    end)
  end

  defp feedback_weight_source(planned, realized) do
    value(realized, "feedback_weight_source") || value(planned, "feedback_weight_source")
  end

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

  defp feedback_source_activity_context(nil), do: nil

  defp feedback_source_activity_context(planned) do
    (value(planned, "source_activity_context") || %{})
    |> Map.merge(%{
      "command_authority_status" => value(planned, "command_authority_status"),
      "required_authority" => value(planned, "required_authority"),
      "command_safety_status" => value(planned, "command_safety_status"),
      "command_authorized" => value(planned, "command_authorized"),
      "command_safety_checked" => value(planned, "command_safety_checked")
    })
    |> compact_map()
  end

  defp source_activity_value(%{} = source_activity, primary_key, fallback_key) do
    Map.get(source_activity, primary_key) || Map.get(source_activity, fallback_key)
  end

  defp source_activity_value(_source_activity, _primary_key, _fallback_key), do: nil

  defp delta(actual, planned) when is_number(actual) and is_number(planned), do: actual - planned
  defp delta(_actual, _planned), do: nil

  defp max_abs_timing_delta_s(start_delta_s, end_delta_s) do
    [start_delta_s, end_delta_s]
    |> Enum.filter(&is_number/1)
    |> Enum.map(&abs/1)
    |> Enum.max(fn -> nil end)
  end

  defp timing_variance_status(max_timing_delta_s, threshold)
       when is_number(max_timing_delta_s) and is_number(threshold) do
    if max_timing_delta_s > threshold, do: "exceeds_threshold", else: "within_threshold"
  end

  defp timing_variance_status(_max_timing_delta_s, _threshold), do: nil

  defp throughput_fraction(actual, planned)
       when is_number(actual) and is_number(planned) and planned > 0.0 do
    actual / planned
  end

  defp throughput_fraction(_actual, _planned), do: nil

  defp match_status(planned, realized)
       when planned in [nil, "", []] and realized in [nil, "", []],
       do: nil

  defp match_status(planned, _realized) when planned in [nil, "", []], do: "realized_only"

  defp match_status(_planned, realized) when realized in [nil, "", []], do: "planned_only"

  defp match_status(value, value), do: "matched"
  defp match_status(_planned, _realized), do: "mismatch"

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

  defp contact_success("contact", _status, explicit, _result) when is_boolean(explicit),
    do: explicit

  defp contact_success("contact", status, explicit, result) when not is_nil(result) do
    case provider_result_outcome(result) do
      :failure -> false
      :success -> true
      :unknown -> contact_success("contact", status, explicit, nil)
    end
  end

  defp contact_success("contact", status, _explicit, _result)
       when status in ["completed", "executed"],
       do: true

  defp contact_success("contact", "partial", _explicit, _result), do: nil

  defp contact_success("contact", status, _explicit, _result) when is_binary(status), do: false
  defp contact_success(_feedback_kind, _status, _explicit, _result), do: nil

  defp command_success(kind, _status, explicit, _result)
       when kind in ["command", "health_check"] and is_boolean(explicit),
       do: explicit

  defp command_success(kind, status, explicit, result)
       when kind in ["command", "health_check"] and not is_nil(result) do
    case command_result_outcome(result) do
      :failure -> false
      :success -> true
      :unknown -> command_success(kind, status, explicit, nil)
    end
  end

  defp command_success(kind, status, _explicit, _result)
       when kind in ["command", "health_check"] and status in ["completed", "executed"],
       do: true

  defp command_success(kind, "partial", _explicit, _result)
       when kind in ["command", "health_check"],
       do: nil

  defp command_success(kind, status, _explicit, _result)
       when kind in ["command", "health_check"] and is_binary(status), do: false

  defp command_success(_feedback_kind, _status, _explicit, _result), do: nil

  defp observation_success("observation", _status, explicit, _result) when is_boolean(explicit),
    do: explicit

  defp observation_success("observation", status, explicit, result) when not is_nil(result) do
    case provider_result_outcome(result) do
      :failure -> false
      :success -> true
      :unknown -> observation_success("observation", status, explicit, nil)
    end
  end

  defp observation_success("observation", status, _explicit, _result)
       when status in ["completed", "executed"],
       do: true

  defp observation_success("observation", "partial", _explicit, _result), do: nil

  defp observation_success("observation", status, _explicit, _result)
       when status in @realized_failure_statuses,
       do: false

  defp observation_success(_feedback_kind, _status, _explicit, _result), do: nil

  defp maneuver_success("maneuver", _status, explicit, _result) when is_boolean(explicit),
    do: explicit

  defp maneuver_success("maneuver", status, explicit, result) when not is_nil(result) do
    case provider_result_outcome(result) do
      :failure -> false
      :success -> true
      :unknown -> maneuver_success("maneuver", status, explicit, nil)
    end
  end

  defp maneuver_success("maneuver", status, _explicit, _result)
       when status in ["completed", "executed"],
       do: true

  defp maneuver_success("maneuver", status, _explicit, _result)
       when status in @realized_failure_statuses,
       do: false

  defp maneuver_success(_feedback_kind, _status, _explicit, _result), do: nil

  defp command_result_outcome(result) do
    provider_result_outcome(result)
  end

  defp provider_result_outcome(result) do
    outcomes =
      result
      |> provider_result_values()
      |> Enum.map(&provider_result_token_outcome/1)
      |> Enum.reject(&(&1 == :unknown))

    cond do
      Enum.member?(outcomes, :failure) -> :failure
      Enum.member?(outcomes, :success) -> :success
      true -> :unknown
    end
  end

  defp provider_result_feedback_value(result, row) when not is_nil(result) do
    case provider_result_outcome(result) do
      :failure -> 0.0
      :success -> completed_fraction_success_value(row, 1.0)
      :unknown -> nil
    end
  end

  defp provider_result_feedback_value(_result, _row), do: nil

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp provider_result_token_outcome(result) when is_binary(result) do
    case provider_result_token(result) do
      value
      when value in [
             "rejected",
             "failed",
             "failure",
             "timeout",
             "timed_out",
             "aborted",
             "error",
             "dropped",
             "lost",
             "missed",
             "canceled",
             "cancelled",
             "no_contact"
           ] ->
        :failure

      value
      when value in [
             "accepted",
             "acknowledged",
             "completed",
             "executed",
             "succeeded",
             "success",
             "ok",
             "acquired",
             "established",
             "delivered"
           ] ->
        :success

      _value ->
        :unknown
    end
  end

  defp provider_result_token(result) when is_binary(result) do
    result
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp identifier(map, key) do
    case Map.get(map, key) do
      nil -> nil
      value when is_binary(value) and value != "" -> if(stable_id?(value), do: value)
      value when is_atom(value) -> value |> Atom.to_string() |> stable_identifier()
      _value -> nil
    end
  end

  defp realized_input_identity(activity) do
    Enum.find_value(
      ["id", "realized_activity_id", "planned_activity_id", "activity_id", "timeline_id"],
      &identifier(activity, &1)
    )
  end

  defp realized_input_identity_issue(activity) do
    raw_identities =
      ["id", "realized_activity_id", "planned_activity_id", "activity_id", "timeline_id"]
      |> Enum.map(&raw_identifier(activity, &1))
      |> Kernel.++([get_in(activity, ["metadata", "timeline_id"])])
      |> Kernel.++(raw_realized_context_identifiers(activity))
      |> Enum.reject(&is_nil/1)

    cond do
      Enum.any?(raw_identities, &(not stable_id?(&1))) -> "invalid_realized_feedback_id"
      realized_input_identity(activity) in [nil, ""] -> "missing_realized_feedback_id"
      true -> nil
    end
  end

  defp raw_identifier(activity, key) do
    case Map.get(activity, key) do
      nil -> nil
      value when is_binary(value) and value != "" -> value
      value when is_atom(value) -> Atom.to_string(value)
      _value -> nil
    end
  end

  defp raw_realized_context_identifiers(activity) do
    [
      raw_identifier(activity, "ground_station_id"),
      raw_identifier(activity, "station_id"),
      raw_identifier(activity, "target_id"),
      raw_identifier(activity, "spacecraft_id"),
      raw_identifier(activity, "satellite_id"),
      raw_identifier(activity, "resource_id"),
      raw_identifier(activity, "source_window_id"),
      raw_identifier(activity, "scenario_id"),
      raw_value_identifier(get_in(activity, ["metadata", "ground_station_id"])),
      raw_value_identifier(get_in(activity, ["metadata", "station_id"])),
      raw_value_identifier(get_in(activity, ["metadata", "target_id"])),
      raw_value_identifier(get_in(activity, ["metadata", "spacecraft_id"])),
      raw_value_identifier(get_in(activity, ["metadata", "source_window_id"])),
      raw_nested_identifier(activity, "target", ["target_id", "id"]),
      raw_nested_identifier(activity, "ground_station", ["ground_station_id", "station_id", "id"]),
      raw_nested_identifier(activity, "station", ["station_id", "id"]),
      raw_nested_identifier(activity, "spacecraft", ["spacecraft_id", "id"]),
      raw_nested_identifier(activity, "satellite", ["satellite_id", "id"]),
      raw_nested_identifier(activity, "source_window", ["source_window_id", "id"])
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp raw_nested_identifier(activity, object_key, identity_keys) do
    case Map.get(activity, object_key) do
      %{} = object -> Enum.find_value(identity_keys, &raw_identifier(object, &1))
      _value -> nil
    end
  end

  defp raw_value_identifier(value) when is_binary(value) and value != "", do: value
  defp raw_value_identifier(value) when is_atom(value), do: Atom.to_string(value)
  defp raw_value_identifier(_value), do: nil

  defp realized_status_supported?(activity),
    do: realized_status(activity) in @realized_terminal_statuses

  defp realized_status(%{"status" => status, "realized_status" => realized_status}) do
    status = normalize_realized_status_value(status)
    realized_status = normalize_realized_status_value(realized_status)

    if status in @realized_feedback_match_statuses do
      realized_status
    else
      status
    end
  end

  defp realized_status(%{"status" => status, "lifecycle_event" => lifecycle_event}) do
    status = normalize_realized_status_value(status)
    lifecycle_status = lifecycle_event_realized_status(lifecycle_event)

    if status in @realized_feedback_match_statuses do
      lifecycle_status
    else
      status
    end
  end

  defp realized_status(%{"status" => status}), do: normalize_realized_status_value(status)

  defp realized_status(%{"lifecycle_event" => lifecycle_event}),
    do: lifecycle_event_realized_status(lifecycle_event)

  defp realized_status(_activity), do: nil

  defp realized_feedback_status(%{"status" => status, "realized_status" => realized_status}) do
    status = normalize_realized_status_value(status)
    realized_status = normalize_realized_status_value(realized_status)

    if status in @realized_feedback_match_statuses and
         realized_status in @realized_terminal_statuses do
      status
    end
  end

  defp realized_feedback_status(%{"status" => status, "lifecycle_event" => lifecycle_event}) do
    status = normalize_realized_status_value(status)
    lifecycle_status = lifecycle_event_realized_status(lifecycle_event)

    if status in @realized_feedback_match_statuses and
         lifecycle_status in @realized_terminal_statuses do
      status
    end
  end

  defp realized_feedback_status(_activity), do: nil

  defp normalize_realized_status_value(status) when is_binary(status),
    do: normalize_realized_status(status)

  defp normalize_realized_status_value(status) when is_atom(status),
    do: status |> Atom.to_string() |> normalize_realized_status()

  defp normalize_realized_status_value(_status), do: nil

  defp normalize_realized_status(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp lifecycle_event_realized_status(event) do
    case normalize_realized_status_value(event) do
      nil -> nil
      event -> Map.get(@lifecycle_event_realized_statuses, event, event)
    end
  end

  defp source_realized_activity_id(source_activity) do
    identifier(source_activity, "id") || identifier(source_activity, "realized_activity_id")
  end

  defp invalid_realized_planned_activity_id(source_activity) do
    identifier(source_activity, "planned_activity_id") ||
      identifier(source_activity, "activity_id") ||
      source_realized_activity_id(source_activity)
  end

  defp invalid_realized_timeline_id(source_activity) do
    identifier(source_activity, "timeline_id") ||
      stable_identifier(get_in(source_activity, ["metadata", "timeline_id"]))
  end

  defp invalid_realized_status_reason(activity) do
    case realized_status(activity) do
      nil -> "missing_realized_status"
      _status -> "unsupported_realized_status"
    end
  end

  defp unsupported_realized_status(source_activity, "unsupported_realized_status"),
    do: realized_status(source_activity)

  defp unsupported_realized_status(_source_activity, _reason), do: nil

  defp realized_id!(activity) do
    realized_input_identity(activity) || raise(ArgumentError, "id is required")
  end

  defp stable_identifier(value) when is_binary(value), do: if(stable_id?(value), do: value)
  defp stable_identifier(_value), do: nil

  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(_value), do: false

  defp first_number(map, keys) do
    Enum.find_value(keys, fn key ->
      value =
        case key do
          path when is_list(path) -> get_in(map, path)
          key -> first_value(map, [key])
        end

      numeric_value(value)
    end)
  end

  defp planned_data_volume_mb(activity) do
    first_number(activity, [
      "planned_data_volume_mb",
      "data_volume_mb",
      "estimated_data_volume_mb",
      "estimated_storage_mb",
      "estimated_downlink_mb"
    ])
  end

  defp actual_data_volume_mb(activity) do
    first_number(activity, [
      "actual_data_volume_mb",
      "actual_storage_mb",
      "actual_downlink_mb",
      "delivered_data_mb",
      "received_data_mb"
    ])
  end

  defp data_rate_mbps(activity) do
    first_number(activity, [
      "data_rate_mbps",
      "downlink_rate_mbps",
      "actual_data_rate_mbps",
      "actual_downlink_rate_mbps",
      ["link", "data_rate_mbps"],
      ["link", "downlink_rate_mbps"],
      ["communications", "data_rate_mbps"],
      ["communications", "downlink_rate_mbps"],
      ["throughput_model", "data_rate_mbps"],
      ["throughput_model", "downlink_rate_mbps"],
      ["throughput_model", "actual_data_rate_mbps"],
      ["throughput_model", "actual_downlink_rate_mbps"],
      ["metadata", "data_rate_mbps"],
      ["metadata", "downlink_rate_mbps"]
    ]) || data_rate_mb_s(activity)
  end

  defp data_rate_mb_s(activity) do
    case first_number(activity, [
           "data_rate_mb_s",
           "downlink_rate_mb_s",
           "actual_data_rate_mb_s",
           "actual_downlink_rate_mb_s",
           ["link", "data_rate_mb_s"],
           ["link", "downlink_rate_mb_s"],
           ["communications", "data_rate_mb_s"],
           ["communications", "downlink_rate_mb_s"],
           ["throughput_model", "data_rate_mb_s"],
           ["throughput_model", "downlink_rate_mb_s"],
           ["throughput_model", "actual_data_rate_mb_s"],
           ["throughput_model", "actual_downlink_rate_mb_s"],
           ["metadata", "data_rate_mb_s"],
           ["metadata", "downlink_rate_mb_s"]
         ]) do
      value when is_number(value) -> value * 8.0
      _value -> nil
    end
  end

  defp actual_throughput_mb(activity) do
    explicit_actual_throughput_mb(activity) || actual_data_rate_derived_throughput_mb(activity)
  end

  defp explicit_actual_throughput_mb(activity) do
    first_number(activity, [
      "actual_throughput_mb",
      "actual_downlink_mb",
      "actual_data_volume_mb",
      "delivered_data_mb",
      "received_data_mb",
      ["throughput_model", "actual_throughput_mb"],
      ["throughput_model", "actual_downlink_mb"],
      ["throughput_model", "actual_data_volume_mb"],
      ["throughput_model", "delivered_data_mb"],
      ["throughput_model", "received_data_mb"]
    ])
  end

  defp actual_data_rate_derived_throughput_mb(activity) do
    case actual_data_rate_throughput_derivation(activity) do
      %{"actual_throughput_mb" => actual_throughput_mb} when is_number(actual_throughput_mb) ->
        actual_throughput_mb

      _derivation ->
        nil
    end
  end

  defp actual_data_rate_throughput_derivation(activity) do
    duration_s = actual_duration_s(activity)

    cond do
      is_number(explicit_actual_throughput_mb(activity)) ->
        nil

      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = actual_data_rate_mb_s(activity) ->
        %{
          "derivation" => "actual_data_rate_times_duration",
          "rate_unit" => "MB/s",
          "actual_data_rate_mb_s" => rate_mb_s,
          "duration_s" => duration_s,
          "actual_throughput_mb" => rate_mb_s * duration_s
        }

      rate_mbps = actual_data_rate_mbps(activity) ->
        rate_mb_s = rate_mbps / 8.0

        %{
          "derivation" => "actual_data_rate_times_duration",
          "rate_unit" => "Mbps",
          "actual_data_rate_mbps" => rate_mbps,
          "actual_data_rate_mb_s" => rate_mb_s,
          "duration_s" => duration_s,
          "actual_throughput_mb" => rate_mb_s * duration_s
        }

      true ->
        nil
    end
  end

  defp actual_data_rate_mb_s(activity) do
    first_number(activity, [
      "actual_data_rate_mb_s",
      "actual_downlink_rate_mb_s",
      "delivered_rate_mb_s",
      "received_rate_mb_s",
      ["throughput_model", "actual_data_rate_mb_s"],
      ["throughput_model", "actual_downlink_rate_mb_s"],
      ["throughput_model", "delivered_rate_mb_s"],
      ["throughput_model", "received_rate_mb_s"]
    ])
  end

  defp actual_data_rate_mbps(activity) do
    first_number(activity, [
      "actual_data_rate_mbps",
      "actual_downlink_rate_mbps",
      "delivered_rate_mbps",
      "received_rate_mbps",
      ["throughput_model", "actual_data_rate_mbps"],
      ["throughput_model", "actual_downlink_rate_mbps"],
      ["throughput_model", "delivered_rate_mbps"],
      ["throughput_model", "received_rate_mbps"]
    ])
  end

  defp actual_duration_s(activity) do
    first_number(activity, [
      "actual_duration_s",
      "actual_contact_duration_s",
      "contact_duration_s",
      "duration_s",
      ["throughput_model", "actual_duration_s"],
      ["throughput_model", "actual_contact_duration_s"],
      ["throughput_model", "contact_duration_s"],
      ["throughput_model", "duration_s"]
    ]) || interval_duration_s(activity)
  end

  defp interval_duration_s(activity) do
    start_s =
      first_number(activity, [
        "actual_starts_at_s",
        "actual_start_s",
        "starts_at_s",
        "start_s"
      ])

    end_s =
      first_number(activity, [
        "actual_ends_at_s",
        "actual_end_s",
        "ends_at_s",
        "end_s"
      ])

    if is_number(start_s) and is_number(end_s) and end_s > start_s do
      end_s - start_s
    end
  end

  defp derived_throughput_completion_fraction(row) do
    actual_throughput_mb = actual_throughput_mb(row)

    denominator =
      first_number(row, [
        "planned_estimated_throughput_mb",
        "estimated_throughput_mb",
        "required_downlink_mb",
        ["throughput_model", "estimated_throughput_mb"],
        ["throughput_model", "required_downlink_mb"]
      ])

    if is_number(actual_throughput_mb) and is_number(denominator) and denominator > 0.0 do
      actual_throughput_mb / denominator
    end
  end

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
    delta_v = maneuver_delta_v(activity)

    %{
      "delta_v_km_s" => delta_v,
      "delta_v_magnitude_km_s" => vector_norm(delta_v)
    }
    |> compact_map()
  end

  defp activity_execution_uncertainty_context(activity) do
    uncertainty = activity_execution_uncertainty(activity)

    cond do
      is_map(uncertainty) ->
        uncertainty
        |> execution_uncertainty_fields()
        |> Map.merge(%{
          "execution_uncertainty_status" => "declared",
          "execution_uncertainty" => uncertainty
        })
        |> compact_map()

      execution_uncertainty_relevant?(activity) ->
        %{"execution_uncertainty_status" => "missing"}

      true ->
        %{}
    end
  end

  defp activity_execution_uncertainty(activity) do
    uncertainty =
      Map.get(activity, "execution_uncertainty") ||
        Map.get(activity, "maneuver_execution_uncertainty") ||
        get_in(activity, ["metadata", "execution_uncertainty"]) ||
        get_in(activity, ["metadata", "maneuver_execution_uncertainty"]) ||
        get_in(activity, ["assumptions", "execution_uncertainty"]) ||
        get_in(activity, ["assumptions", "maneuver_execution_uncertainty"])

    case uncertainty do
      %{} = uncertainty -> normalize_execution_uncertainty(stringify_keys(uncertainty))
      _value -> nil
    end
  end

  defp execution_uncertainty_relevant?(%{"type" => "impulsive_burn"}), do: true
  defp execution_uncertainty_relevant?(_activity), do: false

  defp normalize_execution_uncertainty(%{} = uncertainty) do
    uncertainty
    |> normalize_uncertainty_number("timing_3sigma_s")
    |> normalize_uncertainty_triplet("delta_v_3sigma_km_s")
    |> normalize_uncertainty_number("delta_v_3sigma_magnitude_km_s")
  end

  defp normalize_uncertainty_number(%{} = uncertainty, key) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_value(value) do
          nil -> uncertainty
          number -> Map.put(uncertainty, key, number)
        end

      :error ->
        uncertainty
    end
  end

  defp normalize_uncertainty_triplet(%{} = uncertainty, key) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_triplet(value) do
          nil -> uncertainty
          triplet -> Map.put(uncertainty, key, triplet)
        end

      :error ->
        uncertainty
    end
  end

  defp execution_uncertainty_fields(uncertainty) do
    delta_v_3sigma_km_s = numeric_triplet(Map.get(uncertainty, "delta_v_3sigma_km_s"))

    %{
      "timing_3sigma_s" => numeric_value(Map.get(uncertainty, "timing_3sigma_s")),
      "delta_v_3sigma_km_s" => delta_v_3sigma_km_s,
      "delta_v_3sigma_magnitude_km_s" => vector_norm(delta_v_3sigma_km_s),
      "execution_uncertainty_source" =>
        Map.get(uncertainty, "source") || Map.get(uncertainty, "model")
    }
    |> compact_map()
  end

  defp execution_uncertainty_reconciliation_context(planned, realized) do
    planned_context = execution_uncertainty_row_context(planned)
    realized_context = execution_uncertainty_row_context(realized)

    cond do
      declared_execution_uncertainty?(realized_context) -> realized_context
      declared_execution_uncertainty?(planned_context) -> planned_context
      missing_execution_uncertainty?(realized_context) -> realized_context
      missing_execution_uncertainty?(planned_context) -> planned_context
      true -> %{}
    end
  end

  defp execution_uncertainty_row_context(nil), do: %{}

  defp execution_uncertainty_row_context(row) do
    %{
      "execution_uncertainty_status" => value(row, "execution_uncertainty_status"),
      "execution_uncertainty" => value(row, "execution_uncertainty"),
      "timing_3sigma_s" => value(row, "timing_3sigma_s"),
      "delta_v_3sigma_km_s" => value(row, "delta_v_3sigma_km_s"),
      "delta_v_3sigma_magnitude_km_s" => value(row, "delta_v_3sigma_magnitude_km_s"),
      "execution_uncertainty_source" => value(row, "execution_uncertainty_source")
    }
    |> compact_map()
  end

  defp declared_execution_uncertainty?(%{"execution_uncertainty_status" => "declared"}), do: true
  defp declared_execution_uncertainty?(_context), do: false

  defp missing_execution_uncertainty?(%{"execution_uncertainty_status" => "missing"}), do: true
  defp missing_execution_uncertainty?(_context), do: false

  defp maneuver_delta_v(activity) do
    first_value(activity, [
      "delta_v_km_s",
      "actual_delta_v_km_s",
      "executed_delta_v_km_s",
      ["metadata", "delta_v_km_s"],
      ["metadata", "actual_delta_v_km_s"],
      ["metadata", "executed_delta_v_km_s"]
    ])
    |> numeric_triplet()
  end

  defp numeric_triplet([x, y, z]) do
    triplet = Enum.map([x, y, z], &numeric_value/1)

    if Enum.all?(triplet, &is_number/1), do: triplet, else: nil
  end

  defp numeric_triplet(_value), do: nil

  defp numeric_value(value) when is_number(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp vector_norm(nil), do: nil

  defp vector_norm([x, y, z]) do
    :math.sqrt(x * x + y * y + z * z)
  end

  defp vector_delta([actual_x, actual_y, actual_z], [planned_x, planned_y, planned_z]) do
    [actual_x - planned_x, actual_y - planned_y, actual_z - planned_z]
  end

  defp vector_delta(_actual, _planned), do: nil

  defp realized_observation_success_factor(activity) do
    explicit_observation_success_factor(activity) ||
      provider_result_observation_factor(activity) ||
      completed_fraction_observation_factor(activity)
  end

  defp realized_observation_success_factor_source(activity) do
    Map.get(activity, "observation_success_factor_source") ||
      get_in(activity, ["metadata", "observation_success_factor_source"]) ||
      if is_nil(explicit_observation_success_factor(activity)) do
        provider_result_observation_factor_source(activity) ||
          completed_fraction_observation_factor_source(activity)
      end
  end

  defp explicit_observation_success_factor(activity) do
    first_unit_interval_number(activity, [
      "observation_success_factor",
      ["metadata", "observation_success_factor"]
    ])
  end

  defp normalized_completed_fraction(activity) do
    unit_interval_number_or_nil(Map.get(activity, "completed_fraction"))
  end

  defp first_unit_interval_number(activity, fields) do
    Enum.find_value(fields, fn field ->
      value =
        case field do
          path when is_list(path) -> feedback_path_value(activity, path)
          field -> first_value(activity, [field])
        end

      unit_interval_number_or_nil(value)
    end)
  end

  defp provider_result_observation_factor(%{"observation_result" => result} = activity) do
    provider_result_feedback_value(result, activity)
  end

  defp provider_result_observation_factor(_activity), do: nil

  defp provider_result_observation_factor_source(%{"observation_result" => result})
       when not is_nil(result) do
    case provider_result_outcome(result) do
      outcome when outcome in [:failure, :success] -> "realized_activity.observation_result"
      :unknown -> nil
    end
  end

  defp provider_result_observation_factor_source(_activity), do: nil

  defp completed_fraction_observation_factor(%{"type" => type} = activity)
       when type in ["observe", "observation"] do
    case numeric_value(Map.get(activity, "completed_fraction")) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp completed_fraction_observation_factor(_activity), do: nil

  defp completed_fraction_observation_factor_source(activity) do
    if completed_fraction_observation_factor(activity) do
      "realized_activity.completed_fraction"
    end
  end

  defp realized_contact_success_factor(activity) do
    explicit_contact_success_factor(activity) ||
      completed_fraction_contact_factor(activity)
  end

  defp realized_contact_success_factor_source(activity) do
    explicit_contact_success_factor_source(activity) ||
      if is_nil(explicit_contact_success_factor(activity)) do
        completed_fraction_contact_factor_source(activity)
      end
  end

  defp explicit_contact_success_factor(activity) do
    first_unit_interval_number(activity, [
      "contact_success_factor",
      ["metadata", "contact_success_factor"],
      ["throughput_model", "contact_success_factor"]
    ])
  end

  defp explicit_contact_success_factor_source(activity) do
    Map.get(activity, "contact_success_factor_source") ||
      get_in(activity, ["metadata", "contact_success_factor_source"]) ||
      get_in(activity, ["throughput_model", "confidence_source"])
  end

  defp completed_fraction_contact_factor(activity) do
    if contact_feedback_activity?(activity) do
      completed_fraction_factor(activity)
    end
  end

  defp completed_fraction_contact_factor_source(activity) do
    if completed_fraction_contact_factor(activity) do
      "realized_activity.completed_fraction"
    end
  end

  defp realized_command_success_factor(activity) do
    explicit_command_success_factor(activity) ||
      completed_fraction_command_factor(activity)
  end

  defp realized_command_success_factor_source(activity) do
    explicit_command_success_factor_source(activity) ||
      if is_nil(explicit_command_success_factor(activity)) do
        completed_fraction_command_factor_source(activity)
      end
  end

  defp explicit_command_success_factor(activity) do
    first_unit_interval_number(activity, [
      "command_success_factor",
      ["metadata", "command_success_factor"]
    ])
  end

  defp explicit_command_success_factor_source(activity) do
    Map.get(activity, "command_success_factor_source") ||
      get_in(activity, ["metadata", "command_success_factor_source"])
  end

  defp completed_fraction_command_factor(activity) do
    if command_feedback_activity?(activity) do
      completed_fraction_factor(activity)
    end
  end

  defp completed_fraction_command_factor_source(activity) do
    if completed_fraction_command_factor(activity) do
      "realized_activity.completed_fraction"
    end
  end

  defp completed_fraction_factor(activity) do
    unit_interval_number_or_nil(Map.get(activity, "completed_fraction"))
  end

  defp unit_interval_number_or_nil(value) do
    case unit_interval_number_status(value) do
      {:ok, number} -> number
      _status -> nil
    end
  end

  defp unit_interval_number_status(value) do
    case numeric_value(value) do
      number when is_number(number) and number >= 0.0 and number <= 1.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        if feedback_value_missing?(value), do: :missing, else: {:invalid_shape, value}
    end
  end

  defp nonnegative_number_status(value) do
    case numeric_value(value) do
      number when is_number(number) and number >= 0.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        if feedback_value_missing?(value), do: :missing, else: {:invalid_shape, value}
    end
  end

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false

  defp command_feedback_activity?(%{"type" => type}) when type in ["command", "health_check"],
    do: true

  defp command_feedback_activity?(%{"direction" => direction})
       when direction in @command_contact_directions or direction == "health_check",
       do: true

  defp command_feedback_activity?(_activity), do: false

  defp contact_feedback_activity?(%{"type" => type} = activity)
       when type in ["downlink", "planned_contact", "tracking"],
       do: not command_feedback_activity?(activity)

  defp contact_feedback_activity?(%{"direction" => direction})
       when direction in ["downlink", "tracking"],
       do: true

  defp contact_feedback_activity?(activity) do
    not command_feedback_activity?(activity) and
      (present_string?(Map.get(activity, "ground_station_id")) or
         present_string?(Map.get(activity, "station_id")) or
         is_map(Map.get(activity, "ground_station")) or
         is_map(Map.get(activity, "station")))
  end

  defp present_string?(value), do: is_binary(value) and value != ""

  defp first_identifier(map, keys) do
    Enum.find_value(keys, fn key ->
      value = first_value(map, [key])

      case value do
        nil -> nil
        value when is_binary(value) and value != "" -> stable_identifier(value)
        value when is_atom(value) -> value |> Atom.to_string() |> stable_identifier()
        %{} = nested -> identifier(nested, "id")
        _value -> nil
      end
    end)
  end

  defp first_value(map, keys) do
    Enum.reduce_while(keys, nil, fn key, _value ->
      metadata = Map.get(map, "metadata") || Map.get(map, :metadata) || %{}

      case fetch_key_or_atom(map, key) do
        {:ok, nil} ->
          first_value_from_metadata(metadata, key)

        {:ok, value} ->
          {:halt, value}

        :error ->
          first_value_from_metadata(metadata, key)
      end
    end)
  end

  defp first_value_from_metadata(metadata, key) do
    case fetch_key_or_atom(metadata, key) do
      {:ok, nil} -> {:cont, nil}
      {:ok, value} -> {:halt, value}
      :error -> {:cont, nil}
    end
  end

  defp fetch_key_or_atom(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error when is_binary(key) -> fetch_existing_atom_key(map, key)
      :error -> :error
    end
  end

  defp fetch_key_or_atom(_map, _key), do: :error

  defp fetch_existing_atom_key(map, key) do
    atom_key = String.to_existing_atom(key)
    Map.fetch(map, atom_key)
  rescue
    ArgumentError -> :error
  end

  defp normalize_id_list(nil, _map_keys), do: nil

  defp normalize_id_list(values, map_keys) when is_list(values) do
    values
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> normalize_scalar_ids()
  end

  defp normalize_id_list(value, map_keys) do
    value
    |> id_values(map_keys)
    |> normalize_scalar_ids()
  end

  defp id_values(%{} = value, map_keys) do
    Enum.flat_map(map_keys, fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value, _map_keys), do: [value]

  defp normalize_scalar_ids(values) do
    values
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp stable_id_value(nil), do: []
  defp stable_id_value(value) when is_boolean(value), do: []

  defp stable_id_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> stable_id_value()
  end

  defp stable_id_value("nil"), do: []

  defp stable_id_value(value) when is_binary(value) and value != "" do
    if stable_id?(value), do: [value], else: []
  end

  defp stable_id_value(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> stable_id_value()
  end

  defp stable_id_value(_value), do: []

  defp required_id!(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" -> value
      value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
      _value -> raise ArgumentError, "#{key} is required"
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp stringify_scalar(nil), do: nil
  defp stringify_scalar(value) when is_binary(value), do: value
  defp stringify_scalar(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_scalar(value) when is_integer(value), do: Integer.to_string(value)
  defp stringify_scalar(value) when is_float(value), do: Float.to_string(value)
  defp stringify_scalar(_value), do: nil

  defp truthy?(value) when is_boolean(value), do: value
  defp truthy?(value) when is_number(value), do: value == 1

  defp truthy?(value) when is_binary(value) do
    String.downcase(String.trim(value)) in ["true", "yes", "1"]
  end

  defp truthy?(_value), do: false

  defp boolean_value(value) when is_boolean(value), do: value

  defp boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "yes" -> true
      "1" -> true
      "false" -> false
      "no" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
