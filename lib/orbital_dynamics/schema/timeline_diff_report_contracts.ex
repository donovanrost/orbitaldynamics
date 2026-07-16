defmodule OrbitalDynamics.Schema.TimelineDiffReportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.TimelineDiffRowContracts

  import OrbitalDynamics.Schema.CollectionAggregation,
    only: [changed_field_frequency_map: 1, frequency_map: 2, nested_frequency_map: 3]

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  def validate(issues, path, report, timeline_report_model_limits)
      when is_list(timeline_report_model_limits) do
    issues
    |> expect_equal(path, report, "schema_contract", "timeline_diff_report.v1")
    |> expect_equal(path, report, "model", "timeline_identity_activity_diff")
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "source_activity_count")
    |> expect_non_negative_integer(path, report, "replacement_activity_count")
    |> expect_non_negative_integer(path, report, "row_count")
    |> expect_non_negative_integer(path, report, "added_count")
    |> expect_non_negative_integer(path, report, "removed_count")
    |> expect_non_negative_integer(path, report, "changed_count")
    |> expect_non_negative_integer(path, report, "unchanged_count")
    |> expect_non_negative_integer(path, report, "review_required_count")
    |> expect_optional_type(path, report, "diff_status_counts", :map)
    |> expect_optional_type(path, report, "required_operator_action_counts", :map)
    |> expect_optional_type(path, report, "transition_decision_counts", :map)
    |> expect_optional_type(path, report, "changed_field_counts", :map)
    |> expect_optional_type(path, report, "status_transition_counts", :map)
    |> expect_optional_type(path, report, "approval_transition_counts", :map)
    |> expect_optional_type(path, report, "status_transition_category_counts", :map)
    |> expect_optional_type(path, report, "approval_transition_category_counts", :map)
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_timeline_identity_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_source_timeline_identity_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_replacement_timeline_identity_count"
    )
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      timeline_report_model_limits,
      "must match timeline report model limits"
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_counts(path, report)
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> TimelineDiffRowContracts.validate(acc, row_path, row) end
    )
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> validate_non_negative_integer_count_map(
      path <> ".diff_status_counts",
      Map.get(report, "diff_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".transition_decision_counts",
      Map.get(report, "transition_decision_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".changed_field_counts",
      Map.get(report, "changed_field_counts")
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
    |> expect_field_equals(path, report, "row_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "added_count",
      Enum.count(rows, &(&1["diff_status"] == "added"))
    )
    |> expect_field_equals(
      path,
      report,
      "removed_count",
      Enum.count(rows, &(&1["diff_status"] == "removed"))
    )
    |> expect_field_equals(
      path,
      report,
      "changed_count",
      Enum.count(rows, &(&1["diff_status"] == "changed"))
    )
    |> expect_field_equals(
      path,
      report,
      "unchanged_count",
      Enum.count(rows, &(&1["diff_status"] == "unchanged"))
    )
    |> expect_field_equals(
      path,
      report,
      "review_required_count",
      Enum.count(rows, &(&1["requires_operator_review"] == true))
    )
    |> expect_field_equals(
      path,
      report,
      "diff_status_counts",
      frequency_map(rows, "diff_status"),
      "must equal row-derived diff_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "transition_decision_counts",
      frequency_map(rows, "transition_decision"),
      "must equal row-derived transition_decision_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "changed_field_counts",
      changed_field_frequency_map(rows),
      "must equal row-derived changed_field_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "status_transition_counts",
      nested_frequency_map(rows, "status_transition", "transition_type"),
      "must equal row-derived status_transition_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "approval_transition_counts",
      nested_frequency_map(rows, "approval_transition", "transition_type"),
      "must equal row-derived approval_transition_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "status_transition_category_counts",
      nested_frequency_map(rows, "status_transition", "transition_category"),
      "must equal row-derived status_transition_category_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "approval_transition_category_counts",
      nested_frequency_map(rows, "approval_transition", "transition_category"),
      "must equal row-derived approval_transition_category_counts"
    )
  end

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
