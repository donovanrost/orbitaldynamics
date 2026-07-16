defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.HoldFields.ImportReadiness do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report
  alias __MODULE__.IdMaps

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{
      "reservation_hold_import_readiness_status_counts" =>
        reports
        |> Enum.map(&Report.import_readiness_status_counts/1)
        |> merge_count_maps(),
      "reservation_hold_import_classification_counts" =>
        reports
        |> Enum.map(&Report.import_classification_counts/1)
        |> merge_count_maps(),
      "reservation_hold_ready_for_import_count" =>
        Report.optional_count_sum(reports, "ready_for_import_count"),
      "reservation_hold_review_required_before_import_count" =>
        Report.optional_count_sum(reports, "review_required_before_import_count"),
      "reservation_hold_no_import_required_count" =>
        Report.optional_count_sum(reports, "no_import_required_count"),
      "reservation_hold_import_status_counts" =>
        reports
        |> Enum.map(&Report.hold_import_status_counts/1)
        |> merge_count_maps(),
      "required_import_action_counts" =>
        reports
        |> Enum.map(&Report.hold_required_import_action_counts/1)
        |> merge_count_maps()
    }
    |> Map.merge(IdMaps.fields(reports))
  end
end
