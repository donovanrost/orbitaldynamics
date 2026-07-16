defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationReportContracts do
  @moduledoc false

  def validate(issues, path, report, model_limits, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      report,
      "schema_contract",
      "timeline_transition_application_report.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "artifact_only_timeline_transition_application"
    )
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "source_activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "replacement_activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "application_count")
    |> expect_non_negative_integer(callbacks, path, report, "selected_activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "review_required_count")
    |> expect_optional_non_negative_integer(callbacks, path, report, "preserved_source_count")
    |> expect_optional_non_negative_integer(callbacks, path, report, "recorded_replacement_count")
    |> expect_optional_non_negative_integer(callbacks, path, report, "withheld_review_count")
    |> validate_count_maps(callbacks, path, report)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "selected_timeline_integrity_review_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "selected_timeline_integrity_issue_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "selected_timeline_integrity_issue_types",
      :list
    )
    |> validate_string_list_allowed(
      callbacks,
      path,
      report,
      "selected_timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      model_limits,
      "must match timeline report model limits"
    )
    |> expect_optional_type(callbacks, path, report, "selected_activities", :list)
    |> expect_type(callbacks, path, report, "applications", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_timeline_transition_application_report_counts(callbacks, path, report)
    |> validate_optional_rows(
      callbacks,
      path <> ".selected_activities",
      Map.get(report, "selected_activities"),
      &validate_timeline_transition_selected_activity(&1, callbacks, &2, &3)
    )
    |> validate_rows(
      callbacks,
      path <> ".applications",
      Map.get(report, "applications", []),
      &validate_timeline_transition_application_row(&1, callbacks, &2, &3)
    )
  end

  defp validate_count_maps(issues, callbacks, path, report) do
    count_map_fields = [
      "application_status_counts",
      "transition_decision_counts",
      "required_operator_action_counts",
      "status_transition_counts",
      "approval_transition_counts",
      "status_transition_category_counts",
      "approval_transition_category_counts"
    ]

    Enum.reduce(count_map_fields, issues, fn field, acc ->
      expect_optional_type(acc, callbacks, path, report, field, :map)
    end)
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp expect_equal(issues, callbacks, path, report, field, expected) do
    callback!(callbacks, :expect_equal).(issues, path, report, field, expected)
  end

  defp expect_non_negative_integer(issues, callbacks, path, report, field) do
    callback!(callbacks, :expect_non_negative_integer).(issues, path, report, field)
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, report, field) do
    callback!(callbacks, :expect_optional_non_negative_integer).(issues, path, report, field)
  end

  defp expect_optional_type(issues, callbacks, path, report, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, report, field, type)
  end

  defp expect_type(issues, callbacks, path, report, field, type) do
    callback!(callbacks, :expect_type).(issues, path, report, field, type)
  end

  defp validate_optional_exact_model_limits(issues, callbacks, path, report, expected, message) do
    callback!(callbacks, :validate_optional_exact_model_limits).(
      issues,
      path,
      report,
      expected,
      message
    )
  end

  defp validate_optional_rows(issues, callbacks, path, rows, validator) do
    callback!(callbacks, :validate_optional_rows).(issues, path, rows, validator)
  end

  defp validate_rows(issues, callbacks, path, rows, validator) do
    callback!(callbacks, :validate_rows).(issues, path, rows, validator)
  end

  defp validate_string_list_allowed(issues, callbacks, path, report, field, allowed) do
    callback!(callbacks, :validate_string_list_allowed).(issues, path, report, field, allowed)
  end

  defp validate_string_list_items(issues, callbacks, path, report, field) do
    callback!(callbacks, :validate_string_list_items).(issues, path, report, field)
  end

  defp validate_timeline_transition_application_report_counts(issues, callbacks, path, report) do
    callback!(callbacks, :validate_timeline_transition_application_report_counts).(
      issues,
      path,
      report
    )
  end

  defp validate_timeline_transition_application_row(issues, callbacks, path, row) do
    callback!(callbacks, :validate_timeline_transition_application_row).(issues, path, row)
  end

  defp validate_timeline_transition_selected_activity(issues, callbacks, path, activity) do
    callback!(callbacks, :validate_timeline_transition_selected_activity).(
      issues,
      path,
      activity
    )
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
