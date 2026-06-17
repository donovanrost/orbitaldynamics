defmodule OrbitalDynamics.Schema.ManifestFieldReferenceJsonSchema do
  @moduledoc false

  def property("fields") do
    %{
      "type" => "array",
      "items" => row()
    }
  end

  def property("supported") do
    supported()
  end

  def property("field_count") do
    %{"type" => "integer", "minimum" => 0}
  end

  def row do
    %{
      "type" => "object",
      "required" => ["path", "parent_path", "section", "type", "required", "array_item"],
      "properties" => %{
        "path" => %{"type" => "string", "minLength" => 1},
        "parent_path" => %{"type" => "string", "minLength" => 1},
        "section" => %{"type" => "string", "minLength" => 1},
        "type" => %{
          "oneOf" => [
            %{"type" => "string", "minLength" => 1},
            %{"type" => "array", "items" => %{"type" => "string", "minLength" => 1}}
          ]
        },
        "required" => %{"type" => "boolean"},
        "array_item" => %{"type" => "boolean"},
        "enum" => %{"type" => "array", "items" => %{}},
        "const" => %{},
        "description" => %{"type" => "string"},
        "min_items" => %{"type" => "integer", "minimum" => 0},
        "max_items" => %{"type" => "integer", "minimum" => 0},
        "minimum" => %{"type" => "number"},
        "maximum" => %{"type" => "number"},
        "schema_contract_ref" => %{"type" => "string", "minLength" => 1},
        "additional_properties_type" => %{"type" => "string", "minLength" => 1},
        "stable_id_pattern" => %{"type" => "string", "minLength" => 1},
        "trust_boundary_sources" => string_array_schema(),
        "nested_contracts" => string_array_schema(),
        "required_children" => string_array_schema(),
        "required_alternatives" => %{
          "type" => "array",
          "items" => string_array_schema()
        }
      },
      "additionalProperties" => true
    }
  end

  def supported do
    %{
      "type" => "object",
      "required" => ["lint_error_codes", "outputs", "propagators", "search_objectives"],
      "properties" => %{
        "lint_error_codes" => string_array_schema(),
        "outputs" => string_array_schema(),
        "propagators" => string_array_schema(),
        "search_objectives" => string_array_schema()
      },
      "additionalProperties" => false
    }
  end

  defp string_array_schema do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end
end
