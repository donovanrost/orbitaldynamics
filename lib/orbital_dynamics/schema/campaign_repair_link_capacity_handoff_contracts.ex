defmodule OrbitalDynamics.Schema.CampaignRepairLinkCapacityHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @repair_capacity_source "campaign_repair.link_capacity_report.rows"

  def validate(
        issues,
        %{"link_capacity_report" => %{"rows" => capacity_rows}} = artifact
      )
      when is_list(capacity_rows) do
    source_rows = Enum.filter(capacity_rows, &is_map/1)

    issues
    |> validate_operator_review_handoff(artifact, source_rows)
    |> validate_cadence_handoff(artifact, source_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         capacity_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_capacity_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(capacity_rows),
      "must contain one Repair link-capacity review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      capacity_rows,
      [["source_link_capacity"]]
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _capacity_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         capacity_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_capacity_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(capacity_rows),
      "must contain one Repair link-capacity import row per enclosing report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      capacity_rows,
      [
        ["source_link_capacity"],
        ["source_review_row", "source_link_capacity"]
      ]
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _capacity_rows), do: issues

  defp indexed_rows(rows, predicate) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} -> is_map(row) and predicate.(row) end)
  end

  defp indexed_rows(_rows, _predicate), do: []

  defp operator_capacity_row?(row) do
    Map.get(row, "review_type") == "link_capacity_review" and
      row_source(row) == @repair_capacity_source
  end

  defp cadence_capacity_row?(row) do
    (Map.get(row, "source_review_type") == "link_capacity_review" or
       Map.get(row, "import_action") == "review_link_capacity") and
      row_source(row) == @repair_capacity_source
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
          "must match the corresponding enclosing Repair link-capacity report row"
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
