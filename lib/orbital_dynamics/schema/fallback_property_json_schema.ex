defmodule OrbitalDynamics.Schema.FallbackPropertyJsonSchema do
  @moduledoc false

  def property(field, contract_name, contract, opts) do
    type =
      opts
      |> Keyword.fetch!(:field_type_hints)
      |> Map.get(field, "object")

    %{"type" => type}
    |> maybe_add_const(field, contract_name, contract)
    |> maybe_add_stable_id_pattern(field, Keyword.fetch!(opts, :stable_id_pattern))
  end

  defp maybe_add_const(property, "schema_contract", contract_name, _contract) do
    property
    |> Map.put("const", contract_name)
    |> Map.put("description", "Stable executable contract identifier")
  end

  defp maybe_add_const(property, "schema_version", _contract_name, contract) do
    property
    |> Map.put("const", contract["schema_version"])
    |> Map.put("description", "Artifact schema version")
  end

  defp maybe_add_const(property, "artifact_type", _contract_name, contract) do
    Map.put(property, "const", contract["artifact_family"])
  end

  defp maybe_add_const(property, _field, _contract_name, _contract), do: property

  defp maybe_add_stable_id_pattern(%{"type" => "string"} = property, field, pattern) do
    if stable_id_field?(field) do
      Map.put(property, "pattern", pattern)
    else
      property
    end
  end

  defp maybe_add_stable_id_pattern(property, _field, _pattern), do: property

  defp stable_id_field?(field), do: field == "id" or String.ends_with?(field, "_id")
end
