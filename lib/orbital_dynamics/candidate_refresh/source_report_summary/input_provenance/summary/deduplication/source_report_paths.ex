defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication.SourceReportPaths do
  @moduledoc false

  alias __MODULE__.ResultArtifactPaths

  def direct_source_report?("mission_state." <> rest) do
    not String.starts_with?(rest, "source_result_artifact.") and
      not String.starts_with?(rest, "result_artifact.")
  end

  def direct_source_report?(_path), do: false

  def result_artifact_source_report?(path, report_keys) do
    ResultArtifactPaths.source_report?(path, report_keys)
  end
end
