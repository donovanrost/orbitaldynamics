defmodule OrbitalDynamics.Schema.TimelineDiffSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "source_activity_count",
    "replacement_activity_count",
    "row_count",
    "added_count",
    "removed_count",
    "changed_count",
    "unchanged_count",
    "review_required_count",
    "duplicate_timeline_identity_count",
    "invalid_source_activity_input_count",
    "invalid_replacement_activity_input_count"
  ]

  @stable_id_array_fields [
    "added_timeline_ids",
    "removed_timeline_ids",
    "changed_timeline_ids",
    "unchanged_timeline_ids",
    "duplicate_timeline_identity_ids",
    "invalid_source_activity_input_ids",
    "invalid_replacement_activity_input_ids",
    "review_timeline_ids"
  ]

  @stable_id_array_map_fields [
    "review_timeline_ids_by_required_operator_action",
    "review_timeline_ids_by_status_transition_category",
    "review_timeline_ids_by_approval_transition_category",
    "timeline_ids_by_changed_field"
  ]

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "timeline_diff_summary.v1"}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_diff_summary"}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "const" => "timeline_diff_report.v1"}
  end

  def property("source", _opts), do: %{"type" => "string"}

  def property("review_rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts)
      when field in [
             "diff_status_counts",
             "transition_decision_counts",
             "required_operator_action_counts",
             "status_transition_category_counts",
             "approval_transition_category_counts"
           ] do
    opts
    |> Keyword.fetch!(:capability)
    |> capability_values(field)
    |> CommonJsonSchema.enum_count_map()
  end

  def property("changed_field_counts", _opts),
    do: CommonJsonSchema.non_negative_integer_count_map()

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  defp capability_values(capability, "diff_status_counts"), do: capability.timeline_diff_statuses

  defp capability_values(capability, "transition_decision_counts"),
    do: capability.transition_decisions

  defp capability_values(capability, "required_operator_action_counts"),
    do: capability.timeline_diff_required_operator_actions

  defp capability_values(capability, "status_transition_category_counts"),
    do: capability.status_transition_categories

  defp capability_values(capability, "approval_transition_category_counts"),
    do: capability.approval_transition_categories
end
