defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedback do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackReportValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackResultArtifactReports

  def entries(path, value) do
    EntryFallbacks.map_entry(path, value, fn entry_path, entry_value ->
      report = TimelineFeedbackReportValues.stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def result_artifact_entries(path, artifact) do
    EntryFallbacks.map_entry(path, artifact, fn entry_path, entry_artifact ->
      TimelineFeedbackResultArtifactReports.entries(entry_path, entry_artifact)
    end)
  end

  def report?(%{} = report),
    do: is_list(Map.get(report, "rows") || Map.get(report, :rows))

  def report?(_report), do: false
end
