defmodule OrbitalDynamics.Schema.CadenceReviewSchemaProviders do
  @moduledoc false

  def property_providers(stable_id_pattern, opts)
      when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    [
      branch_scoped_downlink_context_json_schema_properties: fn ->
        OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders.branch_scoped_downlink_context_properties(
          stable_id_pattern
        )
      end,
      cadence_import_operational_readiness_evidence_json_schema_properties:
        Map.fetch!(dependencies, :cadence_import_operational_readiness_evidence_properties),
      cadence_import_resource_projection_evidence_json_schema_properties:
        Map.fetch!(dependencies, :cadence_import_resource_projection_evidence_properties),
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
end
