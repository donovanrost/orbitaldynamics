defmodule OrbitalDynamics.Schema.PlanningReferencePropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    AcceptedStateJsonSchema,
    ActivityTemplateJsonSchema,
    CapabilityCatalogJsonSchema,
    ManifestFieldReferenceJsonSchema
  }

  def activity_template(
        field,
        contract_name,
        contract,
        default_property,
        {schema_contract, stable_id_pattern}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ActivityTemplateJsonSchema.property_field?/1,
      ActivityTemplateJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern
      ),
      default_property
    )
  end

  def capability_catalog(field, contract_name, contract, default_property) do
    dispatch(
      field,
      contract_name,
      contract,
      &CapabilityCatalogJsonSchema.property_field?/1,
      &CapabilityCatalogJsonSchema.property/1,
      default_property
    )
  end

  def accepted_state(
        field,
        contract_name,
        contract,
        default_property,
        {spacecraft_state_estimate_schema, maneuver_execution_delta_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &AcceptedStateJsonSchema.property_field?/1,
      AcceptedStateJsonSchema.property_fun_from_context(
        spacecraft_state_estimate_schema: spacecraft_state_estimate_schema,
        maneuver_execution_delta_schema: maneuver_execution_delta_schema
      ),
      default_property
    )
  end

  def manifest_field_reference(field, contract_name, contract, default_property) do
    dispatch(
      field,
      contract_name,
      contract,
      &ManifestFieldReferenceJsonSchema.property_field?/1,
      &ManifestFieldReferenceJsonSchema.property/1,
      default_property
    )
  end

  defp dispatch(
         field,
         contract_name,
         contract,
         property_field?,
         property,
         default_property
       ) do
    if property_field?.(field) do
      property.(field)
    else
      default_property.(field, contract_name, contract)
    end
  end
end
