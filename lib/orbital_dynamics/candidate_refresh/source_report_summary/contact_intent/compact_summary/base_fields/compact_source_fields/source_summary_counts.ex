defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.CompactSourceFields.SourceSummaryCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2
    ]

  def fields(summaries) do
    %{
      "source_summary_model_counts" => count_report_field_values(summaries, "model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(summaries, "schema_contract"),
      "source_artifact_type_counts" =>
        count_report_field_values(summaries, "source_artifact_type")
    }
  end
end
