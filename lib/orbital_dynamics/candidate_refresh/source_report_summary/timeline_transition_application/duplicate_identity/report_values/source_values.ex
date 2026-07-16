defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.DuplicateIdentity.ReportValues.SourceValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def count(report, field, fallback) do
    source_value(report, fn
      report, true -> numeric_report_count(report, field)
      report, false -> fallback.(report, field)
    end)
  end

  def map(report, field, fallback) do
    source_value(report, fn
      report, true -> Map.get(report, field)
      report, false -> fallback.(report, field)
    end)
  end

  defp source_value(report, extractor) do
    extractor.(report, ReportShape.summary_source?(report))
  end
end
