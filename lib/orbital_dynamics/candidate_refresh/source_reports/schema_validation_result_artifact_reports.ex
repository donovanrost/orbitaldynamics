defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidation
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationResultArtifactEncoding

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}.source_schema_validation_report",
         Map.get(artifact, "source_schema_validation_report")},
        {"#{path}.schema_validation_report", Map.get(artifact, "schema_validation_report")},
        {"#{path}.source_schema_validation_batch_report",
         Map.get(artifact, "source_schema_validation_batch_report")},
        {"#{path}.schema_validation_batch_report",
         Map.get(artifact, "schema_validation_batch_report")}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        SchemaValidation.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  def stringify_keys(value), do: SchemaValidationResultArtifactEncoding.stringify_keys(value)
end
