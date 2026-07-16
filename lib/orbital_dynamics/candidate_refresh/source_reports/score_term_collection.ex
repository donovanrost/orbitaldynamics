defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTerm
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollectionArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollectionDirectReports

  def score_term_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ScoreTermCollectionDirectReports.reports()
    |> Kernel.++(
      ScoreTermCollectionArtifactReports.score_term_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ScoreTerm.report?(report) end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  defp stringify_keys(value), do: ScoreTermCollectionArtifactReports.stringify_keys(value)
end
