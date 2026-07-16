defmodule OrbitalDynamics.Schema.ActivityTemplateRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "activity_template.v1" => %{
        "schema_contract" => "activity_template.v1",
        "artifact_family" => "activity_template",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "activity_type",
          "template_version",
          "validation_level",
          "known_limits"
        ],
        "optional_fields" => [
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
        ],
        "nested_contracts" => []
      }
    }
  end
end
