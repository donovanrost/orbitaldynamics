defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateDiff
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeValueEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateRejection

  def candidate_diff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> CandidateOutcomeDirectReports.candidate_diff_reports()
    |> Kernel.++(
      CandidateOutcomeArtifactReports.candidate_diff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> CandidateDiff.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, CandidateOutcomeValueEncoding.stringify_keys(report)}
    end)
  end

  def candidate_rejection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> CandidateOutcomeDirectReports.candidate_rejection_reports()
    |> Kernel.++(
      CandidateOutcomeArtifactReports.candidate_rejection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> CandidateRejection.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, CandidateOutcomeValueEncoding.stringify_keys(report)}
    end)
  end
end
