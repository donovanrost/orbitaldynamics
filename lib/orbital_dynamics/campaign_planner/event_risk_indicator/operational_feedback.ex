defmodule OrbitalDynamics.CampaignPlanner.EventRiskIndicator.OperationalFeedback do
  @moduledoc false

  def indicators(%{"type" => "station_throughput_feedback"} = event) do
    station = event_ground_station_id(event) || "default"

    [
      %{
        "type" => "station_throughput_factor_low",
        "severity" => "medium",
        "reason" =>
          "station #{station} throughput feedback factor #{event["station_throughput_factor"]} reduces generated contact capacity",
        "value" => event["station_throughput_factor"],
        "activity_id" => event["activity_id"],
        "scenario_id" => event["scenario_id"],
        "timeline_id" => event["timeline_id"],
        "ground_station_id" => event_ground_station_id(event),
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "station_throughput_factor" => event["station_throughput_factor"],
        "actual_throughput_mb" => event["actual_throughput_mb"],
        "estimated_throughput_mb" => event["estimated_throughput_mb"],
        "starts_at_s" => event["starts_at_s"] || event["source_starts_at_s"],
        "ends_at_s" => event["ends_at_s"] || event["source_ends_at_s"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "requires_operator_review" => event["requires_operator_review"],
        "status_transition" => event["status_transition"],
        "transition_type" => event["transition_type"],
        "transition_category" => event["transition_category"],
        "transition_reason" => event["transition_reason"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "contact_success_feedback"} = event) do
    station = event_ground_station_id(event) || "default"

    [
      %{
        "type" => "contact_success_rate_low",
        "severity" => "medium",
        "reason" =>
          "station #{station} contact success feedback factor #{event["contact_success_factor"]} reduces generated contact confidence",
        "value" => event["contact_success_factor"],
        "activity_id" => event["activity_id"],
        "scenario_id" => event["scenario_id"],
        "timeline_id" => event["timeline_id"],
        "starts_at_s" => event["starts_at_s"] || event["source_starts_at_s"],
        "ends_at_s" => event["ends_at_s"] || event["source_ends_at_s"],
        "contact_success_factor" => event["contact_success_factor"],
        "ground_station_id" => event_ground_station_id(event),
        "contact_result" => event["contact_result"],
        "realized_status" => event["realized_status"],
        "planned_ground_station_id" => event["planned_ground_station_id"],
        "realized_ground_station_id" => event["realized_ground_station_id"],
        "ground_station_match_status" => event["ground_station_match_status"],
        "direction" => event["direction"],
        "planned_direction" => event["planned_direction"],
        "realized_direction" => event["realized_direction"],
        "direction_match_status" => event["direction_match_status"],
        "source_window_id" => event["source_window_id"],
        "planned_source_window_id" => event["planned_source_window_id"],
        "realized_source_window_id" => event["realized_source_window_id"],
        "source_window_match_status" => event["source_window_match_status"],
        "contact_identity_mismatch_fields" => event["contact_identity_mismatch_fields"],
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "link_margin_db" => event["link_margin_db"],
        "snr_db" => event["snr_db"],
        "eb_no_db" => event["eb_no_db"],
        "bit_error_rate" => event["bit_error_rate"],
        "packet_loss_rate" => event["packet_loss_rate"],
        "frame_loss_rate" => event["frame_loss_rate"],
        "carrier_lock" => event["carrier_lock"],
        "symbol_lock" => event["symbol_lock"],
        "link_quality_status" => event["link_quality_status"],
        "status_transition" => event["status_transition"],
        "transition_type" => event["transition_type"],
        "transition_category" => event["transition_category"],
        "transition_reason" => event["transition_reason"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "derivation_reasons" => event["derivation_reasons"],
        "requires_operator_review" => event["requires_operator_review"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "observation_success_feedback"} = event) do
    [
      %{
        "type" => "observation_success_rate_low",
        "severity" => "medium",
        "reason" =>
          "target #{event["target_id"]} observation success feedback factor #{event["observation_success_factor"]} reduces generated observation confidence",
        "value" => event["observation_success_factor"],
        "activity_id" => event["activity_id"],
        "scenario_id" => event["scenario_id"],
        "spacecraft_id" => event["spacecraft_id"],
        "branch_id" => event["branch_id"],
        "timeline_id" => event["timeline_id"],
        "starts_at_s" => event["starts_at_s"] || event["source_starts_at_s"],
        "ends_at_s" => event["ends_at_s"] || event["source_ends_at_s"],
        "required_observations" => event["required_observations"],
        "planned_observations" => event["planned_observations"],
        "priority" => event["priority"],
        "latitude_deg" => event["latitude_deg"],
        "longitude_deg" => event["longitude_deg"],
        "minimum_elevation_deg" => event["minimum_elevation_deg"],
        "observation_success_factor" => event["observation_success_factor"],
        "target_id" => event["target_id"],
        "objective_id" => event["objective_id"],
        "objective_type" => event["objective_type"],
        "objective_status" => event["objective_status"],
        "source_objective_status" => event["source_objective_status"],
        "observation_result" => event["observation_result"],
        "realized_status" => event["realized_status"],
        "target_match_status" => event["target_match_status"],
        "collection_id" => event["collection_id"],
        "collection_ids" => event["collection_ids"],
        "planned_target_id" => event["planned_target_id"],
        "realized_target_id" => event["realized_target_id"],
        "collection_match_status" => event["collection_match_status"],
        "planned_collection_id" => event["planned_collection_id"],
        "realized_collection_id" => event["realized_collection_id"],
        "product_match_status" => event["product_match_status"],
        "planned_product_id" => event["planned_product_id"],
        "realized_product_id" => event["realized_product_id"],
        "product_ids_match_status" => event["product_ids_match_status"],
        "planned_product_ids" => event["planned_product_ids"],
        "realized_product_ids" => event["realized_product_ids"],
        "product_ids" => event["product_ids"],
        "payload_id" => event["payload_id"],
        "payload_ids" => event["payload_ids"],
        "payload_match_status" => event["payload_match_status"],
        "planned_payload_id" => event["planned_payload_id"],
        "realized_payload_id" => event["realized_payload_id"],
        "instrument_id" => event["instrument_id"],
        "instrument_ids" => event["instrument_ids"],
        "instrument_match_status" => event["instrument_match_status"],
        "planned_instrument_id" => event["planned_instrument_id"],
        "realized_instrument_id" => event["realized_instrument_id"],
        "observation_identity_mismatch_fields" => event["observation_identity_mismatch_fields"],
        "pointing_target_match_status" => event["pointing_target_match_status"],
        "pointing_mode_match_status" => event["pointing_mode_match_status"],
        "pointing_status" => event["pointing_status"],
        "pointing_error_deg" => event["pointing_error_deg"],
        "attitude_target_match_status" => event["attitude_target_match_status"],
        "attitude_mode_match_status" => event["attitude_mode_match_status"],
        "attitude_status" => event["attitude_status"],
        "attitude_error_deg" => event["attitude_error_deg"],
        "lighting_condition_match_status" => event["lighting_condition_match_status"],
        "planned_lighting_condition" => event["planned_lighting_condition"],
        "realized_lighting_condition" => event["realized_lighting_condition"],
        "lighting_condition_detail" => event["lighting_condition_detail"],
        "lighting_condition_model" => event["lighting_condition_model"],
        "lighting_detail_model" => event["lighting_detail_model"],
        "lighting_confidence" => event["lighting_confidence"],
        "eclipse_overlap_fraction" => event["eclipse_overlap_fraction"],
        "eclipse_overlap_s" => event["eclipse_overlap_s"],
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "image_quality_score" => event["image_quality_score"],
        "image_quality_status" => event["image_quality_status"],
        "image_quality_source" => event["image_quality_source"],
        "cloud_cover_fraction" => event["cloud_cover_fraction"],
        "blur_score" => event["blur_score"],
        "quality_feedback_source" => event["quality_feedback_source"],
        "status_transition" => event["status_transition"],
        "transition_type" => event["transition_type"],
        "transition_category" => event["transition_category"],
        "transition_reason" => event["transition_reason"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "derivation_reasons" => event["derivation_reasons"],
        "requires_operator_review" => event["requires_operator_review"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "command_success_feedback"} = event) do
    [
      %{
        "type" => "command_success_rate_low",
        "severity" => "medium",
        "reason" =>
          "command #{event["activity_id"]} success feedback factor #{event["command_success_factor"]} reduces branch confidence",
        "value" => event["command_success_factor"],
        "activity_id" => event["activity_id"],
        "scenario_id" => event["scenario_id"],
        "timeline_id" => event["timeline_id"],
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "command_success_factor" => event["command_success_factor"],
        "command_result" => event["command_result"],
        "realized_status" => event["realized_status"],
        "ground_station_id" => event["ground_station_id"],
        "planned_ground_station_id" => event["planned_ground_station_id"],
        "realized_ground_station_id" => event["realized_ground_station_id"],
        "ground_station_match_status" => event["ground_station_match_status"],
        "direction" => event["direction"],
        "planned_direction" => event["planned_direction"],
        "realized_direction" => event["realized_direction"],
        "direction_match_status" => event["direction_match_status"],
        "source_window_id" => event["source_window_id"],
        "planned_source_window_id" => event["planned_source_window_id"],
        "realized_source_window_id" => event["realized_source_window_id"],
        "source_window_match_status" => event["source_window_match_status"],
        "command_identity_mismatch_fields" => event["command_identity_mismatch_fields"],
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "status_transition" => event["status_transition"],
        "transition_type" => event["transition_type"],
        "transition_category" => event["transition_category"],
        "transition_reason" => event["transition_reason"],
        "requires_operator_review" => event["requires_operator_review"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "downlink_demand_feedback"} = event) do
    station = event_ground_station_id(event) || "default"

    [
      %{
        "type" => "downlink_demand_declared",
        "severity" => "medium",
        "reason" =>
          "station #{station} downlink demand #{event["required_downlink_mb"]} MB changes generated contact value",
        "value" => event["required_downlink_mb"],
        "ground_station_id" => event_ground_station_id(event)
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "maneuver_success_feedback"} = event) do
    [
      %{
        "type" => "maneuver_success_rate_low",
        "severity" => "medium",
        "reason" =>
          "maneuver #{event["activity_id"]} success feedback factor #{event["maneuver_success_factor"]} reduces branch confidence",
        "value" => event["maneuver_success_factor"],
        "activity_id" => event["activity_id"],
        "scenario_id" => event["scenario_id"],
        "timeline_id" => event["timeline_id"],
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "maneuver_success_factor" => event["maneuver_success_factor"],
        "maneuver_result" => event["maneuver_result"],
        "realized_status" => event["realized_status"],
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "status_transition" => event["status_transition"],
        "transition_type" => event["transition_type"],
        "transition_category" => event["transition_category"],
        "transition_reason" => event["transition_reason"],
        "requires_operator_review" => event["requires_operator_review"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "maneuver_execution_uncertainty_feedback"} = event) do
    risk_type =
      case event["execution_uncertainty_status"] do
        "missing" -> "maneuver_execution_uncertainty_missing"
        _status -> "maneuver_execution_uncertainty_high"
      end

    reason =
      case event["execution_uncertainty_status"] do
        "missing" ->
          "maneuver #{event["activity_id"]} is missing execution uncertainty for branch refresh"

        _status ->
          "maneuver #{event["activity_id"]} execution uncertainty exceeds branch feedback thresholds"
      end

    [
      %{
        "type" => risk_type,
        "severity" => "medium",
        "reason" => reason,
        "activity_id" => event["activity_id"],
        "timeline_id" => event["timeline_id"],
        "maneuver_id" => event["maneuver_id"],
        "scenario_id" => event["scenario_id"],
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "execution_uncertainty_status" => event["execution_uncertainty_status"],
        "execution_uncertainty_source" => event["execution_uncertainty_source"],
        "execution_uncertainty" => event["execution_uncertainty"],
        "timing_3sigma_s" => event["timing_3sigma_s"],
        "timing_3sigma_threshold_s" => event["timing_3sigma_threshold_s"],
        "delta_v_3sigma_km_s" => event["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => event["delta_v_3sigma_magnitude_km_s"],
        "delta_v_3sigma_magnitude_threshold_km_s" =>
          event["delta_v_3sigma_magnitude_threshold_km_s"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "requires_operator_review" => event["requires_operator_review"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "target_priority_feedback"} = event) do
    [
      %{
        "type" => "target_priority_feedback_high",
        "severity" => "medium",
        "reason" =>
          "target #{event["target_id"]} priority feedback #{event["priority"]} derives a generated observation branch",
        "value" => event["priority"],
        "target_id" => event["target_id"]
      }
      |> compact_map()
    ]
  end

  def indicators(_event), do: []

  defp event_ground_station_id(event) do
    case encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp nested_ground_station_id(activity) do
    Enum.find_value(["ground_station", "station", :ground_station, :station], fn station_key ->
      case Map.get(activity, station_key) do
        %{} = station ->
          Enum.find_value(
            ["ground_station_id", "station_id", "id", :ground_station_id, :station_id, :id],
            fn identity_key -> Map.get(station, identity_key) end
          )

        _station ->
          nil
      end
    end)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
