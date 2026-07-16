defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionConstraintResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.Constraint

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionConstraintResultArtifactEncoding

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.source_constraint_report", Map.get(artifact, "source_constraint_report")},
        {"#{path}.constraint_report", Map.get(artifact, "constraint_report")}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        Constraint.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  defp stringify_keys(value),
    do: LinkConstraintCollectionConstraintResultArtifactEncoding.stringify_keys(value)
end
