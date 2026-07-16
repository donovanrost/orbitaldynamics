defmodule OrbitalDynamics.Schema.RefreshBudgetReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_optional_list: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_id_list: 4]

  def validate_optional(issues, _path, nil), do: issues

  def validate_optional(issues, path, %{} = report) do
    validate(issues, path, report)
  end

  def validate_optional(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "refresh_budget_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "deterministic_candidate_limit_after_filters"
    )
    |> expect_type(path, report, "input_candidate_count", :integer)
    |> expect_type(path, report, "kept_candidate_count", :integer)
    |> expect_type(path, report, "dropped_candidate_count", :integer)
    |> expect_type(path, report, "kept_candidate_ids", :list)
    |> expect_type(path, report, "dropped_candidate_ids", :list)
    |> expect_type(path, report, "max_candidate_activities", :integer)
    |> expect_type(path, report, "selection_order", :binary)
    |> expect_type(path, report, "assumptions", :map)
    |> expect_optional_list(path, report, "model_limits")
    |> expect_optional_type(path, report, "invalid_candidate_limit_policy", :boolean)
    |> validate_stable_id_list(path, report, "kept_candidate_ids")
    |> validate_stable_id_list(path, report, "dropped_candidate_ids")
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_counts(path, report)
  end

  defp validate_counts(issues, path, report) do
    issues
    |> expect_field_at_least(path, report, "input_candidate_count", 0)
    |> expect_field_at_least(path, report, "kept_candidate_count", 0)
    |> expect_field_at_least(path, report, "dropped_candidate_count", 0)
    |> expect_field_at_least(path, report, "max_candidate_activities", 0)
    |> expect_equal(
      path,
      report,
      "input_candidate_count",
      OrbitalDynamics.Schema.CollectionAggregation.row_count_sum(report, [
        "kept_candidate_count",
        "dropped_candidate_count"
      ])
    )
    |> expect_equal(
      path,
      report,
      "kept_candidate_count",
      length(Map.get(report, "kept_candidate_ids", []))
    )
    |> expect_equal(
      path,
      report,
      "dropped_candidate_count",
      length(Map.get(report, "dropped_candidate_ids", []))
    )
    |> expect_field_equals(
      path,
      report,
      "model_limits",
      OrbitalDynamics.CandidateRefresh.model_limits(),
      "must match candidate refresh model limits"
    )
    |> validate_candidate_id_sets(path, report)
  end

  defp validate_candidate_id_sets(issues, path, report) do
    kept_candidate_ids = list_value(report, "kept_candidate_ids")
    dropped_candidate_ids = list_value(report, "dropped_candidate_ids")

    issues
    |> reject_duplicate_ids(path <> ".kept_candidate_ids", kept_candidate_ids)
    |> reject_duplicate_ids(path <> ".dropped_candidate_ids", dropped_candidate_ids)
    |> reject_id_list_overlap(
      path <> ".dropped_candidate_ids",
      kept_candidate_ids,
      dropped_candidate_ids,
      "must not overlap kept_candidate_ids"
    )
  end

  defp reject_duplicate_ids(issues, path, ids) do
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
        error(path, "must not contain duplicate IDs: #{inspect(duplicate_ids)}")
        | issues
      ]
    end
  end

  defp reject_id_list_overlap(issues, path, left_ids, right_ids, message) do
    overlap =
      left_ids
      |> MapSet.new()
      |> MapSet.intersection(MapSet.new(right_ids))
      |> MapSet.to_list()
      |> Enum.sort()

    if overlap == [] do
      issues
    else
      [error(path, "#{message}: #{inspect(overlap)}") | issues]
    end
  end

  defp list_value(map, key), do: Map.get(map, key) || []
end
