defmodule OrbitalDynamics.Schema.ParetoFrontierContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_numeric_map: 3, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_list: 3, validate_stable_ids: 4]

  def validate(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "pareto_frontier_report.v1")
    |> expect_equal(path, report, "model", "objective_vector_pareto_frontier")
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "alternative_count")
    |> expect_non_negative_integer(path, report, "objective_count")
    |> expect_non_negative_integer(path, report, "frontier_count")
    |> expect_non_negative_integer(path, report, "dominated_count")
    |> expect_type(path, report, "frontier_ids", :list)
    |> expect_type(path, report, "dominated_ids", :list)
    |> expect_type(path, report, "objective_directions", :map)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      OrbitalDynamics.Optimizer.pareto_frontier_model_limits(),
      "must match Pareto frontier model limits"
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_row/3
    )
    |> validate_counts(path, report)
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    frontier_ids =
      rows
      |> Enum.filter(&(&1["frontier"] == true))
      |> Enum.map(&Map.get(&1, "id"))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort()

    dominated_ids =
      rows
      |> Enum.reject(&(&1["frontier"] == true))
      |> Enum.map(&Map.get(&1, "id"))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort()

    objective_count =
      case Map.get(report, "objective_directions") do
        directions when is_map(directions) -> map_size(directions)
        _directions -> nil
      end

    issues
    |> expect_field_equals(path, report, "alternative_count", length(rows))
    |> expect_field_equals(path, report, "frontier_count", length(frontier_ids))
    |> expect_field_equals(path, report, "dominated_count", length(dominated_ids))
    |> expect_field_equals(path, report, "objective_count", objective_count)
    |> expect_field_equals(
      path,
      report,
      "frontier_ids",
      frontier_ids,
      "must equal row-derived frontier IDs"
    )
    |> expect_field_equals(
      path,
      report,
      "dominated_ids",
      dominated_ids,
      "must equal row-derived dominated IDs"
    )
  end

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "scenario_id",
      "objective_values",
      "objective_keys",
      "frontier",
      "dominated_by_ids",
      "dominates_ids"
    ])
    |> validate_stable_ids(path, row, ["id", "scenario_id"])
    |> expect_type(path, row, "objective_values", :map)
    |> validate_numeric_map(
      path <> ".objective_values",
      Map.get(row, "objective_values")
    )
    |> expect_type(path, row, "objective_keys", :list)
    |> expect_type(path, row, "frontier", :boolean)
    |> expect_type(path, row, "dominated_by_ids", :list)
    |> expect_type(path, row, "dominates_ids", :list)
    |> validate_stable_id_list(
      path <> ".dominated_by_ids",
      Map.get(row, "dominated_by_ids", [])
    )
    |> validate_stable_id_list(
      path <> ".dominates_ids",
      Map.get(row, "dominates_ids", [])
    )
    |> validate_row_counts(path, row)
  end

  defp validate_row_counts(issues, path, row) do
    objective_keys =
      case Map.get(row, "objective_values") do
        values when is_map(values) ->
          values
          |> Map.keys()
          |> Enum.sort()

        _values ->
          nil
      end

    expect_field_equals(
      issues,
      path,
      row,
      "objective_keys",
      objective_keys,
      "must equal objective_values keys"
    )
  end
end
