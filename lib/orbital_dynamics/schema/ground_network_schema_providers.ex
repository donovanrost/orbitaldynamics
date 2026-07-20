defmodule OrbitalDynamics.Schema.GroundNetworkSchemaProviders do
  @moduledoc false

  alias OrbitalDynamics.Schema.{CommonJsonSchema, TimelineContextJsonSchema}

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:contact_allocation_capacity_pack_group_json_schema, 0} => fn ->
        contact_allocation_capacity_pack_group(stable_id_pattern, dependencies)
      end,
      {:contact_allocation_row_json_schema, 0} => fn ->
        contact_allocation_row(stable_id_pattern, dependencies)
      end,
      {:contact_contention_group_json_schema, 0} => fn ->
        contact_contention_group(stable_id_pattern, dependencies)
      end,
      {:contact_contention_recommendation_json_schema, 0} => fn ->
        contact_contention_recommendation(stable_id_pattern, dependencies)
      end,
      {:contact_contention_resolution_policy_json_schema, 0} => fn ->
        contact_contention_resolution_policy(stable_id_pattern)
      end,
      {:link_capacity_row_json_schema, 0} => fn ->
        link_capacity_row(stable_id_pattern, dependencies)
      end,
      {:provider_counteroffer_row_json_schema, 0} => fn ->
        provider_counteroffer_row(stable_id_pattern, dependencies)
      end,
      {:relay_data_path_row_json_schema, 0} => fn ->
        relay_data_path_row(stable_id_pattern)
      end
    }
  end

  def contact_allocation_capacity_requirement_row(stable_id_pattern) do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.capacity_requirement_row_from_deps(
      stable_id_pattern: stable_id_pattern
    )
  end

  def contact_contention_deferred_priority(stable_id_pattern) do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.deferred_priority_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end

  def priority_field_evidence_counts do
    %{
      "type" => "object",
      "additionalProperties" => %{"type" => "integer", "minimum" => 0}
    }
  end

  defp provider_counteroffer_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ProviderCounterofferJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern,
      station_calendar: Map.fetch!(dependencies, :station_calendar_capability)
    )
  end

  defp relay_data_path_row(stable_id_pattern) do
    OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.row_from_deps(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      custody_statuses: &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.custody_statuses/0,
      latency_statuses: &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.latency_statuses/0,
      risk_statuses: &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.risk_statuses/0
    )
  end

  defp link_capacity_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.LinkCapacityReportJsonSchema.row_from_deps(
      stable_id_pattern: stable_id_pattern,
      probability_schema: &CommonJsonSchema.probability/0,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      count_map_schema: &CommonJsonSchema.non_negative_integer_count_map/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      policy_decision_schema: Map.fetch!(dependencies, :policy_decision_schema)
    )
  end

  defp contact_allocation_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.row_from_deps(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      number_array_schema: &CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivation_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivation/0,
      approval_requirement_schema: Map.fetch!(dependencies, :approval_requirement_schema),
      policy_decision_rule_match_schema:
        Map.fetch!(dependencies, :policy_decision_rule_match_schema),
      policy_decision_schema: Map.fetch!(dependencies, :policy_decision_schema),
      source_contention_recommendation_schema: fn ->
        contact_contention_recommendation(stable_id_pattern, dependencies)
      end,
      contact_allocation_capability:
        &OrbitalDynamics.Communications.ContactAllocation.capabilities/0,
      station_calendar_capability: Map.fetch!(dependencies, :station_calendar_capability),
      deferred_priority_schema: fn ->
        contact_contention_deferred_priority(stable_id_pattern)
      end,
      priority_field_evidence_counts_schema: &priority_field_evidence_counts/0
    )
  end

  defp contact_allocation_capacity_pack_group(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.capacity_pack_group_from_deps(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      capacity_requirement_row_schema: fn ->
        contact_allocation_capacity_requirement_row(stable_id_pattern)
      end,
      source_contention_recommendation_schema: fn ->
        contact_contention_recommendation(stable_id_pattern, dependencies)
      end
    )
  end

  defp contact_contention_group(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.group_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      number_array_schema: &CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      source_contact_candidate_schema: fn ->
        contact_contention_source_contact_candidate(stable_id_pattern)
      end,
      policy_decision_schema: Map.fetch!(dependencies, :policy_decision_schema)
    )
  end

  defp contact_contention_recommendation(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.recommendation_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      number_array_schema: &CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      deferred_priority_schema: fn ->
        contact_contention_deferred_priority(stable_id_pattern)
      end,
      source_contact_candidate_schema: fn ->
        contact_contention_source_contact_candidate(stable_id_pattern)
      end,
      priority_field_evidence_counts_schema: &priority_field_evidence_counts/0,
      policy_decision_schema: Map.fetch!(dependencies, :policy_decision_schema)
    )
  end

  defp contact_contention_source_contact_candidate(stable_id_pattern) do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.source_contact_candidate_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end

  defp contact_contention_resolution_policy(stable_id_pattern) do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.resolution_policy_from_context(
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0
    )
  end
end
