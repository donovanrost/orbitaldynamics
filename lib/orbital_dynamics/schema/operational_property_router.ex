defmodule OrbitalDynamics.Schema.OperationalPropertyRouter do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalReadinessValidation

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_import_eligibility_summary.v1",
             "operational_readiness_gate_summary.v1",
             "operational_execution_boundary_summary.v1"
           ] do
    OrbitalDynamics.Schema.OperationalReadinessGateSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      capability: fn -> provider(context, :operational_readiness_capabilities, []) end,
      gate_schema: fn -> provider(context, :operational_readiness_gate_json_schema, []) end,
      import_eligibility_model_limits:
        &OperationalReadinessValidation.operational_import_eligibility_summary_model_limits/0,
      readiness_gate_model_limits:
        &OperationalReadinessValidation.operational_readiness_gate_summary_model_limits/0,
      execution_boundary_model_limits:
        &OperationalReadinessValidation.operational_execution_boundary_summary_model_limits/0,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["operational_quality_gate_summary.v1", "quality_gate_report.v1"] do
    OrbitalDynamics.Schema.QualityGateReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      capability: fn -> provider(context, :operational_readiness_capabilities, []) end,
      operational_summary_model_limits:
        &OperationalReadinessValidation.quality_gate_summary_model_limits/0,
      report_model_limits: &OperationalReadinessValidation.quality_gate_report_model_limits/0,
      row_schema: fn -> provider(context, :quality_gate_report_row_json_schema, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_quality_gate_unavailable_resource_summary.v1",
             "operational_quality_gate_operator_training_summary.v1",
             "operational_quality_gate_schema_validation_summary.v1",
             "operational_quality_gate_import_readiness_summary.v1"
           ] do
    OrbitalDynamics.Schema.SpecializedQualityGateSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      unavailable_resource_model_limits:
        &OperationalReadinessValidation.quality_gate_unavailable_resource_summary_model_limits/0,
      operator_training_model_limits:
        &OperationalReadinessValidation.quality_gate_operator_training_summary_model_limits/0,
      schema_validation_model_limits:
        &OperationalReadinessValidation.quality_gate_schema_validation_summary_model_limits/0,
      import_readiness_model_limits:
        &OperationalReadinessValidation.quality_gate_import_readiness_summary_model_limits/0,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "operational_readiness_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.readiness(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {provider(context, :operational_readiness_capabilities, []),
       provider(context, :operational_readiness_gate_json_schema, []),
       provider(context, :operational_readiness_evidence_json_schema, []),
       OperationalReadinessValidation.operational_readiness_model_limits()}
    )
  end

  def property(field, "operator_review_package.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.operator_review(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {provider(context, :operator_review_capabilities, []),
       provider(context, :operator_review_package_model_limits, []),
       provider(context, :operational_readiness_capabilities, []),
       provider(context, :operator_review_row_json_schema, []),
       OrbitalDynamics.Schema.OperatorReviewPackageContracts.scalar_count_fields(),
       context_value(context, :stable_id_pattern)}
    )
  end

  def property(field, "cadence_import_manifest.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.cadence_import(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {provider(context, :cadence_import_capability, []),
       provider(context, :cadence_import_manifest_model_limits, []),
       provider(context, :operational_readiness_capabilities, []),
       provider(context, :cadence_import_manifest_row_json_schema, []),
       provider(context, :cadence_import_manifest_scalar_count_fields, []),
       context_value(context, :stable_id_pattern)}
    )
  end
end
