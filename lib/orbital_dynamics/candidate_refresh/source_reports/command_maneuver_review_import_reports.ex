defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewImportReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewArtifactHelpers

  def cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module
      ) do
    direct =
      [
        {"accepted_planning_state.source_cadence_import_manifest",
         get_in(refresh, ["accepted_planning_state", "source_cadence_import_manifest"])},
        {"accepted_planning_state.cadence_import_manifest",
         get_in(refresh, ["accepted_planning_state", "cadence_import_manifest"])},
        {"mission_state.source_cadence_import_manifest",
         get_in(refresh, ["mission_state", "source_cadence_import_manifest"])},
        {"mission_state.cadence_import_manifest",
         get_in(refresh, ["mission_state", "cadence_import_manifest"])},
        {"source_cadence_import_manifest", Map.get(refresh, "source_cadence_import_manifest")},
        {"cadence_import_manifest", Map.get(refresh, "cadence_import_manifest")}
      ]
      |> Enum.flat_map(fn {path, manifest_or_manifests} ->
        apply(source_module, :cadence_import_entries, [path, manifest_or_manifests])
      end)

    direct ++
      embedded_cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module
      )
  end

  defp embedded_cadence_import_reports(
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
        {"#{path}.cadence_import_manifest", Map.get(artifact, "cadence_import_manifest")}
      ]
      |> Enum.flat_map(fn {entry_path, manifest} ->
        apply(source_module, :cadence_import_entries, [
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(manifest, artifact)
        ])
      end)
    end)
  end
end
