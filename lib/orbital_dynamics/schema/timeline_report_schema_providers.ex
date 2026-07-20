defmodule OrbitalDynamics.Schema.TimelineReportSchemaProviders do
  @moduledoc false

  alias OrbitalDynamics.Schema.{CommonJsonSchema, TimelineCoreSchemaProviders}

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)
    timeline_capability = Map.fetch!(dependencies, :timeline_capability)

    %{
      {:candidate_rejection_source_json_schema, 0} => fn ->
        candidate_rejection_source(stable_id_pattern, timeline_capability)
      end,
      {:operational_timeline_row_json_schema, 0} => fn ->
        operational_timeline_row(stable_id_pattern, timeline_capability)
      end,
      {:timeline_diff_row_json_schema, 0} => fn ->
        timeline_diff_row(stable_id_pattern, timeline_capability)
      end,
      {:timeline_integrity_issue_json_schema, 0} => fn ->
        timeline_integrity_issue(stable_id_pattern, timeline_capability)
      end,
      {:timeline_precondition_json_schema, 0} => fn ->
        timeline_precondition(timeline_capability)
      end,
      {:timeline_lifecycle_state_source_json_schema, 0} => fn ->
        timeline_lifecycle_state_source(stable_id_pattern, dependencies)
      end,
      {:timeline_activity_state_source_json_schema, 0} => fn ->
        timeline_activity_state_source(stable_id_pattern)
      end,
      {:timeline_activity_precondition_summary_source_json_schema, 0} => fn ->
        timeline_activity_precondition_summary_source(stable_id_pattern, dependencies)
      end,
      {:timeline_diff_summary_source_json_schema, 0} => fn ->
        timeline_diff_summary_source(stable_id_pattern, dependencies)
      end,
      {:timeline_dependency_impact_summary_source_json_schema, 0} => fn ->
        timeline_dependency_impact_summary_source(stable_id_pattern, dependencies)
      end,
      {:timeline_publication_summary_source_json_schema, 0} => fn ->
        timeline_publication_summary_source(stable_id_pattern, dependencies)
      end,
      {:timeline_transition_application_row_json_schema, 0} => fn ->
        timeline_transition_application_row(stable_id_pattern, timeline_capability)
      end,
      {:timeline_transition_application_summary_source_json_schema, 0} => fn ->
        timeline_transition_application_summary_source(stable_id_pattern, dependencies)
      end,
      {:timeline_dependency_impact_row_json_schema, 0} => fn ->
        timeline_dependency_impact_row(stable_id_pattern, dependencies)
      end,
      {:timeline_dependency_impact_handoff_json_schema_properties, 0} => fn ->
        timeline_dependency_impact_handoff_properties(stable_id_pattern, dependencies)
      end,
      {:timeline_publication_handoff_json_schema_properties, 0} => fn ->
        timeline_publication_handoff_properties(stable_id_pattern, dependencies)
      end,
      {:timeline_activity_precondition_handoff_json_schema_properties, 0} => fn ->
        timeline_activity_precondition_handoff_properties(stable_id_pattern, dependencies)
      end
    }
  end

  def operational_timeline_row(stable_id_pattern, timeline_capability) do
    OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.row_from_context(
      capability: timeline_capability,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      number_array_schema: &CommonJsonSchema.number_array/0,
      timeline_precondition_schema: fn -> timeline_precondition(timeline_capability) end,
      activity_context_schema: fn ->
        TimelineCoreSchemaProviders.activity_context(stable_id_pattern)
      end,
      timeline_integrity_issue_schema: fn ->
        timeline_integrity_issue(stable_id_pattern, timeline_capability)
      end
    )
  end

  def candidate_rejection_source(stable_id_pattern, timeline_capability) do
    OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.source_from_context(
      stable_id_pattern: stable_id_pattern,
      timeline_capability: timeline_capability,
      string_array_schema: &CommonJsonSchema.string_array/0,
      activity_context_schema: fn ->
        TimelineCoreSchemaProviders.activity_context(stable_id_pattern)
      end
    )
  end

  def timeline_precondition(timeline_capability) do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.precondition_from_context(
      capability: timeline_capability
    )
  end

  def timeline_integrity_issue(stable_id_pattern, timeline_capability) do
    OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.integrity_issue_from_context(
      capability: timeline_capability,
      stable_id_pattern: stable_id_pattern
    )
  end

  def timeline_diff_row(stable_id_pattern, timeline_capability) do
    OrbitalDynamics.Schema.TimelineDiffReportJsonSchema.row_from_context(
      capability: timeline_capability,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      activity_context_schema: fn ->
        TimelineCoreSchemaProviders.activity_context(stable_id_pattern)
      end,
      protection_decision_schema: fn ->
        TimelineCoreSchemaProviders.protection_decision(stable_id_pattern)
      end,
      lifecycle_transition_schema:
        &OrbitalDynamics.Schema.TimelineContextJsonSchema.lifecycle_transition/0,
      string_array_schema: &CommonJsonSchema.string_array/0,
      timeline_identity_schema: fn ->
        TimelineCoreSchemaProviders.timeline_identity(stable_id_pattern)
      end
    )
  end

  defp timeline_lifecycle_state_source(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.source_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      transition_decisions: dependency(dependencies, :timeline_transition_decisions),
      string_array_schema: &CommonJsonSchema.string_array/0,
      lifecycle_transition_schema:
        &OrbitalDynamics.Schema.TimelineContextJsonSchema.lifecycle_transition/0,
      activity_context_schema: fn ->
        TimelineCoreSchemaProviders.activity_context(stable_id_pattern)
      end,
      protection_decision_schema: fn ->
        lifecycle_state_source_protection_decision(stable_id_pattern)
      end
    )
  end

  defp timeline_activity_state_source(stable_id_pattern) do
    OrbitalDynamics.Schema.TimelineActivityStateJsonSchema.source_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      lifecycle_transition_schema:
        &OrbitalDynamics.Schema.TimelineContextJsonSchema.lifecycle_transition/0,
      protection_decision_schema: fn ->
        TimelineCoreSchemaProviders.protection_decision(stable_id_pattern)
      end
    )
  end

  defp timeline_activity_precondition_summary_source(stable_id_pattern, dependencies) do
    {name, contract} = contract(dependencies, :timeline_activity_precondition_summary_contract)

    OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryJsonSchema.summary_source_from_context(
      name,
      contract,
      [
        model_limits: dependency(dependencies, :timeline_report_model_limits),
        precondition_statuses: dependency(dependencies, :timeline_activity_precondition_statuses),
        string_array_schema: &CommonJsonSchema.string_array/0,
        precondition_schema: fn ->
          timeline_precondition(dependency(dependencies, :timeline_capability))
        end,
        stable_id_pattern: stable_id_pattern,
        stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
        timeline_identity_schema: fn ->
          TimelineCoreSchemaProviders.timeline_identity(stable_id_pattern)
        end
      ],
      dependency(dependencies, :default_property)
    )
  end

  defp lifecycle_state_source_protection_decision(stable_id_pattern) do
    %{
      "oneOf" => [
        TimelineCoreSchemaProviders.protection_decision(stable_id_pattern),
        %{"type" => "string"}
      ]
    }
  end

  defp timeline_diff_summary_source(stable_id_pattern, dependencies) do
    {name, contract} = contract(dependencies, :timeline_diff_summary_contract)

    OrbitalDynamics.Schema.TimelineDiffSummaryJsonSchema.summary_source_from_context(
      name,
      contract,
      [
        model_limits: dependency(dependencies, :timeline_report_model_limits),
        row_schema: fn ->
          timeline_diff_row(stable_id_pattern, dependency(dependencies, :timeline_capability))
        end,
        capability: dependency(dependencies, :timeline_capability),
        stable_id_pattern: stable_id_pattern
      ],
      dependency(dependencies, :default_property)
    )
  end

  defp timeline_dependency_impact_summary_source(stable_id_pattern, dependencies) do
    {name, contract} = contract(dependencies, :timeline_dependency_impact_summary_contract)

    OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema.summary_source_from_context(
      name,
      contract,
      [
        stable_id_pattern: stable_id_pattern,
        stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
        required_operator_actions: dependency(dependencies, :timeline_required_operator_actions),
        model_limits: dependency(dependencies, :timeline_report_model_limits)
      ],
      dependency(dependencies, :default_property)
    )
  end

  defp timeline_publication_summary_source(stable_id_pattern, dependencies) do
    {name, contract} = contract(dependencies, :timeline_publication_summary_contract)

    OrbitalDynamics.Schema.TimelinePublicationSummaryJsonSchema.summary_source_from_context(
      name,
      contract,
      [
        stable_id_pattern: stable_id_pattern,
        timeline_diff_summary_source_schema: fn ->
          timeline_diff_summary_source(stable_id_pattern, dependencies)
        end,
        timeline_dependency_impact_summary_source_schema: fn ->
          timeline_dependency_impact_summary_source(stable_id_pattern, dependencies)
        end,
        stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
        stable_id_array_map_schema: fn ->
          CommonJsonSchema.stable_id_array_map(stable_id_pattern)
        end,
        model_limits: dependency(dependencies, :timeline_report_model_limits)
      ],
      dependency(dependencies, :default_property)
    )
  end

  defp timeline_transition_application_row(stable_id_pattern, timeline_capability) do
    OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.application_row_from_context(
      timeline_capability: timeline_capability,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      lifecycle_transition_schema:
        &OrbitalDynamics.Schema.TimelineContextJsonSchema.lifecycle_transition/0,
      protection_decision_schema: fn ->
        TimelineCoreSchemaProviders.protection_decision(stable_id_pattern)
      end,
      timeline_diff_row_schema: fn ->
        timeline_diff_row(stable_id_pattern, timeline_capability)
      end
    )
  end

  defp timeline_transition_application_summary_source(stable_id_pattern, dependencies) do
    {name, contract} = contract(dependencies, :timeline_transition_application_summary_contract)
    timeline_capability = dependency(dependencies, :timeline_capability)

    OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.summary_source_from_context(
      name,
      contract,
      [
        timeline_capability: timeline_capability,
        stable_id_pattern: stable_id_pattern,
        stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
        stable_id_array_map_schema: fn ->
          CommonJsonSchema.stable_id_array_map(stable_id_pattern)
        end,
        string_array_schema: &CommonJsonSchema.string_array/0,
        lifecycle_transition_schema:
          &OrbitalDynamics.Schema.TimelineContextJsonSchema.lifecycle_transition/0,
        protection_decision_schema: fn ->
          TimelineCoreSchemaProviders.protection_decision(stable_id_pattern)
        end,
        timeline_diff_row_schema: fn ->
          timeline_diff_row(stable_id_pattern, timeline_capability)
        end,
        timeline_identity_schema: fn ->
          TimelineCoreSchemaProviders.timeline_identity(stable_id_pattern)
        end,
        activity_context_schema: fn ->
          TimelineCoreSchemaProviders.activity_context(stable_id_pattern)
        end,
        model_limits: dependency(dependencies, :timeline_report_model_limits),
        enum_count_map_schema: &CommonJsonSchema.enum_count_map/1
      ],
      dependency(dependencies, :default_property)
    )
  end

  defp timeline_dependency_impact_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      required_operator_actions: dependency(dependencies, :timeline_required_operator_actions)
    )
  end

  defp timeline_dependency_impact_handoff_properties(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.dependency_impact_properties(
      stable_id_array_schema: CommonJsonSchema.stable_id_array(stable_id_pattern),
      timeline_dependency_impact_row_schema:
        timeline_dependency_impact_row(stable_id_pattern, dependencies)
    )
  end

  defp timeline_publication_handoff_properties(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.publication_properties(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: CommonJsonSchema.stable_id_array(stable_id_pattern),
      stable_id_array_map_schema: CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      count_map_schema: CommonJsonSchema.non_negative_integer_count_map(),
      timeline_publication_summary_source_schema:
        timeline_publication_summary_source(stable_id_pattern, dependencies)
    )
  end

  defp timeline_activity_precondition_handoff_properties(stable_id_pattern, dependencies) do
    timeline_capability = dependency(dependencies, :timeline_capability)

    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.activity_precondition_properties(
      timeline_capability: apply(timeline_capability, []),
      stable_id_array_schema: CommonJsonSchema.stable_id_array(stable_id_pattern),
      string_array_schema: CommonJsonSchema.string_array(),
      timeline_precondition_schema: timeline_precondition(timeline_capability),
      timeline_activity_precondition_summary_source_schema:
        timeline_activity_precondition_summary_source(stable_id_pattern, dependencies)
    )
  end

  defp contract(dependencies, name) do
    contract_name = Map.fetch!(dependencies, name)
    {contract_name, dependencies |> Map.fetch!(:registry_contract) |> apply([contract_name])}
  end

  defp dependency(dependencies, name), do: Map.fetch!(dependencies, name)
end
