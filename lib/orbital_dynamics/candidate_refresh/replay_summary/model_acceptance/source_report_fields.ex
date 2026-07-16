defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.Summary

  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_summary_fields(refresh_or_artifact, source_reports) do
    branch_model_acceptance_summary = source_report_summary_branch_family(refresh_or_artifact)

    model_acceptance_summary =
      branch_model_acceptance_summary || Map.get(source_reports, "model_acceptance_report", %{})

    source_report_fields(source_reports, Summary.pressure_fields(model_acceptance_summary))
  end

  def source_report_fields(source_reports, pressure_fields) do
    pressure_fields
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.fields(source_reports))
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "model_acceptance_report",
      &InputProvenance.build/1
    )
  end
end
