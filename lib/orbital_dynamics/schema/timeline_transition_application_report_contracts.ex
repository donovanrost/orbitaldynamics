defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_optional_rows: 4, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_optional_exact_model_limits: 5,
      validate_string_list_allowed: 5,
      validate_string_list_items: 4
    ]

  def validate(
        issues,
        path,
        report,
        model_limits,
        count_validator,
        selected_activity_validator,
        application_row_validator
      )
      when is_list(model_limits) and is_function(count_validator, 3) and
             is_function(selected_activity_validator, 3) and
             is_function(application_row_validator, 3) do
    issues
    |> expect_equal(
      path,
      report,
      "schema_contract",
      "timeline_transition_application_report.v1"
    )
    |> expect_equal(
      path,
      report,
      "model",
      "artifact_only_timeline_transition_application"
    )
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "source_activity_count")
    |> expect_non_negative_integer(path, report, "replacement_activity_count")
    |> expect_non_negative_integer(path, report, "application_count")
    |> expect_non_negative_integer(path, report, "selected_activity_count")
    |> expect_non_negative_integer(path, report, "review_required_count")
    |> expect_optional_non_negative_integer(path, report, "preserved_source_count")
    |> expect_optional_non_negative_integer(path, report, "recorded_replacement_count")
    |> expect_optional_non_negative_integer(path, report, "withheld_review_count")
    |> validate_count_maps(path, report)
    |> expect_optional_non_negative_integer(
      path,
      report,
      "selected_timeline_integrity_review_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "selected_timeline_integrity_issue_count"
    )
    |> expect_optional_type(
      path,
      report,
      "selected_timeline_integrity_issue_types",
      :list
    )
    |> validate_string_list_allowed(
      path,
      report,
      "selected_timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      model_limits,
      "must match timeline report model limits"
    )
    |> expect_optional_type(path, report, "selected_activities", :list)
    |> expect_type(path, report, "applications", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> expect_optional_type(path, report, "timeline_revision", :map)
    |> OrbitalDynamics.Schema.TimelineRevisionContracts.validate_optional(
      path <> ".timeline_revision",
      Map.get(report, "timeline_revision")
    )
    |> validate_timeline_transition_application_report_counts(path, report, count_validator)
    |> validate_optional_rows(
      path <> ".selected_activities",
      Map.get(report, "selected_activities"),
      selected_activity_validator
    )
    |> validate_rows(
      path <> ".applications",
      Map.get(report, "applications", []),
      application_row_validator
    )
    |> OrbitalDynamics.Schema.TimelineRevisionContracts.validate_row_copies(
      path,
      report,
      "applications"
    )
  end

  defp validate_count_maps(issues, path, report) do
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
      expect_optional_type(acc, path, report, field, :map)
    end)
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp validate_timeline_transition_application_report_counts(
         issues,
         path,
         report,
         validator
       ),
       do: validator.(issues, path, report)
end
