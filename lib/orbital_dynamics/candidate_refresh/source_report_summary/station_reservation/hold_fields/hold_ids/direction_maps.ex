defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.HoldFields.HoldIds.DirectionMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    %{
      "reservation_hold_ids_by_direction" =>
        string_list_map(reports, &Report.hold_ids_by_direction/1),
      "reservation_hold_contact_ids_by_direction" =>
        string_list_map(reports, &Report.hold_contact_ids_by_direction/1)
    }
  end

  defp string_list_map(reports, fun) do
    reports
    |> Enum.map(fun)
    |> merge_string_list_maps()
  end
end
