defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.SourceFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.SourceReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(RowMetrics.fields(reports))
    |> compact_map()
  end

  def timeline_feedback_report_source(report), do: SourceReport.source(report)
end
