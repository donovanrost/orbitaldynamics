defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.CountFields do
  @moduledoc false

  alias __MODULE__.{CountMapFields, ScalarCounts}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &row_count/1),
      "timeline_integrity_review_count" => sum_report_count(reports, &review_count/1)
    }
    |> Map.merge(CountMapFields.fields(reports))
  end

  defp row_count(report) do
    ScalarCounts.row_count(report)
  end

  defp review_count(report) do
    ScalarCounts.review_count(report)
  end
end
