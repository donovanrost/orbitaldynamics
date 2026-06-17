defmodule OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_array_fields [
    "invalid_activity_input_ids",
    "duplicate_dependency_activity_ids",
    "duplicate_dependency_timeline_ids",
    "duplicate_exclusivity_activity_ids",
    "duplicate_exclusivity_timeline_ids"
  ]

  @integer_fields [
    "activity_count",
    "row_count",
    "contact_count",
    "command_count",
    "locked_count",
    "approved_count",
    "executed_count",
    "source_window_lineage_count",
    "valid_activity_count",
    "invalid_activity_input_count",
    "terminal_exception_count",
    "execution_uncertainty_declared_count",
    "execution_uncertainty_missing_count",
    "dependency_count",
    "dependency_issue_count",
    "exclusivity_count",
    "exclusivity_issue_count",
    "timeline_integrity_review_count",
    "timeline_integrity_issue_count",
    "duplicate_timeline_identity_count",
    "duplicate_timeline_identity_activity_count"
  ]

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("source", _opts), do: %{"type" => "string"}

  def property("model", _opts) do
    %{"type" => "string", "const" => "selected_activity_operational_context_summary"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts)
      when field in [
             "activity_status_counts",
             "approval_status_counts",
             "required_operator_action_counts",
             "cadence_import_status_counts",
             "operational_kind_counts"
           ] do
    opts
    |> Keyword.fetch!(:capability)
    |> capability_values(field)
    |> CommonJsonSchema.enum_count_map()
  end

  defp capability_values(capability, "activity_status_counts"), do: capability.activity_statuses
  defp capability_values(capability, "approval_status_counts"), do: capability.approval_statuses

  defp capability_values(capability, "required_operator_action_counts"),
    do: capability.required_operator_actions

  defp capability_values(capability, "cadence_import_status_counts"),
    do: capability.cadence_import_statuses

  defp capability_values(capability, "operational_kind_counts"), do: capability.operational_kinds
end
