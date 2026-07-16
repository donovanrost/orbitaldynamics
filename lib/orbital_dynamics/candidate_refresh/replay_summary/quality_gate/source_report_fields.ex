defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Core
  alias __MODULE__.Pressure
  alias __MODULE__.ResourceAvailability
  import __MODULE__.Aggregation, only: [compact_map: 1]

  def source_report_summary_fields(refresh_or_artifact, source_reports) do
    branch_quality_gate_summary = source_report_summary_branch_family(refresh_or_artifact)

    quality_gate_summary =
      branch_quality_gate_summary || Map.get(source_reports, "quality_gate_report", %{})

    quality_gate_summary
    |> Pressure.source_report_fields()
    |> Map.merge(source_report_fields(source_reports))
  end

  def source_report_fields(source_reports) do
    source_reports
    |> Core.fields()
    |> Map.merge(ResourceAvailability.fields(source_reports))
    |> compact_map()
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "quality_gate_report",
      &InputProvenance.build/1
    )
  end
end
