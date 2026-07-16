defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewCollections do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewCollectionEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module,
        source_key,
        report_key
      ) do
    refresh
    |> CommandManeuverReviewDirectReports.reports(source_module, source_key, report_key)
    |> Kernel.++(
      CommandManeuverReviewArtifactReports.result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module,
        source_key,
        report_key
      )
    )
    |> Kernel.++(
      CommandManeuverReviewArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module
      )
    )
    |> Kernel.++(
      CommandManeuverReviewArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module
      )
    )
    |> Enum.filter(fn {_path, report} -> apply(source_module, :report?, [report]) end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  defp stringify_keys(value), do: CommandManeuverReviewCollectionEncoding.stringify_keys(value)
end
