defmodule OrbitalDynamics.Schema.ParetoFrontierContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "pareto_frontier_report.v1")
    |> expect_equal(callbacks, path, report, "model", "objective_vector_pareto_frontier")
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "alternative_count")
    |> expect_non_negative_integer(callbacks, path, report, "objective_count")
    |> expect_non_negative_integer(callbacks, path, report, "frontier_count")
    |> expect_non_negative_integer(callbacks, path, report, "dominated_count")
    |> expect_type(callbacks, path, report, "frontier_ids", :list)
    |> expect_type(callbacks, path, report, "dominated_ids", :list)
    |> expect_type(callbacks, path, report, "objective_directions", :map)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      pareto_frontier_model_limits(callbacks),
      "must match Pareto frontier model limits"
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
    |> validate_counts(callbacks, path, report)
  end

  defp validate_counts(issues, callbacks, path, report) do
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
    |> expect_field_equals(callbacks, path, report, "alternative_count", length(rows))
    |> expect_field_equals(callbacks, path, report, "frontier_count", length(frontier_ids))
    |> expect_field_equals(callbacks, path, report, "dominated_count", length(dominated_ids))
    |> expect_field_equals(callbacks, path, report, "objective_count", objective_count)
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "frontier_ids",
      frontier_ids,
      "must equal row-derived frontier IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "dominated_ids",
      dominated_ids,
      "must equal row-derived dominated IDs"
    )
  end

  defp validate_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "id",
      "scenario_id",
      "objective_values",
      "objective_keys",
      "frontier",
      "dominated_by_ids",
      "dominates_ids"
    ])
    |> validate_stable_ids(callbacks, path, row, ["id", "scenario_id"])
    |> expect_type(callbacks, path, row, "objective_values", :map)
    |> validate_numeric_map(
      callbacks,
      path <> ".objective_values",
      Map.get(row, "objective_values")
    )
    |> expect_type(callbacks, path, row, "objective_keys", :list)
    |> expect_type(callbacks, path, row, "frontier", :boolean)
    |> expect_type(callbacks, path, row, "dominated_by_ids", :list)
    |> expect_type(callbacks, path, row, "dominates_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".dominated_by_ids",
      Map.get(row, "dominated_by_ids", [])
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".dominates_ids",
      Map.get(row, "dominates_ids", [])
    )
    |> validate_row_counts(callbacks, path, row)
  end

  defp validate_row_counts(issues, callbacks, path, row) do
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
      callbacks,
      path,
      row,
      "objective_keys",
      objective_keys,
      "must equal objective_values keys"
    )
  end

  defp pareto_frontier_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :pareto_frontier_model_limits), [])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        artifact,
        expected,
        message
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_numeric_map(issues, callbacks, path, value),
    do: apply(Keyword.fetch!(callbacks, :validate_numeric_map), [issues, path, value])
end
