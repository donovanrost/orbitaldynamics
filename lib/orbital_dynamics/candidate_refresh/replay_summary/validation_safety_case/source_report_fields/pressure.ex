defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(pressure_fields) do
    %{
      "source_report_validation_safety_case_branch_local_review_pressure" =>
        Map.get(pressure_fields, "branch_local_review_pressure"),
      "source_report_validation_safety_case_branch_local_blocking_pressure" =>
        Map.get(pressure_fields, "branch_local_blocking_pressure"),
      "source_report_validation_safety_case_branch_local_schema_pressure" =>
        Map.get(pressure_fields, "branch_local_schema_pressure"),
      "source_report_validation_safety_case_branch_local_fixture_pressure" =>
        Map.get(pressure_fields, "branch_local_fixture_pressure")
    }
  end
end
