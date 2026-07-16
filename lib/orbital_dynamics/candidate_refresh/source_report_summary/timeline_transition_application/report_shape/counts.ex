defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape.Counts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape.Applications
  alias __MODULE__.FirstCount

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def source_row_count(report, true) do
    FirstCount.value(report, [
      "source_report_row_count",
      "row_count",
      "application_count"
    ])
  end

  def source_row_count(report, false) do
    Applications.row_count_or(report, fn ->
      FirstCount.value(report, [
        "row_count",
        "application_count"
      ])
    end)
  end

  def application_count(report, true) do
    numeric_report_count(report, "application_count")
  end

  def application_count(report, false) do
    Applications.row_count_or(report, fn ->
      numeric_report_count(report, "application_count")
    end)
  end
end
