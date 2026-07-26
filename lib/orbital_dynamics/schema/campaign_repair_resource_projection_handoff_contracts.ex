defmodule OrbitalDynamics.Schema.CampaignRepairResourceProjectionHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @repair_projection_source "campaign_repair.source_resource_projection_report.projected_resources"

  def validate(
        issues,
        %{"source_resource_projection_report" => %{"projected_resources" => projection_rows}} =
          artifact
      )
      when is_list(projection_rows) do
    issues
    |> validate_operator_review_handoff(artifact, projection_rows)
    |> validate_cadence_handoff(artifact, projection_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         projection_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_projection_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(projection_rows),
      "must contain one Repair resource-projection review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      projection_rows,
      [["source_resource_projection"]]
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _projection_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         projection_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_projection_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(projection_rows),
      "must contain one Repair resource-projection import row per enclosing report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      projection_rows,
      [
        ["source_resource_projection"],
        ["source_review_row", "source_resource_projection"]
      ]
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _projection_rows), do: issues

  defp indexed_rows(rows, predicate) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} -> is_map(row) and predicate.(row) end)
  end

  defp indexed_rows(_rows, _predicate), do: []

  defp operator_projection_row?(row) do
    Map.get(row, "review_type") == "resource_projection_review" and
      row_source(row) == @repair_projection_source
  end

  defp cadence_projection_row?(row) do
    (Map.get(row, "source_review_type") == "resource_projection_review" or
       Map.get(row, "import_action") == "review_resource_projection") and
      row_source(row) == @repair_projection_source
  end

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp validate_source_copies(issues, base_path, indexed_rows, source_rows, copy_paths) do
    indexed_rows
    |> Enum.zip(source_rows)
    |> Enum.reduce(issues, fn {{row, row_index}, source_row}, acc ->
      Enum.reduce(copy_paths, acc, fn copy_path, inner_acc ->
        validate_optional_source_copy(
          inner_acc,
          base_path,
          row_index,
          row,
          copy_path,
          source_row
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
         source_row
       ) do
    case get_in(row, copy_path) do
      %{} = copy ->
        validate_equal(
          issues,
          Enum.join([base_path <> "[#{row_index}]" | copy_path], "."),
          copy,
          source_row,
          "must match the corresponding enclosing Repair resource-projection report row"
        )

      _copy ->
        issues
    end
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
