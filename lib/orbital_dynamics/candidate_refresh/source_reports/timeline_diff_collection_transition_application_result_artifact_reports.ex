defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionTransitionApplicationResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiff

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionTransitionApplicationEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplication

  def reports(refresh, source_result_artifacts_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.timeline_transition_application_report",
         Map.get(artifact, "timeline_transition_application_report")}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        TimelineTransitionApplication.timeline_diff_entries(
          entry_path,
          report,
          &TimelineDiff.row_from_review_or_import_row/1
        )
      end)
    end)
  end

  defp stringify_keys(value),
    do: TimelineDiffCollectionTransitionApplicationEncoding.stringify_keys(value)
end
