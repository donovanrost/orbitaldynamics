defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.SchemaValidation.ValidationFields do
  @moduledoc false

  alias __MODULE__.RemediationFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2
    ]

  def fields(reports) do
    %{
      "status_counts" => count_report_field_values(reports, "status"),
      "validated_contract_counts" => count_report_field_values(reports, "validated_contract"),
      "validation_mode_counts" => count_report_field_values(reports, "validation_mode")
    }
    |> Map.merge(RemediationFields.fields(reports))
  end
end
