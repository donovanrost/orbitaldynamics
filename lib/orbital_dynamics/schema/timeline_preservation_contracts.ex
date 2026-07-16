defmodule OrbitalDynamics.Schema.TimelinePreservationContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

  alias OrbitalDynamics.Schema.{CollectionValidation, TimelineIdentityContracts}

  def validate_report(issues, path, report, model_limits) when is_list(model_limits) do
    decision_counts = Map.get(report, "protection_decision_counts", %{})
    preserve_count = protection_count(decision_counts, "preserve")
    review_count = protection_count(decision_counts, "review_change")
    mutable_count = protection_count(decision_counts, "mutable")

    issues
    |> expect_equal(
      path,
      report,
      "schema_contract",
      "timeline_preservation_report.v1"
    )
    |> expect_equal(
      path,
      report,
      "model",
      "artifact_only_lifecycle_preservation_summary"
    )
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "activity_count")
    |> expect_non_negative_integer(path, report, "mutable_activity_count")
    |> expect_non_negative_integer(path, report, "preserve_activity_count")
    |> expect_non_negative_integer(path, report, "review_change_activity_count")
    |> expect_non_negative_integer(
      path,
      report,
      "preservation_sensitive_activity_count"
    )
    |> expect_one_of(
      path,
      report,
      "timeline_preservation_status",
      ["clear", "preservation_required", "review_required"]
    )
    |> expect_type(path, report, "protection_decision_counts", :map)
    |> expect_type(path, report, "protection_category_counts", :map)
    |> expect_type(path, report, "protection_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".protection_decision_counts",
      decision_counts
    )
    |> validate_non_negative_integer_count_map(
      path <> ".protection_category_counts",
      Map.get(report, "protection_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".protection_reason_counts",
      Map.get(report, "protection_reason_counts")
    )
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      model_limits,
      "must match timeline report model limits"
    )
    |> validate_report_id_sets(path, report)
    |> expect_type(path, report, "rows", :list)
    |> CollectionValidation.validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_protection_row(&1, &2, &3)
    )
    |> expect_type(path, report, "assumptions", :map)
    |> validate_assumptions(
      path,
      report,
      "lifecycle_lock_approval_and_executed_preservation_review"
    )
    |> expect_field_equals(
      path,
      report,
      "activity_count",
      non_negative_integer_map_sum(decision_counts),
      "must equal protection_decision_counts total"
    )
    |> expect_field_equals(
      path,
      report,
      "mutable_activity_count",
      mutable_count,
      "must equal protection_decision_counts mutable"
    )
    |> expect_field_equals(
      path,
      report,
      "preserve_activity_count",
      preserve_count,
      "must equal protection_decision_counts preserve"
    )
    |> expect_field_equals(
      path,
      report,
      "review_change_activity_count",
      review_count,
      "must equal protection_decision_counts review_change"
    )
    |> expect_field_equals(
      path,
      report,
      "preservation_sensitive_activity_count",
      preserve_count + review_count,
      "must equal preserve_activity_count plus review_change_activity_count"
    )
    |> expect_field_equals(
      path,
      report,
      "timeline_preservation_status",
      preservation_status_from_counts(preserve_count, review_count),
      "must equal count-derived timeline_preservation_status"
    )
    |> validate_report_derived_sets(path, report)
  end

  def validate_status(issues, path, status, model_limits) when is_list(model_limits) do
    decision = Map.get(status, "protection_decision")
    expected_status = preservation_status_from_decision(decision)

    issues
    |> expect_equal(
      path,
      status,
      "schema_contract",
      "timeline_preservation_status.v1"
    )
    |> expect_equal(
      path,
      status,
      "model",
      "artifact_only_lifecycle_preservation_status"
    )
    |> expect_one_of(
      path,
      status,
      "timeline_preservation_status",
      ["clear", "preservation_required", "review_required"]
    )
    |> expect_type(path, status, "requires_preservation", :boolean)
    |> expect_type(path, status, "requires_operator_review", :boolean)
    |> validate_stable_ids(path, status, ["activity_id", "timeline_id"])
    |> expect_type(path, status, "protection_decision", :binary)
    |> expect_type(path, status, "protection_category", :binary)
    |> expect_type(path, status, "protection_reason", :binary)
    |> expect_optional_type(path, status, "locked", :boolean)
    |> expect_optional_type(path, status, "approved", :boolean)
    |> expect_optional_type(path, status, "invalid_activity_input", :boolean)
    |> expect_optional_type(path, status, "timeline_identity", :map)
    |> TimelineIdentityContracts.validate_optional_identity(path, status, "timeline_identity")
    |> expect_optional_type(path, status, "model_limits", :list)
    |> validate_string_list_items(path, status, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      status,
      model_limits,
      "must match timeline report model limits"
    )
    |> expect_type(path, status, "assumptions", :map)
    |> validate_assumptions(
      path,
      status,
      "single_activity_lifecycle_preservation_preflight"
    )
    |> expect_field_equals(
      path,
      status,
      "timeline_preservation_status",
      expected_status,
      "must equal protection-decision-derived timeline_preservation_status"
    )
    |> expect_field_equals(
      path,
      status,
      "requires_preservation",
      expected_status == "preservation_required",
      "must equal timeline_preservation_status-derived requires_preservation"
    )
    |> expect_field_equals(
      path,
      status,
      "requires_operator_review",
      expected_status == "review_required",
      "must equal timeline_preservation_status-derived requires_operator_review"
    )
  end

  def validate_optional_source_row(issues, _path, nil), do: issues

  def validate_optional_source_row(issues, path, %{} = row) do
    issues
    |> validate_stable_ids(path, row, ["activity_id", "timeline_id"])
    |> expect_optional_one_of(
      path,
      row,
      "timeline_preservation_status",
      ["clear", "preservation_required", "review_required"]
    )
    |> expect_optional_type(path, row, "schema_contract", :binary)
    |> expect_optional_type(path, row, "model", :binary)
    |> expect_optional_type(path, row, "validation_level", :binary)
    |> expect_optional_type(path, row, "source", :binary)
    |> expect_optional_type(path, row, "activity_type", :binary)
    |> expect_optional_type(path, row, "status", :binary)
    |> expect_optional_type(path, row, "approval_status", :binary)
    |> expect_optional_type(path, row, "requires_preservation", :boolean)
    |> expect_optional_type(path, row, "requires_operator_review", :boolean)
    |> expect_optional_type(path, row, "protection_decision", :binary)
    |> expect_optional_type(path, row, "protection_category", :binary)
    |> expect_optional_type(path, row, "protection_reason", :binary)
    |> expect_optional_type(path, row, "reason", :binary)
    |> expect_optional_type(path, row, "locked", :boolean)
    |> expect_optional_type(path, row, "approved", :boolean)
    |> expect_optional_type(path, row, "executed", :boolean)
    |> expect_optional_type(path, row, "invalid_activity_input", :boolean)
    |> expect_optional_type(path, row, "invalid_activity_input_reason", :binary)
    |> expect_optional_non_negative_integer(path, row, "activity_count")
    |> expect_optional_non_negative_integer(path, row, "mutable_activity_count")
    |> expect_optional_non_negative_integer(path, row, "preserve_activity_count")
    |> expect_optional_non_negative_integer(path, row, "review_change_activity_count")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "preservation_sensitive_activity_count"
    )
    |> TimelineIdentityContracts.validate_optional_identity(path, row, "timeline_identity")
    |> validate_optional_preservation_stable_id_lists(path, row)
  end

  def validate_optional_source_row(issues, path, _row) do
    [error(path, "must be an object") | issues]
  end

  defp validate_report_id_sets(issues, path, report) do
    issues
    |> expect_type(path, report, "preserve_activity_ids", :list)
    |> expect_type(path, report, "preserve_timeline_ids", :list)
    |> expect_type(path, report, "review_change_activity_ids", :list)
    |> expect_type(path, report, "review_change_timeline_ids", :list)
    |> expect_type(path, report, "mutable_activity_ids", :list)
    |> expect_type(path, report, "preservation_sensitive_activity_ids", :list)
    |> expect_type(path, report, "preservation_sensitive_timeline_ids", :list)
    |> validate_optional_stable_id_list(path, report, "preserve_activity_ids")
    |> validate_optional_stable_id_list(path, report, "preserve_timeline_ids")
    |> validate_optional_stable_id_list(path, report, "review_change_activity_ids")
    |> validate_optional_stable_id_list(path, report, "review_change_timeline_ids")
    |> validate_optional_stable_id_list(path, report, "mutable_activity_ids")
    |> validate_optional_stable_id_list(
      path,
      report,
      "preservation_sensitive_activity_ids"
    )
    |> validate_optional_stable_id_list(
      path,
      report,
      "preservation_sensitive_timeline_ids"
    )
    |> expect_type(path, report, "activity_id_sets_by_protection_decision", :map)
    |> expect_type(path, report, "timeline_id_sets_by_protection_decision", :map)
    |> expect_type(path, report, "activity_id_sets_by_protection_category", :map)
    |> expect_type(path, report, "timeline_id_sets_by_protection_category", :map)
    |> expect_type(path, report, "activity_id_sets_by_protection_reason", :map)
    |> expect_type(path, report, "timeline_id_sets_by_protection_reason", :map)
    |> validate_stable_id_array_map(
      path <> ".activity_id_sets_by_protection_decision",
      Map.get(report, "activity_id_sets_by_protection_decision")
    )
    |> validate_stable_id_array_map(
      path <> ".timeline_id_sets_by_protection_decision",
      Map.get(report, "timeline_id_sets_by_protection_decision")
    )
    |> validate_stable_id_array_map(
      path <> ".activity_id_sets_by_protection_category",
      Map.get(report, "activity_id_sets_by_protection_category")
    )
    |> validate_stable_id_array_map(
      path <> ".timeline_id_sets_by_protection_category",
      Map.get(report, "timeline_id_sets_by_protection_category")
    )
    |> validate_stable_id_array_map(
      path <> ".activity_id_sets_by_protection_reason",
      Map.get(report, "activity_id_sets_by_protection_reason")
    )
    |> validate_stable_id_array_map(
      path <> ".timeline_id_sets_by_protection_reason",
      Map.get(report, "timeline_id_sets_by_protection_reason")
    )
  end

  defp validate_report_derived_sets(issues, path, report) do
    activity_decision_sets = Map.get(report, "activity_id_sets_by_protection_decision", %{})
    timeline_decision_sets = Map.get(report, "timeline_id_sets_by_protection_decision", %{})

    issues
    |> expect_field_equals(
      path,
      report,
      "preserve_activity_ids",
      Map.get(activity_decision_sets, "preserve", []),
      "must equal activity_id_sets_by_protection_decision preserve"
    )
    |> expect_field_equals(
      path,
      report,
      "preserve_timeline_ids",
      Map.get(timeline_decision_sets, "preserve", []),
      "must equal timeline_id_sets_by_protection_decision preserve"
    )
    |> expect_field_equals(
      path,
      report,
      "review_change_activity_ids",
      Map.get(activity_decision_sets, "review_change", []),
      "must equal activity_id_sets_by_protection_decision review_change"
    )
    |> expect_field_equals(
      path,
      report,
      "review_change_timeline_ids",
      Map.get(timeline_decision_sets, "review_change", []),
      "must equal timeline_id_sets_by_protection_decision review_change"
    )
    |> expect_field_equals(
      path,
      report,
      "mutable_activity_ids",
      Map.get(activity_decision_sets, "mutable", []),
      "must equal activity_id_sets_by_protection_decision mutable"
    )
    |> expect_field_equals(
      path,
      report,
      "preservation_sensitive_activity_ids",
      sorted_unique_binary_values(
        Map.get(activity_decision_sets, "preserve", []) ++
          Map.get(activity_decision_sets, "review_change", [])
      ),
      "must equal preserve and review_change activity IDs"
    )
    |> expect_field_equals(
      path,
      report,
      "preservation_sensitive_timeline_ids",
      sorted_unique_binary_values(
        Map.get(timeline_decision_sets, "preserve", []) ++
          Map.get(timeline_decision_sets, "review_change", [])
      ),
      "must equal preserve and review_change timeline IDs"
    )
    |> validate_count_map_matches_id_sets(
      path,
      report,
      "protection_decision_counts",
      "activity_id_sets_by_protection_decision"
    )
    |> validate_count_map_matches_id_sets(
      path,
      report,
      "protection_category_counts",
      "activity_id_sets_by_protection_category"
    )
    |> validate_count_map_matches_id_sets(
      path,
      report,
      "protection_reason_counts",
      "activity_id_sets_by_protection_reason"
    )
  end

  defp validate_count_map_matches_id_sets(
         issues,
         path,
         report,
         count_field,
         id_set_field
       ) do
    expected =
      report
      |> Map.get(id_set_field, %{})
      |> Enum.map(fn {key, ids} -> {key, length(ids || [])} end)
      |> Map.new()

    expect_field_equals(
      issues,
      path,
      report,
      count_field,
      expected,
      "must equal #{id_set_field} counts"
    )
  end

  defp validate_protection_row(issues, path, row) do
    issues
    |> validate_protection_decision_shape(path, row)
    |> expect_one_of(path, row, "protection_decision", ["preserve", "review_change"])
  end

  defp validate_protection_decision_shape(issues, path, row) do
    issues
    |> validate_stable_ids(path, row, ["activity_id", "timeline_id"])
    |> expect_type(path, row, "protection_decision", :binary)
    |> expect_type(path, row, "protection_category", :binary)
    |> expect_type(path, row, "reason", :binary)
    |> expect_optional_type(path, row, "locked", :boolean)
    |> expect_optional_type(path, row, "approved", :boolean)
    |> expect_optional_type(path, row, "invalid_activity_input", :boolean)
    |> expect_optional_type(path, row, "timeline_identity", :map)
    |> TimelineIdentityContracts.validate_optional_identity(path, row, "timeline_identity")
  end

  defp validate_assumptions(issues, path, artifact, scope) do
    case Map.get(artifact, "assumptions") do
      assumptions when is_map(assumptions) ->
        issues
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_schedule_mutation"
        )
        |> expect_equal(path <> ".assumptions", assumptions, "scope", scope)

      _assumptions ->
        issues
    end
  end

  defp validate_optional_preservation_stable_id_lists(issues, path, row) do
    Enum.reduce(timeline_preservation_source_stable_id_list_fields(), issues, fn field, acc ->
      acc
      |> expect_optional_type(path, row, field, :list)
      |> validate_optional_stable_id_list(path, row, field)
    end)
  end

  defp timeline_preservation_source_stable_id_list_fields do
    [
      "preserve_activity_ids",
      "preserve_timeline_ids",
      "review_change_activity_ids",
      "review_change_timeline_ids",
      "mutable_activity_ids",
      "preservation_sensitive_activity_ids",
      "preservation_sensitive_timeline_ids"
    ]
  end

  defp preservation_status_from_counts(_preserve_count, review_count) when review_count > 0,
    do: "review_required"

  defp preservation_status_from_counts(preserve_count, _review_count) when preserve_count > 0,
    do: "preservation_required"

  defp preservation_status_from_counts(_preserve_count, _review_count), do: "clear"

  defp preservation_status_from_decision("review_change"), do: "review_required"
  defp preservation_status_from_decision("preserve"), do: "preservation_required"
  defp preservation_status_from_decision(_decision), do: "clear"

  defp protection_count(counts, key) when is_map(counts) do
    case Map.get(counts, key, 0) do
      count when is_integer(count) and count >= 0 -> count
      _count -> 0
    end
  end

  defp protection_count(_counts, _key), do: 0

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp non_negative_integer_map_sum(counts) when is_map(counts) do
    values = Map.values(counts)

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)),
      do: Enum.sum(values),
      else: nil
  end

  defp non_negative_integer_map_sum(_counts), do: nil
end
