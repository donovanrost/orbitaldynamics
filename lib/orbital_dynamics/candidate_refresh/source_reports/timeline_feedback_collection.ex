defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackCollectionDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackCollectionEncoding

  def reports(refresh, source_result_artifacts_fun) do
    refresh
    |> TimelineFeedbackCollectionDirectReports.reports()
    |> Kernel.++(result_artifact_reports(refresh, source_result_artifacts_fun))
    |> Enum.flat_map(fn {path, report} -> TimelineFeedback.entries(path, report) end)
    |> Enum.map(fn {path, report} ->
      {path, TimelineFeedbackCollectionEncoding.stringify_keys(report)}
    end)
  end

  defp result_artifact_reports(refresh, source_result_artifacts_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      TimelineFeedback.result_artifact_entries(path, artifact)
    end)
  end
end
