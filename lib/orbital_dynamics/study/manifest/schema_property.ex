defmodule OrbitalDynamics.Study.Manifest.SchemaProperty do
  @moduledoc false

  def object_property(properties \\ %{}, required \\ []) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => properties
    }
    |> maybe_put_required(required)
  end

  def array_property(items), do: %{"type" => "array", "items" => items}

  def string_property(description \\ nil)
  def string_property(nil), do: %{"type" => "string"}

  def string_property(description),
    do: %{"type" => "string", "description" => description}

  def number_property, do: %{"type" => "number"}
  def non_negative_number_property, do: %{"type" => "number", "minimum" => 0.0}
  def integer_property, do: %{"type" => "integer"}
  def boolean_property, do: %{"type" => "boolean"}
  def enum_property(values), do: %{"type" => "string", "enum" => Enum.sort(values)}

  def station_availability_property do
    %{
      "oneOf" => [
        enum_property([
          "available",
          "unavailable",
          "reduced_capacity",
          "maintenance",
          "reserved"
        ]),
        %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
      ]
    }
  end

  defp maybe_put_required(property, []), do: property
  defp maybe_put_required(property, required), do: Map.put(property, "required", required)
end
