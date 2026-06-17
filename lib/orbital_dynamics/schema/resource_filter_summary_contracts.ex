defmodule OrbitalDynamics.Schema.ResourceFilterSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, summary, "schema_contract", "resource_filter_summary.v1")
    |> expect_equal(callbacks, path, summary, "model", "artifact_only_resource_filter_summary")
    |> expect_equal(callbacks, path, summary, "source_artifact_type", "resource_filter_report.v1")
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      resource_filter_report_model_limits(callbacks),
      "must match resource filter report model limits"
    )
    |> validate_field_types(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "review_rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      &validate_suppressed_candidate(&1, callbacks, &2, &3)
    )
    |> expect_type(callbacks, path, summary, "invalid_resource_summary_inputs", :list)
    |> validate_rows(
      callbacks,
      path <> ".invalid_resource_summary_inputs",
      Map.get(summary, "invalid_resource_summary_inputs", []),
      &validate_invalid_resource_summary_input(&1, callbacks, &2, &3)
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
  end

  defp validate_field_types(issues, callbacks, path, summary) do
    issues =
      Enum.reduce(count_fields(), issues, fn field, acc ->
        expect_non_negative_integer(acc, callbacks, path, summary, field)
      end)

    issues =
      Enum.reduce(count_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end)

    issues =
      Enum.reduce(stable_id_list_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :list)
        |> validate_stable_id_list(callbacks, path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(stable_id_array_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_stable_id_array_map(callbacks, path <> ".#{field}", Map.get(summary, field))
      end)

    issues
    |> expect_one_of(callbacks, path, summary, "suppression_review_status", [
      "clear",
      "review_required"
    ])
  end

  defp count_fields do
    [
      "input_candidate_count",
      "kept_candidate_count",
      "suppressed_candidate_count",
      "invalid_candidate_input_count",
      "invalid_resource_summary_input_count",
      "duplicate_suppressed_candidate_id_count",
      "duplicate_suppressed_candidate_row_count"
    ]
  end

  defp count_map_fields do
    [
      "suppressed_reason_counts",
      "resource_blocking_dimension_counts",
      "suppressed_resource_source_quality_counts",
      "suppressed_resource_trust_boundary_status_counts"
    ]
  end

  defp stable_id_list_fields do
    [
      "suppressed_candidate_ids",
      "invalid_candidate_input_ids",
      "invalid_resource_summary_input_ids"
    ]
  end

  defp stable_id_array_map_fields do
    [
      "suppressed_candidate_ids_by_reason",
      "suppressed_candidate_ids_by_resource_blocking_dimension",
      "suppressed_candidate_ids_by_spacecraft_id",
      "suppressed_candidate_ids_by_scenario_id",
      "suppressed_candidate_ids_by_resource_source_quality",
      "suppressed_candidate_ids_by_resource_trust_boundary_status"
    ]
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_schedule_mutation"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "source",
          "resource_filter_report.v1"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_resource_filter_summary"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_state_propagation",
          "not_performed"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, summary) do
    rows =
      summary
      |> Map.get("review_rows", [])
      |> Enum.filter(&is_map/1)

    invalid_summary_rows =
      summary
      |> Map.get("invalid_resource_summary_inputs", [])
      |> Enum.filter(&is_map/1)

    invalid_candidate_ids =
      rows
      |> Enum.filter(
        &(Map.get(&1, "invalid_candidate_input") == true or
            Map.get(&1, "invalid_candidate_shape") == true)
      )
      |> Enum.map(&Map.get(&1, "id"))
      |> Enum.sort()

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_candidate_count",
      length(rows),
      "must equal review_rows count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "kept_candidate_count",
      row_count_difference(callbacks, summary, "input_candidate_count", length(rows)),
      "must equal input_candidate_count minus suppressed_candidate_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppression_review_status",
      review_status(rows, invalid_summary_rows),
      "must equal row-derived suppression_review_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_candidate_ids",
      row_ids(rows, "id"),
      "must equal review_rows ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_reason_counts",
      frequency_map(callbacks, rows, "suppressed_reason"),
      "must equal review_rows suppressed_reason counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_candidate_ids_by_reason",
      row_ids_by_field(callbacks, rows, "suppressed_reason", "id"),
      "must equal review_rows ids grouped by suppressed_reason"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "resource_blocking_dimension_counts",
      frequency_map(callbacks, rows, "resource_blocking_dimension"),
      "must equal review_rows resource_blocking_dimension counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_candidate_ids_by_resource_blocking_dimension",
      row_ids_by_field(callbacks, rows, "resource_blocking_dimension", "id"),
      "must equal review_rows ids grouped by resource_blocking_dimension"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_candidate_ids_by_spacecraft_id",
      row_ids_by_field(callbacks, rows, "spacecraft_id", "id"),
      "must equal review_rows ids grouped by spacecraft_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_candidate_ids_by_scenario_id",
      row_ids_by_field(callbacks, rows, "scenario_id", "id"),
      "must equal review_rows ids grouped by scenario_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_resource_source_quality_counts",
      frequency_map(callbacks, rows, "resource_source_quality"),
      "must equal review_rows resource_source_quality counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_candidate_ids_by_resource_source_quality",
      row_ids_by_field(callbacks, rows, "resource_source_quality", "id"),
      "must equal review_rows ids grouped by resource_source_quality"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_resource_trust_boundary_status_counts",
      frequency_map(callbacks, rows, "resource_trust_boundary_status"),
      "must equal review_rows resource_trust_boundary_status counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "suppressed_candidate_ids_by_resource_trust_boundary_status",
      row_ids_by_field(callbacks, rows, "resource_trust_boundary_status", "id"),
      "must equal review_rows ids grouped by resource_trust_boundary_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_candidate_input_count",
      length(invalid_candidate_ids),
      "must equal review_rows invalid candidate input count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_candidate_input_ids",
      invalid_candidate_ids,
      "must equal review_rows invalid candidate input ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_resource_summary_input_count",
      length(invalid_summary_rows),
      "must equal invalid_resource_summary_inputs count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_resource_summary_input_ids",
      row_ids(invalid_summary_rows, "resource_summary_id"),
      "must equal invalid_resource_summary_inputs resource_summary_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "duplicate_suppressed_candidate_id_count",
      duplicate_suppressed_candidate_id_count(rows),
      "must equal review_rows duplicate suppressed candidate id count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "duplicate_suppressed_candidate_row_count",
      duplicate_suppressed_candidate_row_count(rows),
      "must equal review_rows duplicate suppressed candidate row count"
    )
  end

  defp review_status([], []), do: "clear"
  defp review_status(_rows, _invalid_summary_rows), do: "review_required"

  defp row_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> sorted_unique_binary_values()
  end

  defp duplicate_suppressed_candidate_id_count(rows) do
    rows
    |> Enum.map(&Map.get(&1, "id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.count(fn {_id, count} -> count > 1 end)
  end

  defp duplicate_suppressed_candidate_row_count(rows) do
    rows
    |> Enum.filter(&(Map.get(&1, "duplicate_suppressed_candidate_id") == true))
    |> length()
  end

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])
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

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_suppressed_candidate(issues, callbacks, path, candidate) do
    apply(Keyword.fetch!(callbacks, :validate_suppressed_candidate), [issues, path, candidate])
  end

  defp validate_invalid_resource_summary_input(issues, callbacks, path, row) do
    apply(Keyword.fetch!(callbacks, :validate_invalid_resource_summary_input), [issues, path, row])
  end

  defp resource_filter_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :resource_filter_report_model_limits), [])

  defp row_count_difference(callbacks, report, field, subtract) do
    apply(Keyword.fetch!(callbacks, :row_count_difference), [report, field, subtract])
  end

  defp frequency_map(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :frequency_map), [rows, field])

  defp row_ids_by_field(callbacks, rows, group_field, id_field) do
    apply(Keyword.fetch!(callbacks, :row_ids_by_field), [rows, group_field, id_field])
  end

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
