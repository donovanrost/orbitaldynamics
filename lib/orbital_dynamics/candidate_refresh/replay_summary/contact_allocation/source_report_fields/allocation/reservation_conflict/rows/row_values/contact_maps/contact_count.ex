defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.ReservationConflict.Rows.RowValues.ContactMaps.ContactCount do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent

  @contact_id_fields ["reservation_conflict_contact_ids"]

  @flat_contact_id_map_fields [
    "reservation_conflict_contact_ids_by_match_status",
    "reservation_conflict_contact_ids_by_direction"
  ]

  @nested_contact_id_map_fields [
    "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
    "reservation_conflict_contact_ids_by_direction_and_ground_station"
  ]

  def fallback_contact_count(report) do
    unique_contact_count(
      report,
      @contact_id_fields,
      @flat_contact_id_map_fields,
      @nested_contact_id_map_fields,
      "reservation_conflict_contact_count"
    )
  end

  defp unique_contact_count(report, list_fields, flat_fields, nested_fields, fallback_field) do
    contact_id_lists = present_values(report, list_fields)
    flat_contact_id_maps = present_values(report, flat_fields)
    nested_contact_id_maps = present_values(report, nested_fields)

    if contact_id_lists != [] or flat_contact_id_maps != [] or nested_contact_id_maps != [] do
      contact_id_lists
      |> Enum.flat_map(&list_value/1)
      |> Kernel.++(flat_contact_ids(flat_contact_id_maps))
      |> Kernel.++(nested_contact_ids(nested_contact_id_maps))
      |> ContactIntent.count_unique_contact_ids()
    else
      Common.numeric_report_count(report, fallback_field)
    end
  end

  defp present_values(report, fields) do
    fields
    |> Enum.filter(&Map.has_key?(report, &1))
    |> Enum.map(&Map.get(report, &1))
  end

  defp flat_contact_ids(contact_id_maps) do
    Enum.flat_map(contact_id_maps, &ContactIntent.string_list_map_contact_ids/1)
  end

  defp nested_contact_ids(contact_id_maps) do
    Enum.flat_map(contact_id_maps, &ContactIntent.nested_string_list_map_contact_ids/1)
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
