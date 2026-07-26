defmodule OrbitalDynamics.Schema.CampaignRepairApprovalHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, %{"approval_requirements" => requirements} = artifact)
      when is_list(requirements) do
    issues
    |> validate_operator_review_handoff(artifact, requirements)
    |> validate_cadence_handoff(artifact, requirements)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         requirements
       ) do
    approval_rows = indexed_rows(Map.get(package, "rows"), &operator_approval_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.approval_requirement_count",
      Map.get(package, "approval_requirement_count"),
      length(requirements),
      "must match enclosing Repair approval requirement count"
    )
    |> validate_equal(
      "$.operator_review_package.rows",
      length(approval_rows),
      length(requirements),
      "must contain one approval-review row per enclosing Repair requirement"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      approval_rows,
      requirements,
      [["source_requirement"]]
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _requirements), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         requirements
       ) do
    approval_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_approval_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(approval_rows),
      length(requirements),
      "must contain one approval-import row per enclosing Repair requirement"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      approval_rows,
      requirements,
      [["source_requirement"], ["source_review_row", "source_requirement"]]
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _requirements), do: issues

  defp indexed_rows(rows, predicate) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} -> is_map(row) and predicate.(row) end)
  end

  defp indexed_rows(_rows, _predicate), do: []

  defp operator_approval_row?(row), do: Map.get(row, "review_type") == "approval_requirement"

  defp cadence_approval_row?(row) do
    Map.get(row, "source_review_type") == "approval_requirement" or
      Map.get(row, "import_action") == "review_approval_requirement"
  end

  defp validate_source_copies(issues, base_path, indexed_rows, requirements, copy_paths) do
    indexed_rows
    |> Enum.zip(requirements)
    |> Enum.reduce(issues, fn {{row, row_index}, requirement}, acc ->
      Enum.reduce(copy_paths, acc, fn copy_path, inner_acc ->
        validate_optional_source_copy(
          inner_acc,
          base_path,
          row_index,
          row,
          copy_path,
          requirement
        )
      end)
    end)
  end

  defp validate_optional_source_copy(
         issues,
         base_path,
         row_index,
         row,
         copy_path,
         requirement
       ) do
    case get_in(row, copy_path) do
      %{} = source_requirement ->
        validate_equal(
          issues,
          Enum.join([base_path <> "[#{row_index}]" | copy_path], "."),
          source_requirement,
          requirement,
          "must match the corresponding enclosing Repair approval requirement"
        )

      _source_requirement ->
        issues
    end
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
