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
end
