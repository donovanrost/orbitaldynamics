defmodule OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CadenceImportManifestJsonSchema,
    OperationalReadinessReportJsonSchema,
    OperatorReviewPackageContracts,
    OperatorReviewPackageJsonSchema
  }

  def readiness(
        field,
        contract_name,
        contract,
        default_property,
        {capability, gate_schema, evidence_schema, model_limits}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &OperationalReadinessReportJsonSchema.property_field?/1,
      OperationalReadinessReportJsonSchema.property_fun_from_context(
        capability: capability,
        gate_schema: gate_schema,
        evidence_schema: evidence_schema,
        model_limits: model_limits
      ),
      default_property
    )
  end

  def operator_review(
        field,
        contract_name,
        contract,
        default_property,
        {
          capability,
          model_limits,
          readiness_capability,
          row_schema,
          scalar_count_fields,
          stable_id_pattern
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &OperatorReviewPackageJsonSchema.property_field?(
        &1,
        OperatorReviewPackageContracts.scalar_count_fields()
      ),
      OperatorReviewPackageJsonSchema.property_fun_from_context(
        capability: capability,
        model_limits: model_limits,
        readiness_capability: readiness_capability,
        row_schema: row_schema,
        scalar_count_fields: scalar_count_fields,
        stable_id_pattern: stable_id_pattern
      ),
      default_property
    )
  end

  def cadence_import(
        field,
        contract_name,
        contract,
        default_property,
        {
          capability,
          model_limits,
          readiness_capability,
          row_schema,
          scalar_count_fields,
          stable_id_pattern
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &CadenceImportManifestJsonSchema.property_field?(&1, scalar_count_fields),
      CadenceImportManifestJsonSchema.property_fun_from_context(
        capability: capability,
        model_limits: model_limits,
        readiness_capability: readiness_capability,
        row_schema: row_schema,
        scalar_count_fields: scalar_count_fields,
        stable_id_pattern: stable_id_pattern
      ),
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
