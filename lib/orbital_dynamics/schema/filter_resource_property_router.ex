defmodule OrbitalDynamics.Schema.FilterResourcePropertyRouter do
  @moduledoc false

  alias OrbitalDynamics.Schema.ResourceValidation

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, contract_name, contract, context)
      when contract_name in ["contact_filter_report.v1", "resource_filter_report.v1"] do
    OrbitalDynamics.Schema.FilterReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{contact: "contact_filter_report.v1", resource: "resource_filter_report.v1"},
      stable_id_pattern: context_value(context, :stable_id_pattern),
      trust_boundary_count_map_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      contact_model_limits: fn -> provider(context, :contact_filter_report_model_limits, []) end,
      contact_assumptions_schema: fn ->
        provider(context, :contact_filter_report_assumptions_json_schema, [])
      end,
      resource_model_limits: fn -> provider(context, :resource_filter_report_model_limits, []) end,
      resource_assumptions_schema: fn ->
        provider(context, :resource_filter_report_assumptions_json_schema, [])
      end,
      suppressed_candidate_schema: fn ->
        provider(context, :suppressed_candidate_json_schema, [])
      end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "resource_projection_report.v1",
             "resource_projection_flow_summary.v1"
           ] do
    OrbitalDynamics.Schema.ResourceProjectionPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: "resource_projection_report.v1",
        flow_summary: "resource_projection_flow_summary.v1"
      },
      stable_id_pattern: context_value(context, :stable_id_pattern),
      models: &ResourceValidation.resource_projection_report_models/0,
      model_limits: &ResourceValidation.resource_projection_report_model_limits/0,
      assumptions_schema:
        &OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema.assumptions/0,
      projection_row_schema: fn -> provider(context, :resource_projection_row_json_schema, []) end,
      flow_row_schema: fn -> provider(context, :resource_projection_flow_row_json_schema, []) end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "contact_contention_report.v1",
             "contact_contention_resolution_report.v1",
             "contact_contention_resolution_summary.v1"
           ] do
    OrbitalDynamics.Schema.ContactContentionPropertyDispatch.property(
      field,
      contract_name,
      contract,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      model_limits: provider(context, :contact_contention_report_model_limits, []),
      report_assumptions_schema:
        provider(context, :contact_contention_report_assumptions_json_schema, []),
      conflict_group_schema: provider(context, :contact_contention_group_json_schema, []),
      recommendation_schema:
        provider(context, :contact_contention_recommendation_json_schema, []),
      resolution_policy_schema:
        provider(context, :contact_contention_resolution_policy_json_schema, []),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end
end
