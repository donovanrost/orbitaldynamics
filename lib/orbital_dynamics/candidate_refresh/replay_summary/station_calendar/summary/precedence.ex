defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary.Precedence do
  @moduledoc false

  def fields(station_summary) do
    %{
      "precedence_review_status_counts" =>
        station_summary
        |> Map.get("precedence_review_status_counts", %{})
        |> non_empty_map(),
      "applied_availability_counts" =>
        station_summary
        |> Map.get("applied_availability_counts", %{})
        |> non_empty_map(),
      "overlap_availability_counts" =>
        station_summary
        |> Map.get("overlap_availability_counts", %{})
        |> non_empty_map(),
      "affected_contact_ids_by_applied_availability" =>
        station_summary
        |> Map.get("affected_contact_ids_by_applied_availability", %{})
        |> non_empty_map(),
      "affected_contact_ids_by_overlap_availability" =>
        station_summary
        |> Map.get("affected_contact_ids_by_overlap_availability", %{})
        |> non_empty_map(),
      "reserved_under_higher_precedence_contact_count" =>
        count_or_nil(station_summary, "reserved_under_higher_precedence_contact_count"),
      "reserved_under_higher_precedence_contact_ids" =>
        station_summary
        |> Map.get("reserved_under_higher_precedence_contact_ids", [])
        |> non_empty_list(),
      "reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
        station_summary
        |> Map.get("reserved_under_higher_precedence_contact_ids_by_applied_availability", %{})
        |> non_empty_map(),
      "reserved_under_higher_precedence_reservation_ids" =>
        station_summary
        |> Map.get("reserved_under_higher_precedence_reservation_ids", [])
        |> non_empty_list(),
      "reserved_under_higher_precedence_reservation_ids_by_status" =>
        station_summary
        |> Map.get("reserved_under_higher_precedence_reservation_ids_by_status", %{})
        |> non_empty_map(),
      "reserved_under_higher_precedence_reservation_ids_by_reserved_by" =>
        station_summary
        |> Map.get("reserved_under_higher_precedence_reservation_ids_by_reserved_by", %{})
        |> non_empty_map(),
      "reserved_under_higher_precedence_contact_ids_by_reservation_status" =>
        station_summary
        |> Map.get("reserved_under_higher_precedence_contact_ids_by_reservation_status", %{})
        |> non_empty_map(),
      "reserved_under_higher_precedence_contact_ids_by_reserved_by" =>
        station_summary
        |> Map.get("reserved_under_higher_precedence_contact_ids_by_reserved_by", %{})
        |> non_empty_map()
    }
  end

  def pressure?(replay) do
    replay
    |> Map.values()
    |> Enum.any?(&present?/1)
  end

  defp present?(value) when is_map(value), do: map_size(value) > 0
  defp present?(value) when is_list(value), do: value != []
  defp present?(value) when is_integer(value), do: value > 0
  defp present?(nil), do: false
  defp present?(_value), do: true

  defp count_or_nil(station_summary, field) do
    case summary_integer(station_summary, field) do
      count when count > 0 -> count
      _count -> nil
    end
  end

  defp non_empty_list([]), do: nil
  defp non_empty_list(list), do: list

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0
end
