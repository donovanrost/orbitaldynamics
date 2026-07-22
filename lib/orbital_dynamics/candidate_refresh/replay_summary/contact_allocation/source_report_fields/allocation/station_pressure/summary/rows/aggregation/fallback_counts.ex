defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows.Aggregation.FallbackCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent

  import Common, only: [numeric_report_count: 2]

  def fallback_contact_count(report) do
    report
    |> unique_contact_count(
      ["station_pressure_contact_ids"],
      [
        "station_pressure_contact_ids_by_ground_station_id",
        "station_pressure_contact_ids_by_ground_station",
        "station_pressure_contact_ids_by_availability",
        "station_pressure_contact_ids_by_precedence_availability",
        "station_pressure_contact_ids_by_precedence_rank",
        "station_pressure_contact_ids_by_status",
        "station_pressure_contact_ids_by_direction"
      ],
      [
        "station_pressure_contact_ids_by_direction_and_ground_station_id",
        "station_pressure_contact_ids_by_direction_and_ground_station"
      ],
      "station_pressure_contact_count"
    )
  end

  def fallback_review_contact_count(report) do
    if Map.has_key?(report, "station_pressure_review_contact_ids") do
      report
      |> Map.get("station_pressure_review_contact_ids")
      |> list_value()
      |> ContactIntent.count_unique_contact_ids()
    else
      numeric_report_count(report, "station_pressure_review_contact_count")
    end
  end

  defp unique_contact_count(report, list_fields, flat_fields, nested_fields, fallback_field) do
    contact_id_lists =
      list_fields
      |> Enum.map(&Map.get(report, &1))
      |> Enum.filter(&is_list/1)

    flat_contact_id_maps =
      flat_fields
      |> Enum.map(&Map.get(report, &1))
      |> Enum.filter(&is_map/1)

    nested_contact_id_maps =
      nested_fields
      |> Enum.map(&Map.get(report, &1))
      |> Enum.filter(&is_map/1)

    cond do
      contact_id_lists != [] or flat_contact_id_maps != [] or nested_contact_id_maps != [] ->
        direct_contact_ids = List.flatten(contact_id_lists)

        flat_contact_ids =
          flat_contact_id_maps
          |> Enum.flat_map(&ContactIntent.string_list_map_contact_ids/1)

        nested_contact_ids =
          nested_contact_id_maps
          |> Enum.flat_map(&ContactIntent.nested_string_list_map_contact_ids/1)

        direct_contact_ids
        |> Kernel.++(flat_contact_ids)
        |> Kernel.++(nested_contact_ids)
        |> ContactIntent.count_unique_contact_ids()

      true ->
        numeric_report_count(report, fallback_field)
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
