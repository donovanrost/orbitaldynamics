defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewArtifactHelpers
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewImportReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewPackageReports

  def result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module,
        source_key,
        report_key
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = CommandManeuverReviewArtifactHelpers.stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.#{source_key}", Map.get(artifact, source_key)},
        {"#{path}.#{report_key}", Map.get(artifact, report_key)}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        apply(source_module, :entries, [
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        ])
      end)
    end)
  end

  def operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module
      ) do
    CommandManeuverReviewPackageReports.operator_review_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      source_module
    )
  end

  def cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module
      ) do
    CommandManeuverReviewImportReports.cadence_import_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      source_module
    )
  end
end
