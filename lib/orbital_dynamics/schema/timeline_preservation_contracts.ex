defmodule OrbitalDynamics.Schema.TimelinePreservationContracts do
  @moduledoc false

  def validate_report(issues, path, report, callbacks) when is_list(callbacks) do
    decision_counts = Map.get(report, "protection_decision_counts", %{})
    preserve_count = protection_count(decision_counts, "preserve")
    review_count = protection_count(decision_counts, "review_change")
    mutable_count = protection_count(decision_counts, "mutable")

    issues
    |> expect_equal(
      callbacks,
      path,
      report,
      "schema_contract",
      "timeline_preservation_report.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "artifact_only_lifecycle_preservation_summary"
    )
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "mutable_activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "preserve_activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "review_change_activity_count")
    |> expect_non_negative_integer(
      callbacks,
      path,
      report,
      "preservation_sensitive_activity_count"
    )
    |> expect_one_of(
      callbacks,
      path,
      report,
      "timeline_preservation_status",
      ["clear", "preservation_required", "review_required"]
    )
    |> expect_type(callbacks, path, report, "protection_decision_counts", :map)
    |> expect_type(callbacks, path, report, "protection_category_counts", :map)
    |> expect_type(callbacks, path, report, "protection_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".protection_decision_counts",
      decision_counts
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".protection_category_counts",
      Map.get(report, "protection_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".protection_reason_counts",
      Map.get(report, "protection_reason_counts")
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
    |> validate_report_id_sets(callbacks, path, report)
    |> expect_type(callbacks, path, report, "rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_protection_row(&1, callbacks, &2, &3)
    )
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_assumptions(
      callbacks,
      path,
      report,
      "lifecycle_lock_approval_and_executed_preservation_review"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "activity_count",
      non_negative_integer_map_sum(callbacks, decision_counts),
      "must equal protection_decision_counts total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "mutable_activity_count",
      mutable_count,
      "must equal protection_decision_counts mutable"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "preserve_activity_count",
      preserve_count,
      "must equal protection_decision_counts preserve"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_change_activity_count",
      review_count,
      "must equal protection_decision_counts review_change"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "preservation_sensitive_activity_count",
      preserve_count + review_count,
      "must equal preserve_activity_count plus review_change_activity_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "timeline_preservation_status",
      preservation_status_from_counts(preserve_count, review_count),
      "must equal count-derived timeline_preservation_status"
    )
    |> validate_report_derived_sets(callbacks, path, report)
  end

  def validate_status(issues, path, status, callbacks) when is_list(callbacks) do
    decision = Map.get(status, "protection_decision")
    expected_status = preservation_status_from_decision(decision)

    issues
    |> expect_equal(
      callbacks,
      path,
      status,
      "schema_contract",
      "timeline_preservation_status.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      status,
      "model",
      "artifact_only_lifecycle_preservation_status"
    )
    |> expect_one_of(
      callbacks,
      path,
      status,
      "timeline_preservation_status",
      ["clear", "preservation_required", "review_required"]
    )
    |> expect_type(callbacks, path, status, "requires_preservation", :boolean)
    |> expect_type(callbacks, path, status, "requires_operator_review", :boolean)
    |> validate_stable_ids(callbacks, path, status, ["activity_id", "timeline_id"])
    |> expect_type(callbacks, path, status, "protection_decision", :binary)
    |> expect_type(callbacks, path, status, "protection_category", :binary)
    |> expect_type(callbacks, path, status, "protection_reason", :binary)
    |> expect_optional_type(callbacks, path, status, "locked", :boolean)
    |> expect_optional_type(callbacks, path, status, "approved", :boolean)
    |> expect_optional_type(callbacks, path, status, "invalid_activity_input", :boolean)
    |> expect_optional_type(callbacks, path, status, "timeline_identity", :map)
    |> validate_optional_timeline_identity(callbacks, path, status, "timeline_identity")
    |> expect_optional_type(callbacks, path, status, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, status, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      status,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
    |> expect_type(callbacks, path, status, "assumptions", :map)
    |> validate_assumptions(
      callbacks,
      path,
      status,
      "single_activity_lifecycle_preservation_preflight"
    )
    |> expect_field_equals(
      callbacks,
      path,
      status,
      "timeline_preservation_status",
      expected_status,
      "must equal protection-decision-derived timeline_preservation_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      status,
      "requires_preservation",
      expected_status == "preservation_required",
      "must equal timeline_preservation_status-derived requires_preservation"
    )
    |> expect_field_equals(
      callbacks,
      path,
      status,
      "requires_operator_review",
      expected_status == "review_required",
      "must equal timeline_preservation_status-derived requires_operator_review"
    )
  end

  def validate_optional_source_row(issues, _path, nil, _callbacks), do: issues

  def validate_optional_source_row(issues, path, %{} = row, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, row, ["activity_id", "timeline_id"])
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "timeline_preservation_status",
      ["clear", "preservation_required", "review_required"]
    )
    |> expect_optional_type(callbacks, path, row, "schema_contract", :binary)
    |> expect_optional_type(callbacks, path, row, "model", :binary)
    |> expect_optional_type(callbacks, path, row, "validation_level", :binary)
    |> expect_optional_type(callbacks, path, row, "source", :binary)
    |> expect_optional_type(callbacks, path, row, "activity_type", :binary)
    |> expect_optional_type(callbacks, path, row, "status", :binary)
    |> expect_optional_type(callbacks, path, row, "approval_status", :binary)
    |> expect_optional_type(callbacks, path, row, "requires_preservation", :boolean)
    |> expect_optional_type(callbacks, path, row, "requires_operator_review", :boolean)
    |> expect_optional_type(callbacks, path, row, "protection_decision", :binary)
    |> expect_optional_type(callbacks, path, row, "protection_category", :binary)
    |> expect_optional_type(callbacks, path, row, "protection_reason", :binary)
    |> expect_optional_type(callbacks, path, row, "reason", :binary)
    |> expect_optional_type(callbacks, path, row, "locked", :boolean)
    |> expect_optional_type(callbacks, path, row, "approved", :boolean)
    |> expect_optional_type(callbacks, path, row, "executed", :boolean)
    |> expect_optional_type(callbacks, path, row, "invalid_activity_input", :boolean)
    |> expect_optional_type(callbacks, path, row, "invalid_activity_input_reason", :binary)
    |> expect_optional_non_negative_integer(callbacks, path, row, "activity_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "mutable_activity_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "preserve_activity_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "review_change_activity_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "preservation_sensitive_activity_count"
    )
    |> validate_optional_timeline_identity(callbacks, path, row, "timeline_identity")
    |> validate_optional_preservation_stable_id_lists(callbacks, path, row)
  end

  def validate_optional_source_row(issues, path, _row, callbacks) when is_list(callbacks) do
    [error(callbacks, path, "must be an object") | issues]
  end

  defp validate_report_id_sets(issues, callbacks, path, report) do
    issues
    |> expect_type(callbacks, path, report, "preserve_activity_ids", :list)
    |> expect_type(callbacks, path, report, "preserve_timeline_ids", :list)
    |> expect_type(callbacks, path, report, "review_change_activity_ids", :list)
    |> expect_type(callbacks, path, report, "review_change_timeline_ids", :list)
    |> expect_type(callbacks, path, report, "mutable_activity_ids", :list)
    |> expect_type(callbacks, path, report, "preservation_sensitive_activity_ids", :list)
    |> expect_type(callbacks, path, report, "preservation_sensitive_timeline_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "preserve_activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, report, "preserve_timeline_ids")
    |> validate_optional_stable_id_list(callbacks, path, report, "review_change_activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, report, "review_change_timeline_ids")
    |> validate_optional_stable_id_list(callbacks, path, report, "mutable_activity_ids")
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "preservation_sensitive_activity_ids"
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "preservation_sensitive_timeline_ids"
    )
    |> expect_type(callbacks, path, report, "activity_id_sets_by_protection_decision", :map)
    |> expect_type(callbacks, path, report, "timeline_id_sets_by_protection_decision", :map)
    |> expect_type(callbacks, path, report, "activity_id_sets_by_protection_category", :map)
    |> expect_type(callbacks, path, report, "timeline_id_sets_by_protection_category", :map)
    |> expect_type(callbacks, path, report, "activity_id_sets_by_protection_reason", :map)
    |> expect_type(callbacks, path, report, "timeline_id_sets_by_protection_reason", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".activity_id_sets_by_protection_decision",
      Map.get(report, "activity_id_sets_by_protection_decision")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".timeline_id_sets_by_protection_decision",
      Map.get(report, "timeline_id_sets_by_protection_decision")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".activity_id_sets_by_protection_category",
      Map.get(report, "activity_id_sets_by_protection_category")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".timeline_id_sets_by_protection_category",
      Map.get(report, "timeline_id_sets_by_protection_category")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".activity_id_sets_by_protection_reason",
      Map.get(report, "activity_id_sets_by_protection_reason")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".timeline_id_sets_by_protection_reason",
      Map.get(report, "timeline_id_sets_by_protection_reason")
    )
  end

  defp validate_report_derived_sets(issues, callbacks, path, report) do
    activity_decision_sets = Map.get(report, "activity_id_sets_by_protection_decision", %{})
    timeline_decision_sets = Map.get(report, "timeline_id_sets_by_protection_decision", %{})

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "preserve_activity_ids",
      Map.get(activity_decision_sets, "preserve", []),
      "must equal activity_id_sets_by_protection_decision preserve"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "preserve_timeline_ids",
      Map.get(timeline_decision_sets, "preserve", []),
      "must equal timeline_id_sets_by_protection_decision preserve"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_change_activity_ids",
      Map.get(activity_decision_sets, "review_change", []),
      "must equal activity_id_sets_by_protection_decision review_change"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_change_timeline_ids",
      Map.get(timeline_decision_sets, "review_change", []),
      "must equal timeline_id_sets_by_protection_decision review_change"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "mutable_activity_ids",
      Map.get(activity_decision_sets, "mutable", []),
      "must equal activity_id_sets_by_protection_decision mutable"
    )
    |> expect_field_equals(
      callbacks,
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
      callbacks,
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
      callbacks,
      path,
      report,
      "protection_decision_counts",
      "activity_id_sets_by_protection_decision"
    )
    |> validate_count_map_matches_id_sets(
      callbacks,
      path,
      report,
      "protection_category_counts",
      "activity_id_sets_by_protection_category"
    )
    |> validate_count_map_matches_id_sets(
      callbacks,
      path,
      report,
      "protection_reason_counts",
      "activity_id_sets_by_protection_reason"
    )
  end

  defp validate_count_map_matches_id_sets(
         issues,
         callbacks,
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
      callbacks,
      path,
      report,
      count_field,
      expected,
      "must equal #{id_set_field} counts"
    )
  end

  defp validate_protection_row(issues, callbacks, path, row) do
    issues
    |> validate_protection_decision_shape(callbacks, path, row)
    |> expect_one_of(callbacks, path, row, "protection_decision", ["preserve", "review_change"])
  end

  defp validate_protection_decision_shape(issues, callbacks, path, row) do
    issues
    |> validate_stable_ids(callbacks, path, row, ["activity_id", "timeline_id"])
    |> expect_type(callbacks, path, row, "protection_decision", :binary)
    |> expect_type(callbacks, path, row, "protection_category", :binary)
    |> expect_type(callbacks, path, row, "reason", :binary)
    |> expect_optional_type(callbacks, path, row, "locked", :boolean)
    |> expect_optional_type(callbacks, path, row, "approved", :boolean)
    |> expect_optional_type(callbacks, path, row, "invalid_activity_input", :boolean)
    |> expect_optional_type(callbacks, path, row, "timeline_identity", :map)
    |> validate_optional_timeline_identity(callbacks, path, row, "timeline_identity")
  end

  defp validate_assumptions(issues, callbacks, path, artifact, scope) do
    case Map.get(artifact, "assumptions") do
      assumptions when is_map(assumptions) ->
        issues
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_schedule_mutation"
        )
        |> expect_equal(callbacks, path <> ".assumptions", assumptions, "scope", scope)

      _assumptions ->
        issues
    end
  end

  defp validate_optional_preservation_stable_id_lists(issues, callbacks, path, row) do
    Enum.reduce(timeline_preservation_source_stable_id_list_fields(), issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, row, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, row, field)
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

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, values),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, values])

  defp expect_optional_one_of(issues, callbacks, path, map, field, values) do
    apply(Keyword.fetch!(callbacks, :expect_optional_one_of), [
      issues,
      path,
      map,
      field,
      values
    ])
  end

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
      issues,
      path,
      map,
      field
    ])
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_timeline_identity(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_timeline_identity), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])

  defp non_negative_integer_map_sum(callbacks, counts),
    do: apply(Keyword.fetch!(callbacks, :non_negative_integer_map_sum), [counts])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
