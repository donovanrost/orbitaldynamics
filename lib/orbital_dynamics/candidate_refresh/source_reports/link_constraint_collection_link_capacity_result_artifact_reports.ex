defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacity

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityResultArtifactEncoding

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.source_link_capacity_summary",
         Map.get(artifact, "source_link_capacity_summary")},
        {"#{path}.link_capacity_summary", Map.get(artifact, "link_capacity_summary")},
        {"#{path}.source_relay_data_path_summary",
         Map.get(artifact, "source_relay_data_path_summary")},
        {"#{path}.relay_data_path_summary", Map.get(artifact, "relay_data_path_summary")},
        {"#{path}.source_link_capacity_report", Map.get(artifact, "source_link_capacity_report")},
        {"#{path}.link_capacity_report", Map.get(artifact, "link_capacity_report")}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        LinkCapacity.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  defp stringify_keys(value),
    do: LinkConstraintCollectionLinkCapacityResultArtifactEncoding.stringify_keys(value)
end
