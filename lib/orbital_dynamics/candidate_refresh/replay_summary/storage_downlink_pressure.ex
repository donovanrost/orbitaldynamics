defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    source_reports =
      refresh_or_artifact
      |> source_report_summary.()
      |> Map.get("source_reports", %{})

    summary(source_reports)
  end

  def summary(source_reports) do
    Summary.summary(source_reports)
  end
end
