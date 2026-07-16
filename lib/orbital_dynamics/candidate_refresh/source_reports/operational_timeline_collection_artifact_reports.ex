defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimeline

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionArtifactEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionReviewReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    result_artifact_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    ) ++
      OperationalTimelineCollectionReviewReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      OperationalTimelineCollectionReviewReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end

  defp result_artifact_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun
       ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = OperationalTimelineCollectionArtifactEncoding.stringify_keys(artifact)

      exact = OperationalTimeline.entries(path, artifact)

      nested =
        [
          {"#{path}.source_operational_timeline_report",
           Map.get(artifact, "source_operational_timeline_report")},
          {"#{path}.operational_timeline_report",
           Map.get(artifact, "operational_timeline_report")}
        ]
        |> Enum.flat_map(fn {entry_path, report} ->
          OperationalTimeline.entries(
            entry_path,
            inherit_result_artifact_trust_boundary_fun.(report, artifact)
          )
        end)

      exact ++ nested
    end)
  end
end
