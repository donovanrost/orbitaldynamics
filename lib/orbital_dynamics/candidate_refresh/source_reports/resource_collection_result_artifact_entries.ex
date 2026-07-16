defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        fields,
        entries
      )
      when is_function(entries, 2) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = ResourceCollectionEncoding.stringify_keys(artifact)

      path
      |> artifact_entries(artifact, fields)
      |> Enum.flat_map(fn {entry_path, report} ->
        entries.(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  defp artifact_entries(path, artifact, fields) do
    [{path, artifact}] ++
      Enum.map(fields, fn field ->
        {"#{path}.#{field}", Map.get(artifact, field)}
      end)
  end
end
