defmodule OrbitalDynamics.CadenceImport.ManifestContractDiagnostics do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization

  def unsupported_contract(%{} = artifact) do
    case artifact |> JsonNormalization.stringify_keys() |> Map.get("schema_contract") do
      contract when is_binary(contract) and contract != "" -> contract
      nil -> "unknown"
      contract when is_atom(contract) -> Atom.to_string(contract)
      contract -> inspect(contract)
    end
  end

  def supported_contracts(capability) do
    capability
    |> Map.fetch!(:supported_sources)
    |> Enum.join(", ")
  end
end
