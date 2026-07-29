defmodule OrbitalDynamics.Schema.CampaignRepairGeneratedConstraintHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_constraint "campaign_repair.constraint_report.rows"

  def validate(issues, artifact) when is_map(artifact) do
    rows = source_rows(artifact)
    reviewable_rows = Enum.filter(rows, &reviewable_constraint?/1)

    issues
    |> validate_operator_review_handoff(artifact, reviewable_rows)
    |> validate_cadence_handoff(artifact, reviewable_rows)
  end

  def validate(issues, _artifact), do: issues

  defp source_rows(%{"constraint_report" => %{"rows" => rows}}) when is_list(rows),
    do: rows

  defp source_rows(_artifact), do: []

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         constraint_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_constraint_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(constraint_rows),
      "must contain one Repair generated constraint review row per enclosing non-passing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      constraint_rows,
      [["source_constraint_row"]],
      "must match the corresponding enclosing Repair generated constraint report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _constraint_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         constraint_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_constraint_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(constraint_rows),
      "must contain one Repair generated constraint import row per enclosing non-passing report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      List.duplicate(@repair_constraint, length(constraint_rows)),
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair generated constraint family"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      constraint_rows,
      [["source_constraint_row"], ["source_review_row", "source_constraint_row"]],
      "must match the corresponding enclosing Repair generated constraint report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _constraint_rows), do: issues

  defp reviewable_constraint?(%{} = row), do: Map.get(row, "status") != "pass"
  defp reviewable_constraint?(_row), do: false

  defp operator_constraint_row?(row) do
    Map.get(row, "review_type") == "constraint_review" and
      row_source(row) == @repair_constraint
  end

  defp cadence_constraint_row?(row) do
    (Map.get(row, "source_review_type") == "constraint_review" or
       Map.get(row, "import_action") == "review_constraint") and
      row_source(row) == @repair_constraint
  end
end
