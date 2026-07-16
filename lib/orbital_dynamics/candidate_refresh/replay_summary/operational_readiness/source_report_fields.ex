defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_summary_fields(refresh_or_artifact, source_reports) do
    branch_readiness_summary = source_report_summary_branch_family(refresh_or_artifact)

    readiness_summary =
      branch_readiness_summary || Map.get(source_reports, "operational_readiness_report", %{})

    readiness_summary
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "operational_readiness_report",
      &InputProvenance.build/1
    )
  end
end
