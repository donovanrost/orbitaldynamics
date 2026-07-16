defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape.SourceContract do
  @moduledoc false

  @summary_schema_contract "timeline_transition_application_summary.v1"

  def summary?(report) do
    (Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")) ==
      @summary_schema_contract
  end
end
