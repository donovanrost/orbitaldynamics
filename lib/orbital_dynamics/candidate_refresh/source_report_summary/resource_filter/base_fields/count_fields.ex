defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.BaseFields.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.BaseFields.InvalidInputs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2,
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type"),
      "row_count" => sum_report_count(reports, &row_count/1),
      "suppressed_candidate_count" => sum_report_count(reports, &suppressed_candidate_count/1)
    }
  end

  defp row_count(report) do
    suppressed_candidate_count(report) +
      InvalidInputs.invalid_resource_summary_input_count(report)
  end

  defp suppressed_candidate_count(report) do
    report
    |> numeric_report_count("suppressed_candidate_count")
    |> case do
      0 -> length(Map.get(report, "suppressed_candidates", []))
      count -> count
    end
  end
end
