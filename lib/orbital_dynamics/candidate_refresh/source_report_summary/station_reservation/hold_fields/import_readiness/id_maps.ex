defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.HoldFields.ImportReadiness.IdMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    %{
      "reservation_hold_ids_by_import_status" =>
        reports
        |> Enum.map(&Report.hold_ids_by_import_status/1)
        |> merge_string_list_maps(),
      "reservation_hold_ids_by_required_import_action" =>
        reports
        |> Enum.map(&Report.hold_ids_by_required_import_action/1)
        |> merge_string_list_maps(),
      "reservation_hold_contact_ids_by_import_status" =>
        reports
        |> Enum.map(&Report.hold_contact_ids_by_import_status/1)
        |> merge_string_list_maps()
    }
  end
end
