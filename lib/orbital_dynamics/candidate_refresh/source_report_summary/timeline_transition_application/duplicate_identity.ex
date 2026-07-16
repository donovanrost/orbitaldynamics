defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.DuplicateIdentity do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "duplicate_timeline_identity_count" =>
        sum_report_count(reports, &ReportValues.duplicate_timeline_identity_count/1),
      "duplicate_source_timeline_identity_count" =>
        sum_report_count(reports, &ReportValues.duplicate_source_timeline_identity_count/1),
      "duplicate_replacement_timeline_identity_count" =>
        sum_report_count(reports, &ReportValues.duplicate_replacement_timeline_identity_count/1),
      "duplicate_timeline_identity_scope_counts" =>
        reports
        |> Enum.map(&ReportValues.duplicate_identity_scope_counts/1)
        |> merge_count_maps()
    }
  end
end
