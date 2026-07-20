defmodule OrbitalDynamics.Schema.ResultArtifactValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ExecutionReproducibilityValidation,
    PrimitiveValidation,
    Registry,
    ResultArtifactContracts,
    StudyResultRegistryContracts
  }

  @result_artifact "result_artifact.v1"
  @execution_report "execution_report.v1"

  def validate(issues, path, artifact) do
    issues
    |> PrimitiveValidation.require_fields(path, artifact, required_fields())
    |> ResultArtifactContracts.validate(path, artifact, &validate_execution_report/1)
  end

  defp validate_execution_report(execution_report) do
    ExecutionReproducibilityValidation.validate(
      [],
      "$",
      execution_report,
      @execution_report
    )
  end

  defp required_fields do
    StudyResultRegistryContracts.contracts()
    |> Registry.fetch!(@result_artifact)
    |> Map.fetch!("required_fields")
  end
end
