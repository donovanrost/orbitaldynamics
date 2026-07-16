defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields.SchemaValidation.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "schema_validation_pass_count" => row_count(reports, "schema_validation_pass_count"),
      "schema_validation_fail_count" => row_count(reports, "schema_validation_fail_count"),
      "schema_validation_error_count" => row_count(reports, "schema_validation_error_count"),
      "schema_validation_warning_count" => row_count(reports, "schema_validation_warning_count"),
      "schema_validation_remediation_count" =>
        row_count(reports, "schema_validation_remediation_count"),
      "schema_validation_status_counts" => count_map(reports, "schema_validation_status_counts")
    }
  end

  defp row_count(reports, field) do
    sum_report_count(reports, &RowFallbackValues.count(&1, field))
  end

  defp count_map(reports, field) do
    reports
    |> Enum.map(&RowFallbackValues.count_map(&1, field))
    |> merge_count_maps()
  end
end
