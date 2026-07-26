defmodule OrbitalDynamics.Schema.CampaignRepairRealizedFeedbackHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @repair_feedback_source "campaign_repair.source_timeline_feedback_report.rows"

  def validate(
        issues,
        %{"source_timeline_feedback_report" => %{"rows" => feedback_rows}} = artifact
      )
      when is_list(feedback_rows) do
    realized_feedback_rows = Enum.filter(feedback_rows, &realized_feedback_row?/1)

    issues
    |> validate_operator_review_handoff(artifact, realized_feedback_rows)
    |> validate_cadence_handoff(artifact, realized_feedback_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         feedback_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_feedback_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(feedback_rows),
      "must contain one Repair realized-feedback review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      feedback_rows,
      [["source_feedback"]]
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _feedback_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         feedback_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_feedback_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(feedback_rows),
      "must contain one Repair realized-feedback import row per enclosing report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      feedback_rows,
      [
        ["source_feedback"],
        ["source_review_row", "source_feedback"]
      ]
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _feedback_rows), do: issues

  defp indexed_rows(rows, predicate) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} -> is_map(row) and predicate.(row) end)
  end

  defp indexed_rows(_rows, _predicate), do: []

  defp realized_feedback_row?(%{} = row), do: Map.get(row, "status") != "planned_only"
  defp realized_feedback_row?(_row), do: false

  defp operator_feedback_row?(row) do
    Map.get(row, "review_type") == "realized_feedback" and
      row_source(row) == @repair_feedback_source
  end

  defp cadence_feedback_row?(row) do
    (Map.get(row, "source_review_type") == "realized_feedback" or
       Map.get(row, "import_action") in ["record_realized_feedback", "review_realized_feedback"]) and
      row_source(row) == @repair_feedback_source
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
          "must match the corresponding enclosing Repair timeline-feedback report row"
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
