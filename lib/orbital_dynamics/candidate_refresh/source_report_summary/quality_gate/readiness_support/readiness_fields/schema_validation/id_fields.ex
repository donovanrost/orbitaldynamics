defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields.SchemaValidation.IdFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def fields(reports) do
    %{
      "schema_validation_status_ids" => string_values(reports, "schema_validation_status_ids"),
      "failed_schema_validation_quality_gate_row_ids" =>
        string_values(reports, "failed_schema_validation_quality_gate_row_ids"),
      "schema_validation_gate_ids" => string_values(reports, "schema_validation_gate_ids")
    }
  end

  defp string_values(reports, field) do
    reports
    |> Enum.flat_map(&RowFallbackValues.string_list(&1, field))
    |> sorted_string_values()
  end
end
