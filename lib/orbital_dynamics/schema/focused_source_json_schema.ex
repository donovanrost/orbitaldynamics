defmodule OrbitalDynamics.Schema.FocusedSourceJsonSchema do
  @moduledoc false

  def build(
        contract_name,
        contract,
        property_field?,
        property_opts,
        property,
        deps,
        default_property
      ) do
    required_fields = contract["required_fields"]

    properties =
      (required_fields ++ Map.get(contract, "optional_fields", []))
      |> Enum.uniq()
      |> Enum.sort()
      |> Map.new(fn field ->
        {field,
         property_for_field(
           field,
           contract_name,
           contract,
           property_field?,
           property_opts,
           property,
           deps,
           default_property
         )}
      end)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => required_fields,
      "properties" => properties
    }
  end

  defp property_for_field(
         field,
         contract_name,
         contract,
         property_field?,
         property_opts,
         property,
         deps,
         default_property
       ) do
    if property_field?.(field) do
      property.(field, property_opts.(field, deps))
    else
      default_property.(field, contract_name, contract)
    end
  end
end
