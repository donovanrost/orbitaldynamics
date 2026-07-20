defmodule OrbitalDynamics.Schema.EmbeddedContractJsonSchema do
  @moduledoc false

  def build(contract_name, opts) do
    contract = Keyword.fetch!(opts, :contract).(contract_name)
    required_fields = contract["required_fields"]
    optional_fields = Map.get(contract, "optional_fields", [])
    property = Keyword.fetch!(opts, :property)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => required_fields,
      "properties" =>
        (required_fields ++ optional_fields)
        |> Enum.uniq()
        |> Enum.sort()
        |> Map.new(&{&1, property.(&1, contract_name, contract)})
    }
  end
end
