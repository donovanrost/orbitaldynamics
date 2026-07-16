defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendar
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReviewArtifactDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReviewArtifactEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        source_key,
        artifact_key
      ) do
    StationScheduleReviewArtifactDirectReports.reports(refresh, builder, source_key, artifact_key) ++
      embedded_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        artifact_key
      )
  end

  defp embedded_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         builder,
         artifact_key
       ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = StationScheduleReviewArtifactEncoding.stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.#{artifact_key}", Map.get(artifact, artifact_key)}
      ]
      |> Enum.flat_map(fn {entry_path, nested_artifact} ->
        StationCalendar.build_entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(nested_artifact, artifact),
          builder
        )
      end)
    end)
  end
end
