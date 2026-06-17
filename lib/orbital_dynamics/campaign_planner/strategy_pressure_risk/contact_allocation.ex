defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.ContactAllocation do
  @moduledoc false

  def contact_allocation_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &contact_allocation_pressure_risk?/1)
  end

  def contact_allocation_pressure_risk?(%{"type" => "downlink_completion_gap"} = risk) do
    not station_reservation_conflict_pressure_risk?(risk) and
      (risk["feedback_scope"] == "contact_allocation" or
         risk["feedback_scope"] == "contact_allocation_provider_reservation_request" or
         Enum.any?(List.wrap(risk["derivation_reasons"]), fn reason ->
           reason
           |> to_string()
           |> String.starts_with?("contact_allocation")
         end))
  end

  def contact_allocation_pressure_risk?(_risk), do: false

  def provider_reservation_request_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &provider_reservation_request_pressure_risk?/1)
  end

  def station_reservation_conflict_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &station_reservation_conflict_pressure_risk?/1)
  end

  defp provider_reservation_request_pressure_risk?(%{
         "type" => "provider_reservation_request_review"
       }),
       do: true

  defp provider_reservation_request_pressure_risk?(_risk), do: false

  defp station_reservation_conflict_pressure_risk?(%{"type" => "downlink_completion_gap"} = risk) do
    risk["feedback_scope"] == "contact_allocation" and
      station_reservation_conflict_evidence?(risk)
  end

  defp station_reservation_conflict_pressure_risk?(_risk), do: false

  defp station_reservation_conflict_evidence?(risk) do
    station_reservation_conflict_match_status?(risk["station_reservation_match_status"]) or
      Enum.any?(List.wrap(risk["derivation_reasons"]), fn reason ->
        reason == "contact_allocation_reservation_conflict"
      end) or
      reservation_conflict_source?(risk["feedback_source"])
  end

  defp reservation_conflict_source?(source) when is_binary(source) do
    String.contains?(source, "reservation_conflict_summary")
  end

  defp reservation_conflict_source?(_source), do: false

  defp station_reservation_conflict_match_status?(status) do
    status
    |> normalized_status_token()
    |> case do
      nil -> false
      "" -> false
      "matched" -> false
      "owner_matched" -> false
      "owned" -> false
      "owner" -> false
      _status -> true
    end
  end

  defp normalized_status_token(nil), do: nil

  defp normalized_status_token(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> normalized_status_token()
  end

  defp normalized_status_token(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
  end

  defp normalized_status_token(status), do: status
end
