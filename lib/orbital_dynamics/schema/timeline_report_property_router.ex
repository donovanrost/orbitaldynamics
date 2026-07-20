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

  def property(field, "candidate_rejection_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.candidate_rejection(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {&OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.model_limits/0,
       fn -> provider(context, :candidate_rejection_row_json_schema, []) end,
       fn -> provider(context, :timeline_candidate_rejection_reasons, []) end,
       fn -> provider(context, :timeline_candidate_rejection_actions, []) end,
       context_value(context, :stable_id_pattern)}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_timeline_report.v1",
             "timeline_diff_report.v1",
             "timeline_diff_summary.v1"
           ] do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        operational_timeline_report: "operational_timeline_report.v1",
        timeline_diff_report: "timeline_diff_report.v1",
        timeline_diff_summary: "timeline_diff_summary.v1"
      },
      model_limits: fn -> provider(context, :timeline_report_model_limits, []) end,
      operational_timeline_row_schema: fn ->
        provider(context, :operational_timeline_row_json_schema, [])
      end,
      timeline_diff_row_schema: fn -> provider(context, :timeline_diff_row_json_schema, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      capability: fn -> provider(context, :timeline_capabilities, []) end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "timeline_activity_status_state.v1",
             "timeline_activity_approval_state.v1",
             "timeline_activity_lifecycle_state.v1"
           ] do
    OrbitalDynamics.Schema.TimelineActivityStatePropertyDispatch.lifecycle(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :timeline_report_model_limits, []) end,
       fn -> provider(context, :timeline_transition_decisions, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
       &TimelineContextJsonSchema.lifecycle_transition/0,
       fn -> provider(context, :protection_decision_json_schema, []) end,
       fn -> provider(context, :activity_context_json_schema, []) end,
       &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.lifecycle_assumptions/0,
       &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.default_assumptions/0}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["timeline_preservation_report.v1", "timeline_preservation_status.v1"] do
    OrbitalDynamics.Schema.TimelineProtectionPropertyDispatch.preservation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      provider(context, :timeline_report_model_limits, []),
      {&OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end,
       fn -> provider(context, :protection_decision_json_schema, []) end,
       fn -> provider(context, :timeline_identity_json_schema, []) end,
       fn arg1 -> provider(context, :timeline_preservation_assumptions_json_schema, [arg1]) end}
    )
  end

  def property(field, "timeline_lifecycle_state_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineTransitionPropertyDispatch.lifecycle_summary(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :timeline_lifecycle_state_row_json_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
       fn -> provider(context, :stable_id_array_schema, []) end}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "timeline_transition_application_report.v1",
             "timeline_transition_application_summary.v1"
           ] do
    OrbitalDynamics.Schema.TimelineTransitionPropertyDispatch.application(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :timeline_transition_application_row_json_schema, []) end,
       fn -> provider(context, :timeline_transition_selected_activity_json_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end,
       fn -> provider(context, :timeline_capabilities, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map/1,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end}
    )
  end
end
