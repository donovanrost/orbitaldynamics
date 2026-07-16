defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationPressureFields.ContactIdMaps do
  @moduledoc false

  alias __MODULE__.ValueMaps

  def direction_and_ground_station(summary) do
    nested_string_list_map(
      summary,
      "station_pressure_contact_ids_by_direction_and_ground_station"
    ) ||
      nested_string_list_map(
        summary,
        "station_pressure_contact_ids_by_direction_and_ground_station_id"
      )
  end

  def string_list_map(summary, field) do
    summary
    |> Map.get(field)
    |> ValueMaps.flat()
  end

  defp nested_string_list_map(summary, field) do
    summary
    |> Map.get(field)
    |> ValueMaps.nested()
  end
end
