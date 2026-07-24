defmodule OrbitalDynamics.Schema.OperatorReviewSchemaProviders do
  @moduledoc false

  alias OrbitalDynamics.Schema.{CommonJsonSchema, TimelineContextJsonSchema}

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:operator_review_row_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.OperatorReviewRowJsonSchema.row(
          operator_review_capability: call(dependencies, :operator_review_capability),
          readiness_capability: call(dependencies, :readiness_capability),
          timeline_capability: call(dependencies, :timeline_capability),
          stable_id_pattern: stable_id_pattern,
          schema_providers: schema_providers(stable_id_pattern, dependencies),
          property_providers: property_providers(stable_id_pattern, opts)
        )
      end
    }
  end

  def property_providers(stable_id_pattern, opts)
      when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    [
      branch_scoped_downlink_context_json_schema_properties: fn ->
        OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders.branch_scoped_downlink_context_properties(
          stable_id_pattern
        )
      end,
      command_authority_handoff_json_schema_properties:
        &OrbitalDynamics.Schema.CommandAuthorityHandoffJsonSchema.properties/0,
      feedback_maneuver_handoff_json_schema_properties:
        Map.fetch!(dependencies, :feedback_maneuver_handoff_properties),
      link_handoff_json_schema_properties: Map.fetch!(dependencies, :link_handoff_properties),
      resource_availability_variance_json_schema_properties:
        &OrbitalDynamics.Schema.ResourceAvailabilityVarianceJsonSchema.properties/0,
      resource_projection_battery_handoff_json_schema_properties:
        Map.fetch!(dependencies, :resource_projection_battery_handoff_properties),
      scoped_downlink_context_json_schema_properties:
        Map.fetch!(dependencies, :scoped_downlink_context_properties),
      thermal_handoff_json_schema_properties:
        Map.fetch!(dependencies, :thermal_handoff_properties),
      timeline_activity_precondition_handoff_json_schema_properties:
        Map.fetch!(dependencies, :timeline_activity_precondition_handoff_properties),
      timeline_dependency_impact_handoff_json_schema_properties:
        Map.fetch!(dependencies, :timeline_dependency_impact_handoff_properties),
      timeline_publication_handoff_json_schema_properties:
        Map.fetch!(dependencies, :timeline_publication_handoff_properties)
    ]
  end

  defp schema_providers(stable_id_pattern, dependencies) do
    [
      activity_context_json_schema: dependency(dependencies, :activity_context_schema),
      actual_data_rate_throughput_derivation_json_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivation/0,
      approval_requirement_json_schema: dependency(dependencies, :approval_requirement_schema),
      branch_comparison_source_row_json_schema: fn ->
        OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders.branch_comparison_source_row(
          stable_id_pattern
        )
      end,
      branch_event_trust_boundary_status_counts_json_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      candidate_activity_source_window_json_schema:
        dependency(dependencies, :candidate_activity_source_window_schema),
      contact_allocation_capacity_requirement_row_json_schema: fn ->
        OrbitalDynamics.Schema.GroundNetworkSchemaProviders.contact_allocation_capacity_requirement_row(
          stable_id_pattern
        )
      end,
      contact_contention_deferred_priority_json_schema: fn ->
        OrbitalDynamics.Schema.GroundNetworkSchemaProviders.contact_contention_deferred_priority(
          stable_id_pattern
        )
      end,
      boolean_array_schema: &CommonJsonSchema.boolean_array/0,
      lifecycle_transition_json_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      non_negative_integer_array_schema: &CommonJsonSchema.non_negative_integer_array/0,
      non_negative_integer_count_map_schema: &CommonJsonSchema.non_negative_integer_count_map/0,
      non_negative_number_map_json_schema: &CommonJsonSchema.non_negative_number_map/0,
      number_array_schema: &CommonJsonSchema.number_array/0,
      number_or_number_array_schema: &CommonJsonSchema.number_or_number_array/0,
      number_or_string_json_schema: &CommonJsonSchema.number_or_string/0,
      numeric_triplet_schema: &CommonJsonSchema.numeric_triplet/0,
      operational_readiness_evidence_json_schema:
        dependency(dependencies, :operational_readiness_evidence_schema),
      operational_readiness_gate_json_schema:
        dependency(dependencies, :operational_readiness_gate_schema),
      operational_readiness_source_report_evidence_json_schema:
        dependency(dependencies, :operational_readiness_source_report_evidence_schema),
      operational_timeline_row_json_schema:
        dependency(dependencies, :operational_timeline_row_schema),
      policy_decision_evidence_json_schema:
        dependency(dependencies, :policy_decision_evidence_schema),
      policy_decision_rule_match_json_schema:
        dependency(dependencies, :policy_decision_rule_match_schema),
      policy_escalation_json_schema: dependency(dependencies, :policy_escalation_schema),
      priority_field_evidence_counts_json_schema:
        &OrbitalDynamics.Schema.GroundNetworkSchemaProviders.priority_field_evidence_counts/0,
      probability_json_schema: &CommonJsonSchema.probability/0,
      protection_decision_json_schema: dependency(dependencies, :protection_decision_schema),
      quality_gate_report_row_json_schema:
        dependency(dependencies, :quality_gate_report_row_schema),
      quality_gate_source_report_evidence_json_schema:
        dependency(dependencies, :quality_gate_source_report_evidence_schema),
      semantic_change_details_json_schema:
        &OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details/0,
      source_evidence_json_schema: dependency(dependencies, :source_evidence_schema),
      source_window_lineage_json_schema: fn ->
        OrbitalDynamics.Schema.CandidateDiffSchemaProviders.source_window_lineage(
          stable_id_pattern
        )
      end,
      stable_id_array_map_schema: fn ->
        CommonJsonSchema.stable_id_array_map(stable_id_pattern)
      end,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      timeline_activity_precondition_summary_source_json_schema:
        dependency(dependencies, :timeline_activity_precondition_summary_source_schema),
      timeline_activity_state_source_json_schema:
        dependency(dependencies, :timeline_activity_state_source_schema),
      timeline_diff_summary_source_json_schema:
        dependency(dependencies, :timeline_diff_summary_source_schema),
      timeline_identity_json_schema: dependency(dependencies, :timeline_identity_schema),
      timeline_lifecycle_state_source_json_schema:
        dependency(dependencies, :timeline_lifecycle_state_source_schema),
      timeline_link_json_schema: dependency(dependencies, :timeline_link_schema),
      timeline_preservation_source_json_schema:
        dependency(dependencies, :timeline_preservation_source_schema),
      timeline_protection_summary_json_schema:
        dependency(dependencies, :timeline_protection_summary_schema),
      timeline_transition_application_row_json_schema:
        dependency(dependencies, :timeline_transition_application_row_schema),
      timeline_transition_application_summary_source_json_schema:
        dependency(dependencies, :timeline_transition_application_summary_source_schema)
    ]
  end

  defp call(dependencies, name), do: dependencies |> dependency(name) |> apply([])
  defp dependency(dependencies, name), do: Map.fetch!(dependencies, name)
end
