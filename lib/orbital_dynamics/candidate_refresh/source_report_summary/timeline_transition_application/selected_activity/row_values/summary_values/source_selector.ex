defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues.SummaryValues.SourceSelector do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  def value(report, summary_source_extractor, report_extractor) do
    case ReportShape.summary_source?(report) do
      true -> summary_source_extractor.(report)
      false -> report_extractor.(report)
    end
  end
end
