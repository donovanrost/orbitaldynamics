defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationPressureFields.ContactIdFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationPressureFields.ContactIdMaps

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def fields(summary) do
    %{
      "station_pressure_contact_ids" =>
        sorted_strings_if_present(summary, "station_pressure_contact_ids"),
      "station_pressure_contact_ids_by_ground_station_id" =>
        ContactIdMaps.string_list_map(
          summary,
          "station_pressure_contact_ids_by_ground_station_id"
        ),
      "station_pressure_contact_ids_by_ground_station" =>
        ContactIdMaps.string_list_map(summary, "station_pressure_contact_ids_by_ground_station"),
      "station_pressure_contact_ids_by_availability" =>
        ContactIdMaps.string_list_map(summary, "station_pressure_contact_ids_by_availability"),
      "station_pressure_contact_ids_by_precedence_availability" =>
        ContactIdMaps.string_list_map(
          summary,
          "station_pressure_contact_ids_by_precedence_availability"
        ),
      "station_pressure_contact_ids_by_precedence_rank" =>
        ContactIdMaps.string_list_map(summary, "station_pressure_contact_ids_by_precedence_rank"),
      "station_pressure_contact_ids_by_status" =>
        ContactIdMaps.string_list_map(summary, "station_pressure_contact_ids_by_status"),
      "station_pressure_contact_ids_by_direction" =>
        ContactIdMaps.string_list_map(summary, "station_pressure_contact_ids_by_direction"),
      "station_pressure_contact_ids_by_direction_and_ground_station" =>
        ContactIdMaps.direction_and_ground_station(summary)
    }
  end

  defp sorted_strings_if_present(summary, field) do
    if Map.has_key?(summary, field) do
      summary
      |> Map.get(field)
      |> sorted_string_values()
    end
  end
end
