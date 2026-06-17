defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase
  alias __MODULE__.Flattened

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_safety_case_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "validation_safety_case_summary")

    safety_case_summary =
      branch_safety_case_summary ||
        Map.get(source_reports, "validation_safety_case_summary", %{})

    pressure_fields = ValidationSafetyCase.pressure_fields(safety_case_summary)

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
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
