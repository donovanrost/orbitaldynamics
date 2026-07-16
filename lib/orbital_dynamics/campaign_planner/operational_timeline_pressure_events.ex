defmodule OrbitalDynamics.CampaignPlanner.OperationalTimelinePressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    CommandWindowOperationalFeedback,
    FeedbackNumericValues,
    ManeuverReviewExecutionUncertainty,
    ManeuverReviewOperationalFeedback,
    ObservationQualityValues,
    OperatorReviewFeedbackRows,
    ProviderResultValues,
    RealizedActivitySuccessValues,
    RealizedFeedbackContext,
    RealizedFeedbackPressureEvents,
    RealizedFeedbackRows,
    ValueEncoding
  }

  def review_row?(row), do: review_row?(row, default_callbacks())

  def review_row?(row, opts) when is_list(opts) do
    operational_timeline_row = Keyword.fetch!(opts, :operational_timeline_row)

    (row["source_review_type"] == "operational_timeline_review" or
       row["review_type"] == "operational_timeline_review" or
       row["import_action"] == "review_operational_timeline") and
      pressure_events(operational_timeline_row.(row), "candidate", opts) != []
  end

  def pressure_branch(row, source_path, index),
    do: pressure_branch(row, source_path, index, default_callbacks())

  def pressure_branch(row, source_path, index, opts) when is_list(opts) do
    case pressure_events(row, source_path, opts) do
      [] ->
        []

      events ->
        [
          %{
            "id" => pressure_branch_id(row, index, opts),
            "label" =>
              "Derived operational-timeline feedback #{pressure_identity(row, index, opts)}",
            "events" => events,
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_events(row, source_path),
    do: pressure_events(row, source_path, default_callbacks())

  def pressure_events(row, source_path, opts) when is_list(opts) do
    feedback_row_usable? = Keyword.fetch!(opts, :operator_review_feedback_row_usable?)
    command_feedback_row? = Keyword.fetch!(opts, :operator_review_command_feedback_row?)
    maneuver_feedback_row? = Keyword.fetch!(opts, :operator_review_maneuver_feedback_row?)
    contact_feedback_row? = Keyword.fetch!(opts, :operator_review_contact_feedback_row?)
    observation_feedback_row? = Keyword.fetch!(opts, :operator_review_observation_feedback_row?)

    cond do
      not feedback_row_usable?.(row) ->
        []

      command_feedback_row?.(row) ->
        row
        |> command_feedback_event(source_path, opts)
        |> feedback_event("operational_timeline_command_feedback")

      maneuver_feedback_row?.(row) ->
        row
        |> maneuver_feedback_events(source_path, opts)

      contact_feedback_row?.(row) ->
        [
          row
          |> contact_success_feedback_event(source_path, opts)
          |> feedback_event("operational_timeline_contact_feedback"),
          row
          |> station_throughput_feedback_event(source_path, opts)
          |> feedback_event("operational_timeline_contact_throughput")
        ]

      observation_feedback_row?.(row) ->
        row
        |> observation_feedback_event(source_path, opts)
        |> feedback_event("operational_timeline_observation_feedback")

      true ->
        []
    end
    |> List.wrap()
    |> Kernel.++([
      row
      |> integrity_feedback_event(source_path, opts)
      |> feedback_event("operational_timeline_integrity_feedback")
    ])
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Map.merge(&1, activity_integrity_context(row, opts)))
  end

  defp command_feedback_event(row, source_path, opts) do
    command_window_pressure_event = Keyword.fetch!(opts, :command_window_pressure_event)
    command_window_pressure_event.(row, source_path)
  end

  defp maneuver_feedback_events(row, source_path, opts) do
    [
      row
      |> maneuver_feedback_event(source_path, opts)
      |> feedback_event("operational_timeline_maneuver_feedback"),
      row
      |> maneuver_uncertainty_feedback_event(source_path, opts)
      |> feedback_event("operational_timeline_maneuver_uncertainty")
    ]
  end

  defp maneuver_feedback_event(row, source_path, opts) do
    maneuver_review_pressure_event = Keyword.fetch!(opts, :maneuver_review_pressure_event)
    maneuver_review_pressure_event.(row, source_path)
  end

  defp station_throughput_feedback_event(row, source_path, opts) do
    realized_station_throughput_feedback_event =
      Keyword.fetch!(opts, :realized_station_throughput_feedback_event)

    realized_station_throughput_feedback_event.(row, source_path)
  end

  defp feedback_event(nil, _reason), do: nil

  defp feedback_event(event, reason) do
    event
    |> Map.put("derivation_reasons", [reason])
    |> Map.put("feedback_scope", "operational_timeline")
  end

  defp integrity_feedback_event(row, source_path, opts) do
    issue_context = integrity_issue_context(row, opts)
    activity_id = realized_feedback_activity_id(row, opts)
    timeline_id = explicit_timeline_id(row, opts)

    if issue_context == %{} or (activity_id in [nil, ""] and timeline_id in [nil, ""]) do
      nil
    else
      compact_map = Keyword.fetch!(opts, :compact_map)
      operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)

      %{
        "type" => "timeline_integrity_feedback",
        "activity_id" => activity_id,
        "timeline_id" => timeline_id,
        "scenario_id" => row["scenario_id"],
        "required_operator_action" =>
          row["required_operator_action"] || "review_timeline_integrity",
        "feedback_source" => source_path,
        "feedback_key" => activity_id || timeline_id,
        "trust_boundary" => operator_review_trust_boundary.(row)
      }
      |> Map.merge(activity_integrity_context(row, opts))
      |> compact_map.()
    end
  end

  def activity_integrity_context(row),
    do: activity_integrity_context(row, integrity_context_opts())

  def activity_integrity_context(row, opts) when is_list(opts) do
    %{
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "exclusivity_group" => row["exclusivity_group"]
    }
    |> Map.merge(integrity_issue_context(row, opts))
    |> reject_empty_values(opts)
  end

  def integrity_issue_context(row), do: integrity_issue_context(row, integrity_context_opts())

  def integrity_issue_context(row, opts) when is_list(opts) do
    %{
      "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
      "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
      "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
      "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => row["exclusivity_violation_group"]
    }
    |> reject_empty_values(opts)
  end

  defp contact_success_feedback_event(row, source_path, opts) do
    contact_success_value = Keyword.fetch!(opts, :contact_success_value)

    case contact_success_value.(row) do
      value when is_number(value) and value < 1.0 ->
        clamp_unit_interval = Keyword.fetch!(opts, :clamp_unit_interval)
        compact_map = Keyword.fetch!(opts, :compact_map)
        operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
        provider_result_artifact_value = Keyword.fetch!(opts, :provider_result_artifact_value)
        put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)

        put_observation_quality_feedback_fields =
          Keyword.fetch!(opts, :put_observation_quality_feedback_fields)

        %{
          "type" => "contact_success_feedback",
          "ground_station_id" => Map.get(row, "ground_station_id") || Map.get(row, "station_id"),
          "activity_id" => realized_feedback_activity_id(row, opts),
          "scenario_id" => row["scenario_id"],
          "starts_at_s" => activity_raw_start(row, opts) || 0.0,
          "ends_at_s" => activity_raw_end(row, opts),
          "contact_success_factor" => clamp_unit_interval.(value),
          "contact_result" => provider_result_artifact_value.(row["contact_result"]),
          "required_operator_action" => row["required_operator_action"],
          "timeline_id" => explicit_timeline_id(row, opts),
          "feedback_source" => source_path,
          "feedback_scope" => "operational_timeline",
          "feedback_key" => Map.get(row, "ground_station_id") || Map.get(row, "station_id"),
          "trust_boundary" => operator_review_trust_boundary.(row)
        }
        |> put_feedback_weight_fields.(row)
        |> put_observation_quality_feedback_fields.(row)
        |> compact_map.()

      _value ->
        nil
    end
  end

  defp maneuver_uncertainty_feedback_event(row, source_path, opts) do
    maneuver_review_execution_uncertainty_entry =
      Keyword.fetch!(opts, :maneuver_review_execution_uncertainty_entry)

    entry = maneuver_review_execution_uncertainty_entry.(row)
    activity_id = realized_feedback_activity_id(row, opts)

    if entry == %{} or activity_id in [nil, ""] do
      nil
    else
      compact_map = Keyword.fetch!(opts, :compact_map)
      operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)

      %{
        "type" => "maneuver_execution_uncertainty_feedback",
        "activity_id" => activity_id,
        "scenario_id" => row["scenario_id"],
        "starts_at_s" => activity_raw_start(row, opts) || 0.0,
        "ends_at_s" => activity_raw_end(row, opts),
        "execution_uncertainty_status" => entry["execution_uncertainty_status"],
        "execution_uncertainty" => entry["execution_uncertainty"],
        "timing_3sigma_s" => entry["timing_3sigma_s"],
        "delta_v_3sigma_km_s" => entry["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => entry["delta_v_3sigma_magnitude_km_s"],
        "execution_uncertainty_source" => entry["execution_uncertainty_source"],
        "required_operator_action" => row["required_operator_action"],
        "cadence_import_status" => row["cadence_import_status"],
        "timeline_id" => explicit_timeline_id(row, opts),
        "maneuver_id" => row["maneuver_id"],
        "feedback_source" => source_path,
        "feedback_scope" => "operational_timeline",
        "feedback_key" => activity_id,
        "trust_boundary" => operator_review_trust_boundary.(row)
      }
      |> compact_map.()
    end
  end

  defp observation_feedback_event(row, source_path, opts) do
    observation_success_value = Keyword.fetch!(opts, :observation_success_value)

    case observation_success_value.(row) do
      value when is_number(value) and value < 1.0 ->
        clamp_unit_interval = Keyword.fetch!(opts, :clamp_unit_interval)
        compact_map = Keyword.fetch!(opts, :compact_map)
        operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
        provider_result_artifact_value = Keyword.fetch!(opts, :provider_result_artifact_value)
        put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)

        put_observation_quality_feedback_fields =
          Keyword.fetch!(opts, :put_observation_quality_feedback_fields)

        %{
          "type" => "observation_success_feedback",
          "target_id" => Map.get(row, "target_id") || Map.get(row, "id"),
          "activity_id" => realized_feedback_activity_id(row, opts),
          "scenario_id" => row["scenario_id"],
          "starts_at_s" => activity_raw_start(row, opts) || 0.0,
          "ends_at_s" => activity_raw_end(row, opts),
          "observation_success_factor" => clamp_unit_interval.(value),
          "observation_result" => provider_result_artifact_value.(row["observation_result"]),
          "required_operator_action" => row["required_operator_action"],
          "timeline_id" => explicit_timeline_id(row, opts),
          "feedback_source" => source_path,
          "feedback_scope" => "operational_timeline",
          "feedback_key" => Map.get(row, "target_id") || Map.get(row, "id"),
          "trust_boundary" => operator_review_trust_boundary.(row)
        }
        |> put_feedback_weight_fields.(row)
        |> put_observation_quality_feedback_fields.(row)
        |> compact_map.()

      _value ->
        nil
    end
  end

  defp pressure_branch_id(row, index, opts),
    do: "derived_operational_timeline_feedback_#{pressure_identity(row, index, opts)}"

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      realized_feedback_activity_id(row, opts),
      explicit_timeline_id(row, opts),
      row["id"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp activity_raw_start(row, opts) do
    Keyword.fetch!(opts, :activity_raw_start).(row)
  end

  defp activity_raw_end(row, opts) do
    Keyword.fetch!(opts, :activity_raw_end).(row)
  end

  defp explicit_timeline_id(row, opts) do
    Keyword.fetch!(opts, :explicit_timeline_id).(row)
  end

  defp realized_feedback_activity_id(row, opts) do
    Keyword.fetch!(opts, :realized_feedback_activity_id).(row)
  end

  defp reject_empty_values(row, opts) do
    Keyword.fetch!(opts, :reject_empty_values).(row)
  end

  defp integrity_context_opts do
    [
      reject_empty_values: &ValueEncoding.reject_empty_values/1
    ]
  end

  defp default_callbacks do
    [
      operational_timeline_row: &OperatorReviewFeedbackRows.operational_timeline_row/1,
      operator_review_feedback_row_usable?: &RealizedFeedbackRows.operator_review_usable?/1,
      operator_review_command_feedback_row?: &RealizedFeedbackRows.operator_review_command?/1,
      operator_review_maneuver_feedback_row?: &RealizedFeedbackRows.operator_review_maneuver?/1,
      operator_review_contact_feedback_row?: &RealizedFeedbackRows.operator_review_contact?/1,
      operator_review_observation_feedback_row?:
        &RealizedFeedbackRows.operator_review_observation?/1,
      command_window_pressure_event: &CommandWindowOperationalFeedback.pressure_event/2,
      maneuver_review_pressure_event: &ManeuverReviewOperationalFeedback.pressure_event/2,
      realized_station_throughput_feedback_event:
        &RealizedFeedbackPressureEvents.station_throughput_feedback_event/2,
      contact_success_value: &operational_timeline_contact_success_value/1,
      observation_success_value: &operational_timeline_observation_success_value/1,
      maneuver_review_execution_uncertainty_entry: &ManeuverReviewExecutionUncertainty.entry/1,
      realized_feedback_activity_id: &RealizedFeedbackContext.activity_id/1,
      explicit_timeline_id: &RealizedFeedbackContext.explicit_timeline_id/1,
      activity_raw_start: &ActivityTiming.activity_raw_start/1,
      activity_raw_end: &ActivityTiming.activity_raw_end/1,
      clamp_unit_interval: &FeedbackNumericValues.clamp_unit_interval/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      put_feedback_weight_fields: &put_feedback_weight_fields/2,
      put_observation_quality_feedback_fields: &put_observation_quality_feedback_fields/2,
      compact_map: &ValueEncoding.compact_map/1,
      reject_empty_values: &ValueEncoding.reject_empty_values/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1
    ]
  end

  defp operational_timeline_contact_success_value(row) do
    case FeedbackNumericValues.unit_interval_number_or_nil(row["contact_success_factor"]) do
      value when is_number(value) -> value
      _value -> RealizedActivitySuccessValues.contact(row)
    end
  end

  defp operational_timeline_observation_success_value(row) do
    case FeedbackNumericValues.unit_interval_number_or_nil(row["observation_success_factor"]) do
      value when is_number(value) -> value
      _value -> RealizedActivitySuccessValues.observation(row)
    end
  end

  defp put_feedback_weight_fields(event, source) do
    [
      "feedback_weight",
      "feedback_weight_source",
      "feedback_sample_weight",
      "feedback_sample_weight_source",
      "sample_weight",
      "sample_weight_source",
      "confidence_weight",
      "confidence_weight_source"
    ]
    |> Enum.reduce(event, fn field, acc -> put_if_present(acc, field, source[field]) end)
  end

  defp put_observation_quality_feedback_fields(event, source) do
    event
    |> put_if_present("image_quality_score", ObservationQualityValues.image_quality_score(source))
    |> put_if_present(
      "image_quality_status",
      ObservationQualityValues.image_quality_status(source)
    )
    |> put_if_present(
      "image_quality_source",
      ObservationQualityValues.image_quality_source(source)
    )
    |> put_if_present(
      "cloud_cover_fraction",
      ObservationQualityValues.cloud_cover_fraction(source)
    )
    |> put_if_present("blur_score", ObservationQualityValues.blur_score(source))
  end

  defp put_if_present(map, _key, value) when value in [nil, ""], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
