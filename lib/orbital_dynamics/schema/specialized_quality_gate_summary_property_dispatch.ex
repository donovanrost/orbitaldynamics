defmodule OrbitalDynamics.Schema.SpecializedQualityGateSummaryPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalQualityGateImportReadinessSummaryJsonSchema
  alias OrbitalDynamics.Schema.OperationalQualityGateOperatorTrainingSummaryJsonSchema
  alias OrbitalDynamics.Schema.OperationalQualityGateSchemaValidationSummaryJsonSchema
  alias OrbitalDynamics.Schema.OperationalQualityGateUnavailableResourceSummaryJsonSchema

  @import_readiness_summary "operational_quality_gate_import_readiness_summary.v1"
  @operator_training_summary "operational_quality_gate_operator_training_summary.v1"
  @schema_validation_summary "operational_quality_gate_schema_validation_summary.v1"
  @unavailable_resource_summary "operational_quality_gate_unavailable_resource_summary.v1"

  def property(field, contract_name, contract, deps)
      when contract_name in [
             @unavailable_resource_summary,
             @operator_training_summary,
             @schema_validation_summary,
             @import_readiness_summary
           ] do
    {property_field?, property} = property_dispatch(contract_name, deps)

    if property_field?.(field) do
      property.(field)
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp property_dispatch(@unavailable_resource_summary, deps) do
    {
      &OperationalQualityGateUnavailableResourceSummaryJsonSchema.property_field?/1,
      OperationalQualityGateUnavailableResourceSummaryJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :unavailable_resource_model_limits).(),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(@operator_training_summary, deps) do
    {
      &OperationalQualityGateOperatorTrainingSummaryJsonSchema.property_field?/1,
      OperationalQualityGateOperatorTrainingSummaryJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :operator_training_model_limits).(),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(@schema_validation_summary, deps) do
    {
      &OperationalQualityGateSchemaValidationSummaryJsonSchema.property_field?/1,
      OperationalQualityGateSchemaValidationSummaryJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :schema_validation_model_limits).(),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(@import_readiness_summary, deps) do
    {
      &OperationalQualityGateImportReadinessSummaryJsonSchema.property_field?/1,
      OperationalQualityGateImportReadinessSummaryJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :import_readiness_model_limits).(),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end
end
