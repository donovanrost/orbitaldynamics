defmodule OrbitalDynamics.Schema.CommonJsonSchema do
  @moduledoc false

  def string_array do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end

  def sha256(pattern) do
    %{"type" => "string", "pattern" => pattern}
  end

  def number_array do
    %{"type" => "array", "items" => %{"type" => "number"}}
  end

  def non_negative_integer_array do
    %{"type" => "array", "items" => %{"type" => "integer", "minimum" => 0}}
  end

  def numeric_triplet do
    %{
      "type" => "array",
      "items" => %{"type" => "number"},
      "minItems" => 3,
      "maxItems" => 3
    }
  end

  def number_or_number_array do
    %{"anyOf" => [%{"type" => "number"}, number_array()]}
  end

  def number_array_map do
    %{"type" => "object", "additionalProperties" => number_array()}
  end

  def stable_id_array(stable_id_pattern) do
    %{"type" => "array", "items" => %{"type" => "string", "pattern" => stable_id_pattern}}
  end

  def stable_id_array_map(stable_id_pattern) do
    %{"type" => "object", "additionalProperties" => stable_id_array(stable_id_pattern)}
  end

  def enum_stable_id_array_map(stable_id_pattern, values) do
    stable_id_array_map(stable_id_pattern)
    |> Map.put("propertyNames", %{"enum" => values})
  end

  def nested_stable_id_array_map(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => stable_id_array_map(stable_id_pattern)
    }
  end

  def string_properties(fields) do
    Map.new(fields, &{&1, %{"type" => "string"}})
  end

  def string_array_properties(fields) do
    Map.new(fields, &{&1, string_array()})
  end

  def string_or_array_properties(fields) do
    Map.new(fields, &{&1, %{"type" => ["string", "array"], "items" => %{"type" => "string"}}})
  end

  def number_properties(fields) do
    Map.new(fields, &{&1, %{"type" => "number"}})
  end

  def integer_properties(fields) do
    Map.new(fields, &{&1, %{"type" => "integer"}})
  end

  def non_negative_integer_properties(fields) do
    Map.new(fields, &{&1, %{"type" => "integer", "minimum" => 0}})
  end

  def boolean_properties(fields) do
    Map.new(fields, &{&1, %{"type" => "boolean"}})
  end

  def boolean_const_assumptions(fields) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => fields,
      "properties" =>
        Map.new(fields, fn field ->
          {field, %{"type" => "boolean", "const" => true}}
        end)
    }
  end

  def string_const_assumptions(values) do
    fields = Map.keys(values)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => fields,
      "properties" =>
        Map.new(values, fn {field, value} ->
          {field, %{"type" => "string", "const" => value}}
        end)
    }
  end

  def numeric_map do
    %{"type" => "object", "additionalProperties" => %{"type" => "number"}}
  end

  def non_negative_integer_count_map do
    %{
      "type" => "object",
      "additionalProperties" => %{"type" => "integer", "minimum" => 0}
    }
  end

  def enum_count_map(values) do
    %{
      "type" => "object",
      "propertyNames" => %{"enum" => values},
      "additionalProperties" => %{"type" => "integer", "minimum" => 0}
    }
  end

  def probability_map do
    %{
      "type" => "object",
      "additionalProperties" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
    }
  end

  def probability do
    %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
  end

  def number_or_string do
    %{"type" => ["number", "string"]}
  end

  def non_negative_number_map do
    %{
      "type" => "object",
      "additionalProperties" => %{"type" => "number", "minimum" => 0.0}
    }
  end

  def nested_non_negative_number_map do
    %{
      "type" => "object",
      "additionalProperties" => non_negative_number_map()
    }
  end

  def string_value_map do
    %{
      "type" => "object",
      "additionalProperties" => %{"type" => "string"}
    }
  end

  def string_list_map do
    %{
      "type" => "object",
      "additionalProperties" => string_array()
    }
  end

  def nested_object_map do
    %{
      "type" => "object",
      "additionalProperties" => %{"type" => "object", "additionalProperties" => true}
    }
  end
end
