defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.SourceFields.SuppressedReasons do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1, merge_string_list_maps: 1]

  def fields(reports) do
    %{
      "suppressed_reason_counts" =>
        reports
        |> Enum.map(&Report.suppressed_reason_counts/1)
        |> merge_count_maps(),
      "contact_ids_by_suppressed_reason" =>
        reports
        |> Enum.map(&Report.contact_ids_by_suppressed_reason/1)
        |> merge_string_list_maps()
    }
  end
end
