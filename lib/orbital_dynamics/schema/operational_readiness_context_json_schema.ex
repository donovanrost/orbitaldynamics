defmodule OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  def resource_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "resource_availability_pressure_count" => non_negative_integer(),
      "resource_availability_reason_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_availability_reason_ids" => CommonJsonSchema.string_array(),
      "station_availability_reason_ids" => CommonJsonSchema.string_array(),
      "station_availability_reason_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "unavailable_resource_reason_ids" => CommonJsonSchema.string_array(),
      "resource_blocking_dimension_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        stable_id_array_map(stable_id_pattern),
      "resource_blocked_contact_ids_by_spacecraft_id" => stable_id_array_map(stable_id_pattern),
      "resource_source_quality_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_trust_boundary_status_counts" => CommonJsonSchema.non_negative_integer_count_map()
    }
  end

  def adapter_boundary_context_properties do
    %{
      "adapter_context_count" => non_negative_integer(),
      "adapter_trust_boundary_declared_count" => non_negative_integer(),
      "adapter_trust_boundary_missing_count" => non_negative_integer(),
      "adapter_trust_boundary_untrusted_count" => non_negative_integer(),
      "adapter_boundary_status_counts" => trust_boundary_status_count_map()
    }
  end

  def operator_training_context_properties do
    %{
      "operator_training_requirement_count" => non_negative_integer(),
      "operator_training_requirement_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "required_operator_roles" => CommonJsonSchema.string_array(),
      "required_training_ids" => CommonJsonSchema.string_array(),
      "required_certification_ids" => CommonJsonSchema.string_array(),
      "required_qualification_ids" => CommonJsonSchema.string_array()
    }
  end

  def cadence_import_context_properties do
    OrbitalDynamics.Schema.CadenceImportOperationalReadinessJsonSchema.context_properties()
  end

  defp non_negative_integer do
    %{"type" => "integer", "minimum" => 0}
  end

  defp stable_id_array_map(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => CommonJsonSchema.stable_id_array(stable_id_pattern)
    }
  end

  defp trust_boundary_status_count_map do
    %{
      "type" => "object",
      "propertyNames" => %{"enum" => ["declared", "missing", "untrusted"]},
      "additionalProperties" => %{"type" => "integer", "minimum" => 0}
    }
  end
end
