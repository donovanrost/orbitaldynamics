defmodule OrbitalDynamics.Schema.RealizedStateValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  def validate_activity(issues, path, artifact),
    do: validate(issues, path, artifact, "realized_activity.v1")

  def validate_snapshot(issues, path, artifact),
    do: validate(issues, path, artifact, "realized_state_snapshot.v1")

  def validate_optional_snapshot(issues, _path, nil), do: issues

  def validate_optional_snapshot(issues, path, %{} = artifact),
    do: validate_snapshot(issues, path, artifact)

  def validate_optional_snapshot(issues, path, _artifact),
    do: [error(path, "must be an object") | issues]

  defp validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "realized_activity.v1"),
    do: OrbitalDynamics.Schema.RealizedActivityContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "realized_state_snapshot.v1"),
    do: OrbitalDynamics.Schema.RealizedStateSnapshotContracts.validate(issues, path, artifact)

  defp required_fields(contract_name) do
    OrbitalDynamics.Schema.RealizedStateRegistryContracts.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
