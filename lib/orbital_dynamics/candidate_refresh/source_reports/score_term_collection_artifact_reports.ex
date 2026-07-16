defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTerm
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollectionArtifactEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollectionReviewArtifactReports

  def score_term_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    result_artifact_score_term_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    ) ++
      ScoreTermCollectionReviewArtifactReports.operator_review_score_term_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      ScoreTermCollectionReviewArtifactReports.cadence_import_score_term_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end

  defp result_artifact_score_term_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun
       ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.source_score_term_report", Map.get(artifact, "source_score_term_report")},
        {"#{path}.score_term_report", Map.get(artifact, "score_term_report")}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        ScoreTerm.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  def stringify_keys(value), do: ScoreTermCollectionArtifactEncoding.stringify_keys(value)
end
