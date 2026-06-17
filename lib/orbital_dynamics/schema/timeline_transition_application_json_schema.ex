defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema do
  @moduledoc false

  @report "timeline_transition_application_report.v1"
  @summary "timeline_transition_application_summary.v1"

  @report_integer_fields [
    "source_activity_count",
    "replacement_activity_count",
    "application_count",
    "selected_activity_count",
    "review_required_count",
    "preserved_source_count",
    "recorded_replacement_count",
    "withheld_review_count",
    "selected_timeline_integrity_issue_count",
    "selected_timeline_integrity_review_count"
  ]

  @report_enum_count_fields [
    "application_status_counts",
    "transition_decision_counts",
    "required_operator_action_counts",
    "status_transition_counts",
    "approval_transition_counts",
    "status_transition_category_counts",
    "approval_transition_category_counts"
  ]

  @summary_integer_fields @report_integer_fields

  @summary_enum_count_fields [
    "application_status_counts",
    "transition_decision_counts",
    "required_operator_action_counts",
    "status_transition_category_counts",
    "approval_transition_category_counts"
  ]

  @summary_stable_id_array_fields [
    "selected_activity_ids",
    "selected_timeline_ids",
    "review_timeline_ids",
    "review_activity_ids",
    "preserved_source_timeline_ids",
    "recorded_replacement_timeline_ids",
    "withheld_review_timeline_ids"
  ]

  @summary_stable_id_array_map_fields [
    "review_timeline_ids_by_required_operator_action",
    "review_timeline_ids_by_status_transition_category",
    "review_timeline_ids_by_approval_transition_category"
  ]

  def property("source", _contract_name, _opts) do
    %{"type" => "string"}
  end

  def property("model", @report, _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_transition_application"}
  end

  def property("schema_contract", @summary, _opts) do
    %{"type" => "string", "const" => @summary}
  end

  def property("model", @summary, _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_transition_application_summary"}
  end

  def property("validation_level", @summary, _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("source_artifact_type", @summary, _opts) do
    %{"type" => "string", "const" => @report}
  end

  def property("applications", @report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :application_row_schema)}
  end

  def property("selected_activities", @report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :selected_activity_schema)}
  end

  def property("review_applications", @summary, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :application_row_schema)}
  end

  def property("model_limits", contract_name, opts) when contract_name in [@report, @summary] do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("selected_timeline_integrity_issue_types", contract_name, opts)
      when contract_name in [@report, @summary] do
    %{
      "type" => "array",
      "items" => %{
        "type" => "string",
        "enum" => Keyword.fetch!(opts, :timeline_capability).timeline_integrity_issue_types
      }
    }
  end

  def property(field, @report, _opts) when field in @report_integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, @summary, _opts) when field in @summary_integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, @report, opts) when field in @report_enum_count_fields do
    Keyword.fetch!(opts, :enum_count_map_schema).(
      enum_values(field, Keyword.fetch!(opts, :timeline_capability))
    )
  end

  def property(field, @summary, opts) when field in @summary_enum_count_fields do
    Keyword.fetch!(opts, :enum_count_map_schema).(
      enum_values(field, Keyword.fetch!(opts, :timeline_capability))
    )
  end

  def property(field, @summary, opts) when field in @summary_stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, @summary, opts) when field in @summary_stable_id_array_map_fields do
    Keyword.fetch!(opts, :stable_id_array_map_schema)
  end

  def property("assumptions", @summary, _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp enum_values("application_status_counts", capability) do
    capability.transition_application_statuses
  end

  defp enum_values("transition_decision_counts", capability) do
    capability.transition_decisions
  end

  defp enum_values("required_operator_action_counts", capability) do
    capability.transition_decision_required_operator_actions
  end

  defp enum_values("status_transition_counts", capability) do
    capability.lifecycle_transition_types
  end

  defp enum_values("approval_transition_counts", capability) do
    capability.lifecycle_transition_types
  end

  defp enum_values("status_transition_category_counts", capability) do
    capability.status_transition_categories
  end

  defp enum_values("approval_transition_category_counts", capability) do
    capability.approval_transition_categories
  end
end
