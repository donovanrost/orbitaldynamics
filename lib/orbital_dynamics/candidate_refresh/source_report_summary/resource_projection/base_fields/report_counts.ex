defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.BaseFields.ReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.BaseFields.Counts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &Counts.row_count/1),
      "projected_resource_count" =>
        sum_report_count(
          reports,
          &Counts.projected_resource_count/1
        )
    }
  end
end
