defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewPackageReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewArtifactHelpers

  def operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module
      ) do
    direct =
      [
        {"accepted_planning_state.source_operator_review_package",
         get_in(refresh, ["accepted_planning_state", "source_operator_review_package"])},
        {"accepted_planning_state.operator_review_package",
         get_in(refresh, ["accepted_planning_state", "operator_review_package"])},
        {"mission_state.source_operator_review_package",
         get_in(refresh, ["mission_state", "source_operator_review_package"])},
        {"mission_state.operator_review_package",
         get_in(refresh, ["mission_state", "operator_review_package"])},
        {"source_operator_review_package", Map.get(refresh, "source_operator_review_package")},
        {"operator_review_package", Map.get(refresh, "operator_review_package")}
      ]
      |> Enum.flat_map(fn {path, package_or_packages} ->
        apply(source_module, :operator_review_entries, [path, package_or_packages])
      end)

    direct ++
      embedded_operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module
      )
  end

  defp embedded_operator_review_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         source_module
       ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = CommandManeuverReviewArtifactHelpers.stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.operator_review_package", Map.get(artifact, "operator_review_package")}
      ]
      |> Enum.flat_map(fn {entry_path, package} ->
        apply(source_module, :operator_review_entries, [
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(package, artifact)
        ])
      end)
    end)
  end
end
