defmodule OrbitalDynamics.CampaignPlanner.RealizedFeedbackPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    CommandWindowOperationalFeedback,
    ContactThroughputFields,
    FeedbackNumericValues,
    ManeuverReviewExecutionUncertainty,
    ManeuverReviewFeedbackRows,
    ManeuverReviewOperationalFeedback,
    ObservationQualityValues,
    OperatorReviewFeedbackRows,
    ProviderResultValues,
    RealizedActivitySuccessValues,
    RealizedFeedbackContext,
    RealizedFeedbackRows,
    ValueEncoding
  }

  def source(row), do: source(row, row_callbacks())

  def source(%{"source_feedback" => %{} = source} = row, opts) when map_size(source) > 0 do
    {review_row(source, row, opts), "source_feedback"}
  end

  def source(row, opts), do: {review_row(row, row, opts), "realized_feedback"}

  def review_row(source, row), do: review_row(source, row, row_callbacks())

  def review_row(source, row, opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_if_present = Keyword.fetch!(opts, :put_if_present)
    put_operator_review_row_fallback = Keyword.fetch!(opts, :put_operator_review_row_fallback)
    put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)

    operator_review_realized_feedback_type =
      Keyword.fetch!(opts, :operator_review_realized_feedback_type)

    source
    |> stringify_keys.()
    |> put_if_present.("feedback_status", row["feedback_status"])
    |> put_if_present.("status", row["realized_status"] || row["status"])
    |> put_operator_review_row_fallback.(row, "activity_id", nil)
    |> put_operator_review_row_fallback.(row, "id", "activity_id")
    |> put_operator_review_row_fallback.(row, "timeline_id", "timeline_identity")
    |> put_operator_review_row_fallback.(row, "scenario_id", nil)
    |> put_operator_review_row_fallback.(row, "ground_station_id", nil)
    |> put_operator_review_row_fallback.(row, "ground_station_id", "planned_ground_station_id")
    |> put_operator_review_row_fallback.(row, "ground_station_id", "realized_ground_station_id")
    |> put_operator_review_row_fallback.(row, "target_id", nil)
    |> put_operator_review_row_fallback.(row, "target_id", "planned_target_id")
    |> put_operator_review_row_fallback.(row, "target_id", "realized_target_id")
    |> put_operator_review_row_fallback.(row, "contact_success", nil)
    |> put_operator_review_row_fallback.(row, "contact_success_factor", nil)
    |> put_operator_review_row_fallback.(row, "contact_result", nil)
    |> put_operator_review_row_fallback.(row, "observation_success", nil)
    |> put_operator_review_row_fallback.(row, "observation_success_factor", nil)
    |> put_operator_review_row_fallback.(row, "observation_result", nil)
    |> put_operator_review_row_fallback.(row, "command_success", nil)
    |> put_operator_review_row_fallback.(row, "command_success_factor", nil)
    |> put_operator_review_row_fallback.(row, "command_result", nil)
    |> put_operator_review_row_fallback.(row, "maneuver_success", nil)
    |> put_operator_review_row_fallback.(row, "maneuver_success_factor", nil)
    |> put_operator_review_row_fallback.(row, "maneuver_result", nil)
    |> put_operator_review_row_fallback.(row, "execution_uncertainty", nil)
    |> put_operator_review_row_fallback.(row, "execution_uncertainty_status", nil)
    |> put_operator_review_row_fallback.(row, "timing_3sigma_s", nil)
    |> put_operator_review_row_fallback.(row, "delta_v_3sigma_km_s", nil)
    |> put_operator_review_row_fallback.(row, "delta_v_3sigma_magnitude_km_s", nil)
    |> put_operator_review_row_fallback.(row, "execution_uncertainty_source", nil)
    |> put_operator_review_row_fallback.(row, "actual_throughput_mb", nil)
    |> put_operator_review_row_fallback.(row, "estimated_throughput_mb", nil)
    |> put_operator_review_row_fallback.(row, "required_downlink_mb", nil)
    |> put_operator_review_row_fallback.(row, "completed_fraction", nil)
    |> put_feedback_weight_fields.(row)
    |> put_if_present.("type", operator_review_realized_feedback_type.(row, source))
    |> put_if_present.("_operator_review_feedback_status", row["feedback_status"])
    |> put_if_present.("_operator_review_match_strategy", row["match_strategy"])
    |> put_if_present.("_operator_review_realized_match_count", row["realized_match_count"])
    |> put_if_present.(
      "_operator_review_invalid_realized_feedback_input",
      row["invalid_realized_feedback_input"]
    )
    |> put_if_present.("_operator_review_invalid_activity_input", row["invalid_activity_input"])
  end

  def review_row?(row), do: review_row?(row, default_callbacks())

  def review_row?(row, opts) do
    (row["source_review_type"] == "realized_feedback" or
       row["review_type"] == "realized_feedback" or
       row["import_action"] in ["review_realized_feedback", "record_realized_feedback"]) and
      pressure_events(row, "candidate", opts) != []
  end

  def pressure_branch(row, source_path, index),
    do: pressure_branch(row, source_path, index, default_callbacks())

  def pressure_branch(row, source_path, index, opts) do
    case pressure_events(row, source_path, opts) do
      [] ->
        []

      events ->
        [
          %{
            "id" => pressure_branch_id(row, index, opts),
            "label" => "Derived realized-feedback #{pressure_identity(row, index, opts)}",
            "events" => events,
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_events(row, source_path),
    do: pressure_events(row, source_path, default_callbacks())

  def pressure_events(row, source_path, opts) do
    operator_review_feedback_row_usable? =
      Keyword.fetch!(opts, :operator_review_feedback_row_usable?)

    operator_review_command_feedback_row? =
      Keyword.fetch!(opts, :operator_review_command_feedback_row?)

    operator_review_maneuver_feedback_row? =
      Keyword.fetch!(opts, :operator_review_maneuver_feedback_row?)

    operator_review_contact_feedback_row? =
      Keyword.fetch!(opts, :operator_review_contact_feedback_row?)

    operator_review_observation_feedback_row? =
      Keyword.fetch!(opts, :operator_review_observation_feedback_row?)

    cond do
      not operator_review_feedback_row_usable?.(row) ->
        []

      operator_review_command_feedback_row?.(row) ->
        [command_feedback_event(row, source_path, opts)]

      operator_review_maneuver_feedback_row?.(row) ->
        maneuver_feedback_events(row, source_path, opts)

      operator_review_contact_feedback_row?.(row) ->
        contact_feedback_events(row, source_path, opts)

      operator_review_observation_feedback_row?.(row) ->
        observation_feedback_events(row, source_path, opts)

      true ->
        []
    end
    |> Enum.reject(&is_nil/1)
  end

  defp command_feedback_event(row, source_path, opts) do
    command_success_value = Keyword.fetch!(opts, :command_success_value)
    command_window_pressure_event = Keyword.fetch!(opts, :command_window_pressure_event)

    case command_success_value.(row) do
      value when is_number(value) and value < 1.0 ->
        row
        |> command_window_pressure_event.(source_path)
        |> Map.put("derivation_reasons", ["realized_command_feedback"])
        |> Map.put("feedback_scope", "realized_feedback")

      _value ->
        nil
    end
  end

  defp maneuver_feedback_event(row, source_path, opts) do
    maneuver_review_row_success_value = Keyword.fetch!(opts, :maneuver_review_row_success_value)
    maneuver_review_pressure_event = Keyword.fetch!(opts, :maneuver_review_pressure_event)

    case maneuver_review_row_success_value.(row) do
      value when is_number(value) and value < 1.0 ->
        row
        |> maneuver_review_pressure_event.(source_path)
        |> Map.put("derivation_reasons", ["realized_maneuver_feedback"])
        |> Map.put("feedback_scope", "realized_feedback")

      _value ->
        nil
    end
  end

  defp maneuver_feedback_events(row, source_path, opts) do
    [
      maneuver_feedback_event(row, source_path, opts),
      maneuver_uncertainty_feedback_event(row, source_path, opts)
    ]
  end

  defp maneuver_uncertainty_feedback_event(row, source_path, opts) do
    maneuver_review_execution_uncertainty_entry =
      Keyword.fetch!(opts, :maneuver_review_execution_uncertainty_entry)

    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    activity_raw_start = Keyword.fetch!(opts, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(opts, :activity_raw_end)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
    compact_map = Keyword.fetch!(opts, :compact_map)

    entry = maneuver_review_execution_uncertainty_entry.(row)
    activity_id = realized_feedback_activity_id.(row)

    if entry == %{} or activity_id in [nil, ""] do
      nil
    else
      %{
        "type" => "maneuver_execution_uncertainty_feedback",
        "activity_id" => activity_id,
        "scenario_id" => row["scenario_id"],
        "starts_at_s" => activity_raw_start.(row) || 0.0,
        "ends_at_s" => activity_raw_end.(row),
        "execution_uncertainty_status" => entry["execution_uncertainty_status"],
        "execution_uncertainty" => entry["execution_uncertainty"],
        "timing_3sigma_s" => entry["timing_3sigma_s"],
        "delta_v_3sigma_km_s" => entry["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => entry["delta_v_3sigma_magnitude_km_s"],
        "execution_uncertainty_source" => entry["execution_uncertainty_source"],
        "required_operator_action" => row["required_operator_action"],
        "cadence_import_status" => row["cadence_import_status"],
        "timeline_id" => explicit_timeline_id.(row),
        "maneuver_id" => row["maneuver_id"],
        "derivation_reasons" => ["realized_maneuver_uncertainty"],
        "feedback_source" => source_path,
        "feedback_scope" => "realized_feedback",
        "feedback_key" => activity_id,
        "trust_boundary" => operator_review_trust_boundary.(row)
      }
      |> compact_map.()
    end
  end

  defp contact_feedback_events(row, source_path, opts) do
    [
      contact_success_feedback_event(row, source_path, opts),
      station_throughput_feedback_event(row, source_path, opts)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp contact_success_feedback_event(row, source_path, opts) do
    contact_success_value = Keyword.fetch!(opts, :contact_success_value)

    case contact_success_value.(row) do
      value when is_number(value) and value < 1.0 ->
        contact_event(row, source_path, value, opts)

      _value ->
        nil
    end
  end

  defp contact_event(row, source_path, value, opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    activity_raw_start = Keyword.fetch!(opts, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(opts, :activity_raw_end)
    clamp_unit_interval = Keyword.fetch!(opts, :clamp_unit_interval)
    provider_result_artifact_value = Keyword.fetch!(opts, :provider_result_artifact_value)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
    put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)
    compact_map = Keyword.fetch!(opts, :compact_map)

    %{
      "type" => "contact_success_feedback",
      "ground_station_id" => Map.get(row, "ground_station_id") || Map.get(row, "station_id"),
      "activity_id" => realized_feedback_activity_id.(row),
      "scenario_id" => row["scenario_id"],
      "starts_at_s" => activity_raw_start.(row) || 0.0,
      "ends_at_s" => activity_raw_end.(row),
      "contact_success_factor" => clamp_unit_interval.(value),
      "contact_result" => provider_result_artifact_value.(row["contact_result"]),
      "required_operator_action" => row["required_operator_action"],
      "timeline_id" => explicit_timeline_id.(row),
      "derivation_reasons" => ["realized_contact_feedback"],
      "feedback_source" => source_path,
      "feedback_scope" => "realized_feedback",
      "feedback_key" => Map.get(row, "ground_station_id") || Map.get(row, "station_id"),
      "trust_boundary" => operator_review_trust_boundary.(row)
    }
    |> put_feedback_weight_fields.(row)
    |> compact_map.()
  end

  def station_throughput_feedback_event(row, source_path),
    do: station_throughput_feedback_event(row, source_path, default_callbacks())

  def station_throughput_feedback_event(row, source_path, opts) do
    station_throughput_value = Keyword.fetch!(opts, :station_throughput_value)

    case station_throughput_value.(row) do
      value when is_number(value) and value < 1.0 ->
        station_throughput_event(row, source_path, value, opts)

      _value ->
        nil
    end
  end

  defp station_throughput_event(row, source_path, value, opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    activity_raw_start = Keyword.fetch!(opts, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(opts, :activity_raw_end)
    clamp_unit_interval = Keyword.fetch!(opts, :clamp_unit_interval)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
    put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)
    compact_map = Keyword.fetch!(opts, :compact_map)

    %{
      "type" => "station_throughput_feedback",
      "ground_station_id" => Map.get(row, "ground_station_id") || Map.get(row, "station_id"),
      "activity_id" => realized_feedback_activity_id.(row),
      "scenario_id" => row["scenario_id"],
      "starts_at_s" => activity_raw_start.(row) || 0.0,
      "ends_at_s" => activity_raw_end.(row),
      "station_throughput_factor" => clamp_unit_interval.(value),
      "actual_throughput_mb" => row["actual_throughput_mb"],
      "estimated_throughput_mb" => row["estimated_throughput_mb"],
      "required_operator_action" => row["required_operator_action"],
      "timeline_id" => explicit_timeline_id.(row),
      "derivation_reasons" => ["realized_station_throughput_feedback"],
      "feedback_source" => source_path,
      "feedback_scope" => "realized_feedback",
      "feedback_key" => Map.get(row, "ground_station_id") || Map.get(row, "station_id"),
      "trust_boundary" => operator_review_trust_boundary.(row)
    }
    |> put_feedback_weight_fields.(row)
    |> compact_map.()
  end

  defp observation_feedback_events(row, source_path, opts) do
    observation_success_value = Keyword.fetch!(opts, :observation_success_value)

    case observation_success_value.(row) do
      value when is_number(value) and value < 1.0 ->
        [observation_event(row, source_path, value, opts)]

      _value ->
        []
    end
  end

  defp observation_event(row, source_path, value, opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    activity_raw_start = Keyword.fetch!(opts, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(opts, :activity_raw_end)
    clamp_unit_interval = Keyword.fetch!(opts, :clamp_unit_interval)
    provider_result_artifact_value = Keyword.fetch!(opts, :provider_result_artifact_value)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
    put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)

    put_observation_quality_feedback_fields =
      Keyword.fetch!(opts, :put_observation_quality_feedback_fields)

    compact_map = Keyword.fetch!(opts, :compact_map)

    %{
      "type" => "observation_success_feedback",
      "target_id" => Map.get(row, "target_id") || Map.get(row, "id"),
      "activity_id" => realized_feedback_activity_id.(row),
      "scenario_id" => row["scenario_id"],
      "starts_at_s" => activity_raw_start.(row) || 0.0,
      "ends_at_s" => activity_raw_end.(row),
      "observation_success_factor" => clamp_unit_interval.(value),
      "observation_result" => provider_result_artifact_value.(row["observation_result"]),
      "required_operator_action" => row["required_operator_action"],
      "timeline_id" => explicit_timeline_id.(row),
      "derivation_reasons" => ["realized_observation_feedback"],
      "feedback_source" => source_path,
      "feedback_scope" => "realized_feedback",
      "feedback_key" => Map.get(row, "target_id") || Map.get(row, "id"),
      "trust_boundary" => operator_review_trust_boundary.(row)
    }
    |> put_feedback_weight_fields.(row)
    |> put_observation_quality_feedback_fields.(row)
    |> compact_map.()
  end

  defp pressure_branch_id(row, index, opts),
    do: "derived_realized_feedback_#{pressure_identity(row, index, opts)}"

  defp pressure_identity(row, index, opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      realized_feedback_activity_id.(row),
      explicit_timeline_id.(row),
      row["id"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp row_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      put_if_present: &put_if_present/3,
      put_operator_review_row_fallback: &put_operator_review_row_fallback/4,
      put_feedback_weight_fields: &put_feedback_weight_fields/2,
      operator_review_realized_feedback_type: &OperatorReviewFeedbackRows.realized_feedback_type/2
    ]
  end

  defp default_callbacks do
    [
      put_feedback_weight_fields: &put_feedback_weight_fields/2,
      put_observation_quality_feedback_fields: &put_observation_quality_feedback_fields/2,
      operator_review_feedback_row_usable?: &RealizedFeedbackRows.operator_review_usable?/1,
      operator_review_command_feedback_row?: &RealizedFeedbackRows.operator_review_command?/1,
      operator_review_maneuver_feedback_row?: &RealizedFeedbackRows.operator_review_maneuver?/1,
      operator_review_contact_feedback_row?: &RealizedFeedbackRows.operator_review_contact?/1,
      operator_review_observation_feedback_row?:
        &RealizedFeedbackRows.operator_review_observation?/1,
      command_success_value: &RealizedActivitySuccessValues.command/1,
      command_window_pressure_event: &CommandWindowOperationalFeedback.pressure_event/2,
      maneuver_review_row_success_value: &ManeuverReviewFeedbackRows.success_value/1,
      maneuver_review_pressure_event: &ManeuverReviewOperationalFeedback.pressure_event/2,
      maneuver_review_execution_uncertainty_entry: &ManeuverReviewExecutionUncertainty.entry/1,
      realized_feedback_activity_id: &RealizedFeedbackContext.activity_id/1,
      activity_raw_start: &ActivityTiming.activity_raw_start/1,
      activity_raw_end: &ActivityTiming.activity_raw_end/1,
      explicit_timeline_id: &RealizedFeedbackContext.explicit_timeline_id/1,
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      compact_map: &ValueEncoding.compact_map/1,
      contact_success_value: &RealizedActivitySuccessValues.contact/1,
      station_throughput_value: &ContactThroughputFields.station_throughput_value/1,
      observation_success_value: &RealizedActivitySuccessValues.observation/1,
      clamp_unit_interval: &FeedbackNumericValues.clamp_unit_interval/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1
    ]
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

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp put_operator_review_row_fallback(source, row, field, row_field) do
    row_field = row_field || field

    case Map.get(source, field) do
      value when value in [nil, ""] -> put_if_present(source, field, row[row_field])
      _value -> source
    end
  end

  defp put_if_present(map, _key, value) when value in [nil, ""], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
