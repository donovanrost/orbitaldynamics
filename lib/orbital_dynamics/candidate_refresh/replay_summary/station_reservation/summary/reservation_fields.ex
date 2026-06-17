defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary.ReservationFields do
  @moduledoc false

  def fields(reservation_summary) do
    %{
      "affected_contact_ids" => Map.get(reservation_summary, "affected_contact_ids", []),
      "contact_ids_by_match_status" =>
        Map.get(reservation_summary, "contact_ids_by_match_status", %{}),
      "contact_ids_by_status" => Map.get(reservation_summary, "contact_ids_by_status", %{}),
      "direction_counts" => Map.get(reservation_summary, "direction_counts", %{}),
      "contact_ids_by_direction" => Map.get(reservation_summary, "contact_ids_by_direction", %{}),
      "direction_routing" => Map.get(reservation_summary, "direction_routing", %{}),
      "source_summary_model_counts" =>
        reservation_summary
        |> Map.get("source_summary_model_counts", %{})
        |> non_empty_map(),
      "source_summary_schema_contract_counts" =>
        reservation_summary
        |> Map.get("source_summary_schema_contract_counts", %{})
        |> non_empty_map(),
      "source_artifact_type_counts" =>
        reservation_summary
        |> Map.get("source_artifact_type_counts", %{})
        |> non_empty_map(),
      "reservation_expires_at_s" => Map.get(reservation_summary, "reservation_expires_at_s", []),
      "earliest_reservation_expires_at_s" =>
        numeric_value(Map.get(reservation_summary, "earliest_reservation_expires_at_s")),
      "station_reservation_match_status_counts" =>
        Map.get(reservation_summary, "station_reservation_match_status_counts", %{}),
      "reservation_status_counts" =>
        Map.get(reservation_summary, "reservation_status_counts", %{}),
      "reservation_ids" => Map.get(reservation_summary, "reservation_ids", []),
      "reservation_ids_by_match_status" =>
        Map.get(reservation_summary, "reservation_ids_by_match_status", %{}),
      "reservation_ids_by_status" =>
        Map.get(reservation_summary, "reservation_ids_by_status", %{}),
      "reserved_by_counts" => Map.get(reservation_summary, "reserved_by_counts", %{}),
      "contact_ids_by_reserved_by" =>
        Map.get(reservation_summary, "contact_ids_by_reserved_by", %{}),
      "reservation_ids_by_reserved_by" =>
        Map.get(reservation_summary, "reservation_ids_by_reserved_by", %{})
    }
  end

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
