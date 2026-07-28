defmodule OrbitalDynamics.Schema.CampaignRepairWarningHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @repair_warning_source "campaign_repair.warnings"

  def validate(issues, %{"warnings" => warnings} = artifact) when is_list(warnings) do
    issues
    |> validate_operator_review_handoff(artifact, warnings)
    |> validate_cadence_handoff(artifact, warnings)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         warnings
       ) do
    warning_rows = indexed_rows(Map.get(package, "rows"), &operator_warning_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.warning_count",
      Map.get(package, "warning_count"),
      length(warnings),
      "must match enclosing Repair warning count"
    )
    |> validate_equal(
      "$.operator_review_package.rows",
      length(warning_rows),
      length(warnings),
      "must contain one warning-review row per enclosing Repair warning"
    )
    |> validate_reason_copies("$.operator_review_package.rows", warning_rows, warnings, [
      ["reason"]
    ])
  end

  defp validate_operator_review_handoff(issues, _artifact, _warnings), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         warnings
       ) do
    warning_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_warning_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(warning_rows),
      length(warnings),
      "must contain one warning-import row per enclosing Repair warning"
    )
    |> validate_reason_copies("$.cadence_import_manifest.rows", warning_rows, warnings, [
      ["reason"],
      ["source_review_row", "reason"]
    ])
  end

  defp validate_cadence_handoff(issues, _artifact, _warnings), do: issues

  defp indexed_rows(rows, predicate) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} -> is_map(row) and predicate.(row) end)
  end

  defp indexed_rows(_rows, _predicate), do: []

  defp operator_warning_row?(row) do
    Map.get(row, "review_type") == "warning" and
      Map.get(row, "source") == @repair_warning_source
  end

  defp cadence_warning_row?(row) do
    (Map.get(row, "source_review_type") == "warning" or
       Map.get(row, "import_action") == "review_warning") and
      Map.get(row, "source") == @repair_warning_source
  end

  defp validate_reason_copies(issues, base_path, indexed_rows, warnings, copy_paths) do
    indexed_rows
    |> Enum.zip(warnings)
    |> Enum.reduce(issues, fn {{row, row_index}, warning}, acc ->
      Enum.reduce(copy_paths, acc, fn copy_path, inner_acc ->
        validate_optional_reason_copy(inner_acc, base_path, row_index, row, copy_path, warning)
      end)
    end)
  end

  defp validate_optional_reason_copy(
         issues,
         base_path,
         row_index,
         row,
         copy_path,
         warning
       ) do
    case get_in(row, copy_path) do
      reason when is_binary(reason) ->
        validate_equal(
          issues,
          Enum.join([base_path <> "[#{row_index}]" | copy_path], "."),
          reason,
          warning,
          "must match the corresponding enclosing Repair warning"
        )

      _reason ->
        issues
    end
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
