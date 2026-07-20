defmodule OrbitalDynamics.Schema.TimelineReportPropertyRouter do
  @moduledoc false

  alias OrbitalDynamics.Schema.TimelineContextJsonSchema

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, "timeline_feedback_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.feedback(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :timeline_feedback_row_json_schema, []) end,
       fn -> provider(context, :timeline_feedback_report_model_limits, []) end,
       fn -> provider(context, :timeline_feedback_capabilities, []) end,
       fn -> provider(context, :operational_feedback_json_schema, []) end,
       fn ->
         provider(context, :timeline_feedback_operational_feedback_provenance_json_schema, [])
       end}
    )
  end

  def property(field, "timeline_integrity_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.integrity(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_integrity_report.v1",
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :operational_timeline_row_json_schema, []) end,
       fn -> provider(context, :timeline_integrity_issue_types, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end}
    )
  end

  def property(
        field,
        "timeline_dependency_impact_summary.v1" = contract_name,
        contract,
        context
      ) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.dependency_impact(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_dependency_impact_summary.v1",
      {fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :timeline_dependency_impact_row_json_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end}
    )
  end

  def property(field, "timeline_publication_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.publication(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_publication_summary.v1",
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :timeline_diff_summary_source_json_schema, []) end,
       fn -> provider(context, :timeline_dependency_impact_summary_source_json_schema, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end}
    )
  end

  def property(field, "timeline_activity_state.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineActivityStatePropertyDispatch.state(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_activity_state.v1",
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :timeline_feedback_row_json_schema, []) end,
       fn -> provider(context, :timeline_feedback_capabilities, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
       fn -> provider(context, :timeline_identity_json_schema, []) end,
       fn -> provider(context, :activity_context_json_schema, []) end,
       &TimelineContextJsonSchema.lifecycle_transition/0,
       fn -> provider(context, :protection_decision_json_schema, []) end,
       fn ->
         OrbitalDynamics.Schema.CommonJsonSchema.boolean_const_assumptions([
           "artifact_only",
           "no_schedule_mutation",
           "no_command_execution"
         ])
       end, fn -> provider(context, :timeline_feedback_report_model_limits, []) end}
    )
  end

  def property(
        field,
        "timeline_activity_precondition_summary.v1" = contract_name,
        contract,
        context
      ) do
    OrbitalDynamics.Schema.TimelineProtectionPropertyDispatch.precondition(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_activity_precondition_summary.v1",
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :timeline_report_model_limits, []) end,
       fn -> provider(context, :timeline_activity_precondition_statuses, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
       fn -> provider(context, :timeline_precondition_json_schema, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :timeline_identity_json_schema, []) end}
    )
  end
end
