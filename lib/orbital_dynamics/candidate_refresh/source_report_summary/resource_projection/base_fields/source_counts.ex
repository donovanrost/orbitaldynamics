defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.BaseFields.SourceCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_report_field_values: 2]

  def fields(reports) do
    %{
      "source_artifact_type_counts" =>
        reports
        |> count_report_field_values("source_artifact_type"),
      "source_flow_summary_model_counts" =>
        reports
        |> count_report_field_values("source_flow_summary_model")
    }
  end
end
