defmodule OrbitalDynamics.Schema.ActivityTemplateJsonSchema do
  @moduledoc false

  @property_fields [
    "schema_contract",
    "id",
    "activity_type",
    "template_version",
    "validation_level",
    "known_limits",
    "display_name",
    "description",
    "required_fields",
    "optional_fields",
    "default_fields",
    "field_count",
    "required_field_count",
    "optional_field_count",
    "lifecycle_defaults",
    "operational_hints",
    "subsystem_state_hints",
    "resource_hints",
    "precondition_hints",
    "assumptions"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts("id", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{"type" => "string", "const" => schema_contract}
  end

  def property("id", opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  def property("activity_type", _opts) do
    %{"type" => "string", "enum" => activity_types()}
  end

  def property("template_version", _opts) do
    %{"type" => "integer", "minimum" => 1}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("known_limits", _opts), do: string_array_schema()

  def property(field, _opts)
      when field in ["display_name", "description"] do
    %{"type" => "string"}
  end

  def property(field, _opts)
      when field in ["required_fields", "optional_fields"] do
    string_array_schema()
  end

  def property("default_fields", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def property(field, _opts)
      when field in ["field_count", "required_field_count", "optional_field_count"] do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("lifecycle_defaults", _opts) do
    lifecycle_defaults()
  end

  def property("operational_hints", _opts) do
    operational_hints()
  end

  def property("subsystem_state_hints", _opts) do
    subsystem_state_hints()
  end

  def property("resource_hints", _opts) do
    resource_hints()
  end

  def property("precondition_hints", _opts) do
    %{"type" => "array", "items" => precondition_hint()}
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp activity_types do
    OrbitalDynamics.Timeline.capabilities().supported_activity_types
  end

  defp activity_statuses do
    OrbitalDynamics.Timeline.capabilities().activity_statuses
  end

  defp approval_statuses do
    OrbitalDynamics.Timeline.capabilities().approval_statuses
  end

  defp precondition_types do
    OrbitalDynamics.Timeline.capabilities().activity_precondition_types
  end

  defp precondition_statuses do
    OrbitalDynamics.Timeline.capabilities().activity_precondition_statuses
  end

  defp lifecycle_defaults do
    %{
      "type" => "object",
      "properties" => %{
        "status" => %{"type" => "string", "enum" => activity_statuses()},
        "approval_status" => %{
          "type" => "string",
          "enum" => approval_statuses()
        },
        "locked" => %{"type" => "boolean"},
        "allow_overlap" => %{"type" => "boolean"}
      },
      "additionalProperties" => true
    }
  end

  defp operational_hints do
    %{
      "type" => "object",
      "properties" => %{
        "setup_duration_s" => %{"type" => "number", "minimum" => 0.0},
        "cooldown_duration_s" => %{"type" => "number", "minimum" => 0.0},
        "telemetry_confirmation_required" => %{"type" => "boolean"},
        "telemetry_confirmation_status" => %{"type" => "string"}
      },
      "additionalProperties" => true
    }
  end

  defp subsystem_state_hints do
    %{
      "type" => "object",
      "properties" => %{
        "required_states" => %{
          "type" => "array",
          "items" => subsystem_state_hint()
        },
        "produced_states" => %{
          "type" => "array",
          "items" => subsystem_state_hint()
        }
      },
      "additionalProperties" => true
    }
  end

  defp subsystem_state_hint do
    %{
      "type" => "object",
      "required" => ["subsystem", "state"],
      "properties" => %{
        "subsystem" => %{"type" => "string"},
        "state" => %{"type" => "string"},
        "reason" => %{"type" => "string"},
        "blocking" => %{"type" => "boolean"}
      },
      "additionalProperties" => true
    }
  end

  defp resource_hints do
    %{
      "type" => "object",
      "properties" =>
        %{}
        |> Map.merge(
          boolean_property_schemas([
            "requires_payload",
            "requires_antenna",
            "requires_contact",
            "uses_storage",
            "uses_power",
            "uses_fuel"
          ])
        )
        |> Map.merge(
          string_array_property_schemas([
            "suppressed_activity_types",
            "incompatible_activity_types"
          ])
        )
        |> Map.merge(
          non_negative_number_property_schemas([
            "estimated_data_volume_mb",
            "estimated_downlink_mb",
            "battery_energy_used_wh",
            "battery_energy_generated_wh"
          ])
        )
        |> Map.merge(
          number_property_schemas([
            "fuel_margin",
            "power_margin",
            "storage_margin",
            "downlink_margin",
            "thermal_margin_c"
          ])
        ),
      "additionalProperties" => true
    }
  end

  defp precondition_hint do
    %{
      "type" => "object",
      "required" => ["precondition_type"],
      "properties" => %{
        "precondition_type" => %{
          "type" => "string",
          "enum" => precondition_types()
        },
        "status" => %{
          "type" => "string",
          "enum" => precondition_statuses()
        },
        "reason" => %{"type" => "string"},
        "field" => %{"type" => "string"},
        "value" => true,
        "blocking" => %{"type" => "boolean"}
      },
      "additionalProperties" => true
    }
  end

  defp string_array_schema do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end

  defp string_array_property_schemas(fields) do
    Map.new(fields, &{&1, string_array_schema()})
  end

  defp number_property_schemas(fields) do
    Map.new(fields, &{&1, %{"type" => "number"}})
  end

  defp non_negative_number_property_schemas(fields) do
    Map.new(fields, &{&1, %{"type" => "number", "minimum" => 0.0}})
  end

  defp boolean_property_schemas(fields) do
    Map.new(fields, &{&1, %{"type" => "boolean"}})
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
