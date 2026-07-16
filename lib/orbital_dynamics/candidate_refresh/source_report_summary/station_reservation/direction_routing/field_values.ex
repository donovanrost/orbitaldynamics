defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting.FieldValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def from(reports, hold_summary) do
    %{
      direction_counts: count_map(reports, &Report.direction_counts/1),
      contact_ids_by_direction: string_list_map(reports, &Report.contact_ids_by_direction/1),
      reservation_hold_ids_by_direction:
        Map.get(hold_summary, "reservation_hold_ids_by_direction", %{}),
      reservation_hold_contact_ids_by_direction:
        Map.get(hold_summary, "reservation_hold_contact_ids_by_direction", %{})
    }
  end

  defp count_map(reports, fun) do
    reports
    |> Enum.map(fun)
    |> merge_count_maps()
  end

  defp string_list_map(reports, fun) do
    reports
    |> Enum.map(fun)
    |> merge_string_list_maps()
  end
end
