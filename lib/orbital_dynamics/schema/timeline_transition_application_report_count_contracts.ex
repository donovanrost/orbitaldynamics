defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationReportCountContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    applications =
      report
      |> Map.get("applications", [])
      |> Enum.filter(&is_map/1)

    selected_activities =
      report
      |> Map.get("selected_activities")
      |> case do
        activities when is_list(activities) -> Enum.filter(activities, &is_map/1)
        _activities -> nil
      end

    issues
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".application_status_counts",
      Map.get(report, "application_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".transition_decision_counts",
      Map.get(report, "transition_decision_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_transition_counts",
      Map.get(report, "status_transition_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".approval_transition_counts",
      Map.get(report, "approval_transition_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_transition_category_counts",
      Map.get(report, "status_transition_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".approval_transition_category_counts",
      Map.get(report, "approval_transition_category_counts")
    )
    |> expect_field_equals(callbacks, path, report, "application_count", length(applications))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "selected_activity_count",
      if(is_list(selected_activities), do: length(selected_activities), else: nil)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_required_count",
      Enum.count(applications, &(&1["requires_operator_review"] == true))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "application_status_counts",
      frequency_map(callbacks, applications, "application_status"),
      "must equal application-derived application_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "transition_decision_counts",
      frequency_map(callbacks, applications, "transition_decision"),
      "must equal application-derived transition_decision_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_operator_action_counts",
      frequency_map(callbacks, applications, "required_operator_action"),
      "must equal application-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_transition_counts",
      nested_frequency_map(callbacks, applications, "status_transition", "transition_type"),
      "must equal application-derived status_transition_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "approval_transition_counts",
      nested_frequency_map(callbacks, applications, "approval_transition", "transition_type"),
      "must equal application-derived approval_transition_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_transition_category_counts",
      nested_frequency_map(callbacks, applications, "status_transition", "transition_category"),
      "must equal application-derived status_transition_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "approval_transition_category_counts",
      nested_frequency_map(callbacks, applications, "approval_transition", "transition_category"),
      "must equal application-derived approval_transition_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "preserved_source_count",
      Enum.count(applications, &(&1["transition_decision"] == "preserve_source"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "recorded_replacement_count",
      Enum.count(applications, &(&1["selected_activity_source"] == "replacement"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "withheld_review_count",
      Enum.count(applications, &(&1["application_status"] == "operator_review_required"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "selected_timeline_integrity_review_count",
      Enum.count(
        selected_activities || [],
        &(&1["timeline_integrity_status"] == "review_required")
      )
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "selected_timeline_integrity_issue_count",
      sum_row_numbers(callbacks, selected_activities || [], "timeline_integrity_issue_count")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "selected_timeline_integrity_issue_types",
      selected_timeline_integrity_issue_types(callbacks, selected_activities || []),
      "must equal selected-activity-derived selected_timeline_integrity_issue_types"
    )
  end

  defp selected_timeline_integrity_issue_types(callbacks, selected_activities) do
    selected_activities
    |> Enum.flat_map(&list_value(callbacks, &1, "timeline_integrity_issue_types"))
    |> sorted_unique_binary_values(callbacks)
  end

  defp expect_field_equals(issues, callbacks, path, report, field, expected) do
    callback!(callbacks, :expect_field_equals).(issues, path, report, field, expected)
  end

  defp expect_field_equals(issues, callbacks, path, report, field, expected, message) do
    callback!(callbacks, :expect_field_equals_with_message).(
      issues,
      path,
      report,
      field,
      expected,
      message
    )
  end

  defp frequency_map(callbacks, rows, field) do
    callback!(callbacks, :frequency_map).(rows, field)
  end

  defp list_value(callbacks, map, key) do
    callback!(callbacks, :list_value).(map, key)
  end

  defp nested_frequency_map(callbacks, rows, field, nested_field) do
    callback!(callbacks, :nested_frequency_map).(rows, field, nested_field)
  end

  defp sorted_unique_binary_values(values, callbacks) do
    callback!(callbacks, :sorted_unique_binary_values).(values)
  end

  defp sum_row_numbers(callbacks, rows, field) do
    callback!(callbacks, :sum_row_numbers).(rows, field)
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    callback!(callbacks, :validate_non_negative_integer_count_map).(issues, path, counts)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
