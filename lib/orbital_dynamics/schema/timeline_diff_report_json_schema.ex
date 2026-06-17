defmodule OrbitalDynamics.Schema.TimelineDiffReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "source_activity_count",
    "replacement_activity_count",
    "valid_source_activity_count",
    "valid_replacement_activity_count",
    "invalid_source_activity_input_count",
    "invalid_replacement_activity_input_count",
    "row_count",
    "added_count",
    "removed_count",
    "changed_count",
    "unchanged_count",
    "review_required_count",
    "duplicate_timeline_identity_count",
    "duplicate_source_timeline_identity_count",
    "duplicate_replacement_timeline_identity_count"
  ]

  def property("source", _opts), do: %{"type" => "string"}

  def property("model", _opts) do
    %{"type" => "string", "const" => "timeline_identity_activity_diff"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts)
      when field in [
             "invalid_source_activity_input_ids",
             "invalid_replacement_activity_input_ids"
           ] do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts)
      when field in [
             "diff_status_counts",
             "required_operator_action_counts",
             "transition_decision_counts",
             "status_transition_counts",
             "approval_transition_counts",
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

  defp capability_values(capability, "diff_status_counts"), do: capability.timeline_diff_statuses

  defp capability_values(capability, "required_operator_action_counts"),
    do: capability.timeline_diff_required_operator_actions

  defp capability_values(capability, "transition_decision_counts"),
    do: capability.transition_decisions

  defp capability_values(capability, "status_transition_counts"),
    do: capability.lifecycle_transition_types

  defp capability_values(capability, "approval_transition_counts"),
    do: capability.lifecycle_transition_types

  defp capability_values(capability, "status_transition_category_counts"),
    do: capability.status_transition_categories

  defp capability_values(capability, "approval_transition_category_counts"),
    do: capability.approval_transition_categories
end
