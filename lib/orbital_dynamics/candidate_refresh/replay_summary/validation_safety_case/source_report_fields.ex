defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.Summary

  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_summary_fields(refresh_or_artifact, source_reports) do
    branch_safety_case_summary = source_report_summary_branch_family(refresh_or_artifact)

    safety_case_summary =
      branch_safety_case_summary ||
        Map.get(source_reports, "validation_safety_case_summary", %{})

    safety_case_summary
    |> Summary.pressure_fields()
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "validation_safety_case_summary",
      &InputProvenance.build/1
    )
  end
end
