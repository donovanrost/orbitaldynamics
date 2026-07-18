defmodule OrbitalDynamics.Schema.ResultArtifactPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ExecutionReportJsonSchema,
    ResourceSummaryJsonSchema,
    ResultArtifactJsonSchema
  }

  def execution_report(
        field,
        contract_name,
        contract,
        default_property,
        {schema_contract, stable_id_pattern, model_limits}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ExecutionReportJsonSchema.property_field?/1,
      ExecutionReportJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern,
        model_limits: model_limits
      ),
      default_property
    )
  end

  def result_artifact(
        field,
        contract_name,
        contract,
        default_property,
        {schema_version, stable_id_pattern, execution_report_contract, embedded_contract_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ResultArtifactJsonSchema.property_field?/1,
      ResultArtifactJsonSchema.property_fun_from_context(
        schema_version: schema_version,
        stable_id_pattern: stable_id_pattern,
        execution_report_contract: execution_report_contract,
        embedded_contract_schema: embedded_contract_schema
      ),
      default_property
    )
  end

  def resource_summary(
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
      &ResourceSummaryJsonSchema.property_field?/1,
      ResourceSummaryJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
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
