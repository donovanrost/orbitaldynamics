defmodule OrbitalDynamics.Schema.ResourceFilterSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CollectionAggregation

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3, validate_stable_id_list: 3]

  def validate(
        issues,
        path,
        summary,
        resource_filter_report_model_limits,
        suppressed_candidate_validator,
        invalid_resource_summary_input_validator
      )
      when is_list(resource_filter_report_model_limits) and
             is_function(suppressed_candidate_validator, 3) and
             is_function(invalid_resource_summary_input_validator, 3) do
    issues
    |> expect_equal(path, summary, "schema_contract", "resource_filter_summary.v1")
    |> expect_equal(path, summary, "model", "artifact_only_resource_filter_summary")
    |> expect_equal(path, summary, "source_artifact_type", "resource_filter_report.v1")
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      resource_filter_report_model_limits,
      "must match resource filter report model limits"
    )
    |> validate_field_types(path, summary)
    |> expect_type(path, summary, "review_rows", :list)
    |> validate_rows(
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      suppressed_candidate_validator
    )
    |> expect_type(path, summary, "invalid_resource_summary_inputs", :list)
    |> validate_rows(
      path <> ".invalid_resource_summary_inputs",
      Map.get(summary, "invalid_resource_summary_inputs", []),
      invalid_resource_summary_input_validator
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
  end

  defp validate_field_types(issues, path, summary) do
    issues =
      Enum.reduce(count_fields(), issues, fn field, acc ->
        expect_non_negative_integer(acc, path, summary, field)
      end)

    issues =
      Enum.reduce(count_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end)

    issues =
      Enum.reduce(stable_id_list_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :list)
        |> validate_stable_id_list(path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(stable_id_array_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :map)
        |> validate_stable_id_array_map(path <> ".#{field}", Map.get(summary, field))
      end)

    issues
    |> expect_one_of(path, summary, "suppression_review_status", [
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

  defp validate_assumptions(issues, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_schedule_mutation"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "source",
          "resource_filter_report.v1"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_resource_filter_summary"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "resource_state_propagation",
          "not_performed"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, summary) do
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
      path,
      summary,
      "suppressed_candidate_count",
      length(rows),
      "must equal review_rows count"
    )
    |> expect_field_equals(
      path,
      summary,
      "kept_candidate_count",
      CollectionAggregation.row_count_difference(summary, "input_candidate_count", length(rows)),
      "must equal input_candidate_count minus suppressed_candidate_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppression_review_status",
      review_status(rows, invalid_summary_rows),
      "must equal row-derived suppression_review_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_candidate_ids",
      row_ids(rows, "id"),
      "must equal review_rows ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_reason_counts",
      CollectionAggregation.frequency_map(rows, "suppressed_reason"),
      "must equal review_rows suppressed_reason counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_candidate_ids_by_reason",
      CollectionAggregation.row_ids_by_field(rows, "suppressed_reason", "id"),
      "must equal review_rows ids grouped by suppressed_reason"
    )
    |> expect_field_equals(
      path,
      summary,
      "resource_blocking_dimension_counts",
      CollectionAggregation.frequency_map(rows, "resource_blocking_dimension"),
      "must equal review_rows resource_blocking_dimension counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_candidate_ids_by_resource_blocking_dimension",
      CollectionAggregation.row_ids_by_field(rows, "resource_blocking_dimension", "id"),
      "must equal review_rows ids grouped by resource_blocking_dimension"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_candidate_ids_by_spacecraft_id",
      CollectionAggregation.row_ids_by_field(rows, "spacecraft_id", "id"),
      "must equal review_rows ids grouped by spacecraft_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_candidate_ids_by_scenario_id",
      CollectionAggregation.row_ids_by_field(rows, "scenario_id", "id"),
      "must equal review_rows ids grouped by scenario_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_resource_source_quality_counts",
      CollectionAggregation.frequency_map(rows, "resource_source_quality"),
      "must equal review_rows resource_source_quality counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_candidate_ids_by_resource_source_quality",
      CollectionAggregation.row_ids_by_field(rows, "resource_source_quality", "id"),
      "must equal review_rows ids grouped by resource_source_quality"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_resource_trust_boundary_status_counts",
      CollectionAggregation.frequency_map(rows, "resource_trust_boundary_status"),
      "must equal review_rows resource_trust_boundary_status counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "suppressed_candidate_ids_by_resource_trust_boundary_status",
      CollectionAggregation.row_ids_by_field(rows, "resource_trust_boundary_status", "id"),
      "must equal review_rows ids grouped by resource_trust_boundary_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "invalid_candidate_input_count",
      length(invalid_candidate_ids),
      "must equal review_rows invalid candidate input count"
    )
    |> expect_field_equals(
      path,
      summary,
      "invalid_candidate_input_ids",
      invalid_candidate_ids,
      "must equal review_rows invalid candidate input ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "invalid_resource_summary_input_count",
      length(invalid_summary_rows),
      "must equal invalid_resource_summary_inputs count"
    )
    |> expect_field_equals(
      path,
      summary,
      "invalid_resource_summary_input_ids",
      row_ids(invalid_summary_rows, "resource_summary_id"),
      "must equal invalid_resource_summary_inputs resource_summary_id values"
    )
    |> expect_field_equals(
      path,
      summary,
      "duplicate_suppressed_candidate_id_count",
      duplicate_suppressed_candidate_id_count(rows),
      "must equal review_rows duplicate suppressed candidate id count"
    )
    |> expect_field_equals(
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

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
