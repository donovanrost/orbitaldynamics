defmodule OrbitalDynamics.Schema.DownlinkLinkBudgetContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  alias OrbitalDynamics.Communications.DownlinkLinkBudget

  def validate(issues, path, artifact) when is_map(artifact) do
    required_fields =
      OrbitalDynamics.Schema.DownlinkLinkBudgetRegistryContracts.contracts()
      |> Map.fetch!(DownlinkLinkBudget.schema_contract())
      |> Map.fetch!("required_fields")

    issues = require_fields(issues, path, artifact, required_fields)

    case DownlinkLinkBudget.validate_artifact(artifact) do
      :ok -> issues
      {:error, reason} -> [error(path, reason) | issues]
    end
  end

  def validate(issues, path, _artifact), do: [error(path, "must be an object") | issues]
end
