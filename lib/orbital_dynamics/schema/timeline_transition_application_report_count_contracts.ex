defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationReportCountContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation,
    only: [
      frequency_map: 2,
      nested_frequency_map: 3,
      sorted_unique_binary_values: 1,
      sum_row_numbers: 2
    ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_field_equals: 6, validate_non_negative_integer_count_map: 3]

  def validate(issues, path, report) do
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
      path <> ".application_status_counts",
      Map.get(report, "application_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".transition_decision_counts",
      Map.get(report, "transition_decision_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".status_transition_counts",
      Map.get(report, "status_transition_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".approval_transition_counts",
      Map.get(report, "approval_transition_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".status_transition_category_counts",
      Map.get(report, "status_transition_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".approval_transition_category_counts",
      Map.get(report, "approval_transition_category_counts")
    )
    |> expect_field_equals(path, report, "application_count", length(applications))
    |> expect_field_equals(
      path,
      report,
      "selected_activity_count",
      if(is_list(selected_activities), do: length(selected_activities), else: nil)
    )
    |> expect_field_equals(
      path,
      report,
      "review_required_count",
      Enum.count(applications, &(&1["requires_operator_review"] == true))
    )
    |> expect_field_equals(
      path,
      report,
      "application_status_counts",
      frequency_map(applications, "application_status"),
      "must equal application-derived application_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "transition_decision_counts",
      frequency_map(applications, "transition_decision"),
      "must equal application-derived transition_decision_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "required_operator_action_counts",
      frequency_map(applications, "required_operator_action"),
      "must equal application-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "status_transition_counts",
      nested_frequency_map(applications, "status_transition", "transition_type"),
      "must equal application-derived status_transition_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "approval_transition_counts",
      nested_frequency_map(applications, "approval_transition", "transition_type"),
      "must equal application-derived approval_transition_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "status_transition_category_counts",
      nested_frequency_map(applications, "status_transition", "transition_category"),
      "must equal application-derived status_transition_category_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "approval_transition_category_counts",
      nested_frequency_map(applications, "approval_transition", "transition_category"),
      "must equal application-derived approval_transition_category_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "preserved_source_count",
      Enum.count(applications, &(&1["transition_decision"] == "preserve_source"))
    )
    |> expect_field_equals(
      path,
      report,
      "recorded_replacement_count",
      Enum.count(applications, &(&1["selected_activity_source"] == "replacement"))
    )
    |> expect_field_equals(
      path,
      report,
      "withheld_review_count",
      Enum.count(applications, &(&1["application_status"] == "operator_review_required"))
    )
    |> expect_field_equals(
      path,
      report,
      "selected_timeline_integrity_review_count",
      Enum.count(
        selected_activities || [],
        &(&1["timeline_integrity_status"] == "review_required")
      )
    )
    |> expect_field_equals(
      path,
      report,
      "selected_timeline_integrity_issue_count",
      sum_row_numbers(selected_activities || [], "timeline_integrity_issue_count")
    )
    |> expect_field_equals(
      path,
      report,
      "selected_timeline_integrity_issue_types",
      selected_timeline_integrity_issue_types(selected_activities || []),
      "must equal selected-activity-derived selected_timeline_integrity_issue_types"
    )
  end

  defp selected_timeline_integrity_issue_types(selected_activities) do
    selected_activities
    |> Enum.flat_map(&list_value(&1, "timeline_integrity_issue_types"))
    |> sorted_unique_binary_values()
  end

  defp expect_field_equals(issues, path, report, field, nil),
    do: expect_field_equals(issues, path, report, field, nil, nil)

  defp expect_field_equals(issues, path, report, field, expected),
    do: expect_field_equals(issues, path, report, field, expected, "must equal #{expected}")

  defp list_value(map, key) when is_map(map), do: Map.get(map, key) || []
  defp list_value(_map, _key), do: []
end
