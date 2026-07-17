defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary

  def replay(refresh_or_artifact) do
    source_reports =
      refresh_or_artifact
      |> SourceReportSummary.build()
      |> Map.get("source_reports", %{})

    summary(source_reports)
  end

  def summary(source_reports) do
    Summary.summary(source_reports)
  end
end
