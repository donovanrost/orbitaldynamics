defmodule OrbitalDynamics.Schema.RefreshBudgetReportContracts do
  @moduledoc false

  def validate_optional(issues, _path, nil, _callbacks), do: issues

  def validate_optional(issues, path, %{} = report, callbacks) when is_list(callbacks) do
    validate(issues, path, report, callbacks)
  end

  def validate_optional(issues, path, _report, callbacks) when is_list(callbacks),
    do: [error(callbacks, path, "must be an object") | issues]

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "refresh_budget_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "deterministic_candidate_limit_after_filters"
    )
    |> expect_type(callbacks, path, report, "input_candidate_count", :integer)
    |> expect_type(callbacks, path, report, "kept_candidate_count", :integer)
    |> expect_type(callbacks, path, report, "dropped_candidate_count", :integer)
    |> expect_type(callbacks, path, report, "kept_candidate_ids", :list)
    |> expect_type(callbacks, path, report, "dropped_candidate_ids", :list)
    |> expect_type(callbacks, path, report, "max_candidate_activities", :integer)
    |> expect_type(callbacks, path, report, "selection_order", :binary)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> expect_optional_list(callbacks, path, report, "model_limits")
    |> expect_optional_type(callbacks, path, report, "invalid_candidate_limit_policy", :boolean)
    |> validate_stable_id_list(callbacks, path, report, "kept_candidate_ids")
    |> validate_stable_id_list(callbacks, path, report, "dropped_candidate_ids")
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_counts(callbacks, path, report)
  end

  defp validate_counts(issues, callbacks, path, report) do
    issues
    |> expect_field_at_least(callbacks, path, report, "input_candidate_count", 0)
    |> expect_field_at_least(callbacks, path, report, "kept_candidate_count", 0)
    |> expect_field_at_least(callbacks, path, report, "dropped_candidate_count", 0)
    |> expect_field_at_least(callbacks, path, report, "max_candidate_activities", 0)
    |> expect_equal(
      callbacks,
      path,
      report,
      "input_candidate_count",
      row_count_sum(callbacks, report, ["kept_candidate_count", "dropped_candidate_count"])
    )
    |> expect_equal(
      callbacks,
      path,
      report,
      "kept_candidate_count",
      length(Map.get(report, "kept_candidate_ids", []))
    )
    |> expect_equal(
      callbacks,
      path,
      report,
      "dropped_candidate_count",
      length(Map.get(report, "dropped_candidate_ids", []))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "model_limits",
      OrbitalDynamics.CandidateRefresh.model_limits(),
      "must match candidate refresh model limits"
    )
    |> validate_candidate_id_sets(callbacks, path, report)
  end

  defp validate_candidate_id_sets(issues, callbacks, path, report) do
    kept_candidate_ids = list_value(report, "kept_candidate_ids")
    dropped_candidate_ids = list_value(report, "dropped_candidate_ids")

    issues
    |> reject_duplicate_ids(callbacks, path <> ".kept_candidate_ids", kept_candidate_ids)
    |> reject_duplicate_ids(callbacks, path <> ".dropped_candidate_ids", dropped_candidate_ids)
    |> reject_id_list_overlap(
      callbacks,
      path <> ".dropped_candidate_ids",
      kept_candidate_ids,
      dropped_candidate_ids,
      "must not overlap kept_candidate_ids"
    )
  end

  defp reject_duplicate_ids(issues, callbacks, path, ids) do
    duplicate_ids =
      ids
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> id end)
      |> Enum.sort()

    if duplicate_ids == [] do
      issues
    else
      [
        error(callbacks, path, "must not contain duplicate IDs: #{inspect(duplicate_ids)}")
        | issues
      ]
    end
  end

  defp reject_id_list_overlap(issues, callbacks, path, left_ids, right_ids, message) do
    overlap =
      left_ids
      |> MapSet.new()
      |> MapSet.intersection(MapSet.new(right_ids))
      |> MapSet.to_list()
      |> Enum.sort()

    if overlap == [] do
      issues
    else
      [error(callbacks, path, "#{message}: #{inspect(overlap)}") | issues]
    end
  end

  defp list_value(map, key), do: Map.get(map, key) || []

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_list(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_list), [issues, path, map, field])

  defp validate_stable_id_list(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :validate_stable_id_list), [issues, path, map, field])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp expect_field_at_least(issues, callbacks, path, map, field, minimum),
    do:
      apply(require_callback(callbacks, :expect_field_at_least), [
        issues,
        path,
        map,
        field,
        minimum
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp row_count_sum(callbacks, report, fields),
    do: apply(require_callback(callbacks, :row_count_sum), [report, fields])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, key) do
    Keyword.fetch!(callbacks, key)
  end
end
