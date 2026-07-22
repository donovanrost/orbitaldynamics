defmodule OrbitalDynamics.CampaignPlanner.EventRiskIndicator.ReviewPressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PressureRiskFields

  def indicators(%{"type" => "provider_reservation_request_pressure"} = event) do
    [
      %{
        "type" => "provider_reservation_request_review",
        "severity" => "high",
        "reason" =>
          "contact #{event["contact_id"] || event["source_activity_id"]} has provider reservation request evidence requiring operator review",
        "contact_id" => event["contact_id"],
        "source_activity_id" => event["source_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "ground_station_id" => event["ground_station_id"],
        "direction" => event["direction"],
        "station_reservation_id" => event["station_reservation_id"],
        "station_calendar_reservation_ids" => event["station_calendar_reservation_ids"],
        "station_reserved_by" => event["station_reserved_by"],
        "station_reservation_match_status" => event["station_reservation_match_status"],
        "station_reservation_status" => event["station_reservation_status"],
        "provider_reservation_request_status" => event["provider_reservation_request_status"],
        "provider_reservation_row_scope" => event["provider_reservation_row_scope"],
        "required_operator_action" => event["required_operator_action"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "trust_boundary" => event["trust_boundary"],
        "assumptions" => event["assumptions"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "provider_counteroffer_pressure"} = event) do
    [
      %{
        "type" => "provider_counteroffer_review",
        "severity" => "high",
        "reason" =>
          "provider counteroffer #{event["provider_counteroffer_id"]} requires operator review before plan impact can be accepted",
        "provider_counteroffer_id" => event["provider_counteroffer_id"],
        "provider_counteroffer_status" => event["provider_counteroffer_status"],
        "provider_counteroffer_negotiation_state" =>
          event["provider_counteroffer_negotiation_state"],
        "provider_counteroffer_reason_code" => event["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => event["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" => event["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_start_delta_s" => event["provider_counteroffer_start_delta_s"],
        "provider_counteroffer_end_delta_s" => event["provider_counteroffer_end_delta_s"],
        "provider_counteroffer_duration_delta_s" =>
          event["provider_counteroffer_duration_delta_s"],
        "plan_impact_status" => event["plan_impact_status"],
        "ground_station_id" => event["ground_station_id"],
        "station_calendar_entry_id" => event["station_calendar_entry_id"],
        "station_calendar_provider_id" => event["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "trust_boundary" => event["trust_boundary"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "candidate_rejection_pressure"} = event) do
    [
      event
      |> Map.take(PressureRiskFields.candidate_rejection())
      |> Map.merge(%{
        "type" => "candidate_rejection_pressure",
        "severity" => "high",
        "reason" =>
          "candidate #{event["candidate_id"]} has rejection evidence requiring operator review"
      })
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "relay_data_path_pressure"} = event) do
    [
      event
      |> Map.take(PressureRiskFields.relay_data_path())
      |> Map.merge(%{
        "type" => "relay_data_path_pressure",
        "severity" => relay_data_path_pressure_severity(event),
        "reason" => relay_data_path_pressure_reason(event)
      })
      |> compact_map()
    ]
  end

  def indicators(_event), do: []

  defp relay_data_path_pressure_severity(event) do
    if event["risk_status"] in ["high", "critical"] or
         event["custody_status"] in ["missing_ack", "missing", "failed"] or
         event["latency_status"] in ["exceeds_limit", "late"] do
      "high"
    else
      "medium"
    end
  end

  defp relay_data_path_pressure_reason(event) do
    [
      if(event["route_id"] not in [nil, ""], do: "relay route #{event["route_id"]}"),
      if(event["ground_station_id"] not in [nil, ""],
        do: "ground station #{event["ground_station_id"]}"
      ),
      if(event["custody_status"] not in [nil, ""], do: "custody #{event["custody_status"]}"),
      if(event["latency_status"] not in [nil, ""], do: "latency #{event["latency_status"]}"),
      if(event["risk_status"] not in [nil, ""], do: "risk #{event["risk_status"]}")
    ]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> "relay data path pressure"
      parts -> Enum.join(parts, "; ")
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
