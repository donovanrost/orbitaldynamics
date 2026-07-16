defmodule OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudgetResultArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudgetTraversalEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module,
        report_key
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = FreshnessBudgetTraversalEncoding.stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.source_#{report_key}", Map.get(artifact, "source_#{report_key}")},
        {"#{path}.#{report_key}", Map.get(artifact, report_key)}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        source_module.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end
end
