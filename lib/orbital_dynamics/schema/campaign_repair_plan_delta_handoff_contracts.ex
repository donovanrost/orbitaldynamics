defmodule OrbitalDynamics.Schema.CampaignRepairPlanDeltaHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, %{"deltas" => deltas} = artifact) when is_list(deltas) do
    issues
    |> validate_operator_review_handoff(artifact, deltas)
    |> validate_cadence_handoff(artifact, deltas)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         deltas
       ) do
    plan_delta_rows = indexed_rows(Map.get(package, "rows"), &operator_plan_delta_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.plan_delta_count",
      Map.get(package, "plan_delta_count"),
      length(deltas),
      "must match enclosing Repair delta count"
    )
    |> validate_equal(
      "$.operator_review_package.rows",
      length(plan_delta_rows),
      length(deltas),
      "must contain one plan-delta review row per enclosing Repair delta"
    )
    |> validate_source_copies("$.operator_review_package.rows", plan_delta_rows, deltas)
  end

  defp validate_operator_review_handoff(issues, _artifact, _deltas), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         deltas
       ) do
    plan_delta_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_plan_delta_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(plan_delta_rows),
      length(deltas),
      "must contain one plan-delta import row per enclosing Repair delta"
    )
    |> validate_source_copies("$.cadence_import_manifest.rows", plan_delta_rows, deltas)
  end

  defp validate_cadence_handoff(issues, _artifact, _deltas), do: issues

  defp indexed_rows(rows, predicate) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} -> is_map(row) and predicate.(row) end)
  end

  defp indexed_rows(_rows, _predicate), do: []

  defp operator_plan_delta_row?(row), do: Map.get(row, "review_type") == "plan_delta_review"

  defp cadence_plan_delta_row?(row) do
    Map.get(row, "source_review_type") == "plan_delta_review" or
      Map.get(row, "import_action") == "review_plan_delta"
  end

  defp validate_source_copies(issues, base_path, indexed_rows, deltas) do
    indexed_rows
    |> Enum.zip(deltas)
    |> Enum.reduce(issues, fn {{row, row_index}, delta}, acc ->
      validate_optional_source_copy(acc, base_path, row_index, row, delta)
    end)
  end

  defp validate_optional_source_copy(issues, base_path, row_index, row, delta) do
    case Map.get(row, "source_delta") do
      %{} = source_delta ->
        validate_equal(
          issues,
          "#{base_path}[#{row_index}].source_delta",
          source_delta,
          delta,
          "must match the corresponding enclosing Repair delta"
        )

      _source_delta ->
        issues
    end
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
