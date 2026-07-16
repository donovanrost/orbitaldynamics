defmodule OrbitalDynamics.OperatorReview.RiskReview do
  @moduledoc false

  def rows(risks, source) do
    risks
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {risk, index} ->
      risk_type = Map.get(risk, "type", "risk")

      %{
        "id" => review_id(["risk", source, risk_type, index]),
        "review_type" => "risk_explanation",
        "source" => source,
        "subject_id" => risk_type,
        "action" => "review_risk",
        "required_operator_action" => "review_risk",
        "approval_status" => "operator_review_required",
        "risk_type" => risk_type,
        "severity" => Map.get(risk, "severity"),
        "reason" => Map.get(risk, "reason", risk_type),
        "value" => Map.get(risk, "value"),
        "branch_id" => risk["branch_id"],
        "scenario_id" => risk["scenario_id"],
        "activity_id" => risk["activity_id"] || risk["first_resource_pressure_activity_id"],
        "activity_type" => risk["activity_type"] || risk["first_resource_pressure_activity_type"],
        "ground_station_id" =>
          risk["ground_station_id"] || risk["first_resource_pressure_ground_station_id"],
        "spacecraft_id" => risk["spacecraft_id"],
        "target_id" => risk["target_id"],
        "collection_id" => risk["collection_id"],
        "product_id" => risk["product_id"],
        "product_ids" => risk["product_ids"],
        "payload_id" => risk["payload_id"],
        "instrument_id" => risk["instrument_id"],
        "objective_id" => risk["objective_id"],
        "objective_type" => risk["objective_type"],
        "objective_status" => risk["objective_status"],
        "source_objective_status" => risk["source_objective_status"],
        "latency_objective" => risk["latency_objective"],
        "max_latency_s" => risk["max_latency_s"],
        "planned_latency_s" => risk["planned_latency_s"],
        "required_contacts" => risk["required_contacts"],
        "planned_contacts" => risk["planned_contacts"],
        "required_downlink_mb" => risk["required_downlink_mb"],
        "planned_downlink_mb" => risk["planned_downlink_mb"],
        "contact_result" => risk["contact_result"],
        "realized_status" => risk["realized_status"],
        "source_activity_id" => risk["source_activity_id"],
        "source_activity_ids" => risk["source_activity_ids"],
        "missed_downlink_activity_id" => risk["missed_downlink_activity_id"],
        "missed_downlink_activity_ids" => risk["missed_downlink_activity_ids"],
        "feedback_source" => risk["feedback_source"],
        "feedback_scope" => risk["feedback_scope"],
        "trust_boundary" => risk["trust_boundary"],
        "derivation_reasons" => risk["derivation_reasons"],
        "direction" => risk["direction"] || risk["first_resource_pressure_direction"],
        "station_calendar_entry_id" =>
          risk["station_calendar_entry_id"] ||
            risk["first_resource_pressure_station_calendar_entry_id"],
        "station_calendar_provider_id" =>
          risk["station_calendar_provider_id"] ||
            risk["first_resource_pressure_station_calendar_provider_id"],
        "station_calendar_provider_entry_id" =>
          risk["station_calendar_provider_entry_id"] ||
            risk["first_resource_pressure_station_calendar_provider_entry_id"],
        "station_calendar_directions" =>
          risk["station_calendar_directions"] ||
            risk["first_resource_pressure_station_calendar_directions"],
        "first_resource_pressure_activity_id" => risk["first_resource_pressure_activity_id"],
        "first_resource_pressure_activity_type" => risk["first_resource_pressure_activity_type"],
        "first_resource_pressure_kind" => risk["first_resource_pressure_kind"],
        "first_resource_pressure_starts_at_s" => risk["first_resource_pressure_starts_at_s"],
        "first_resource_pressure_direction" => risk["first_resource_pressure_direction"],
        "first_resource_pressure_ground_station_id" =>
          risk["first_resource_pressure_ground_station_id"],
        "first_resource_pressure_station_calendar_entry_id" =>
          risk["first_resource_pressure_station_calendar_entry_id"],
        "first_resource_pressure_station_calendar_provider_id" =>
          risk["first_resource_pressure_station_calendar_provider_id"],
        "first_resource_pressure_station_calendar_provider_entry_id" =>
          risk["first_resource_pressure_station_calendar_provider_entry_id"],
        "first_resource_pressure_station_calendar_directions" =>
          risk["first_resource_pressure_station_calendar_directions"],
        "first_resource_pressure_capacity_fraction" =>
          risk["first_resource_pressure_capacity_fraction"],
        "first_resource_pressure_source_window_id" =>
          risk["first_resource_pressure_source_window_id"],
        "first_resource_pressure_source_window_type" =>
          risk["first_resource_pressure_source_window_type"],
        "first_resource_pressure_source_window" => risk["first_resource_pressure_source_window"],
        "source_window_id" =>
          risk["source_window_id"] || risk["first_resource_pressure_source_window_id"],
        "source_window_type" =>
          risk["source_window_type"] || risk["first_resource_pressure_source_window_type"],
        "source_window" => risk["source_window"] || risk["first_resource_pressure_source_window"],
        "source_risk" => risk
      }
      |> compact_map()
    end)
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
