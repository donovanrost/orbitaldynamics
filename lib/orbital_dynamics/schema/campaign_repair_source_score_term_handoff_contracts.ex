defmodule OrbitalDynamics.Schema.CampaignRepairSourceScoreTermHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_score_term "campaign_repair.source_score_term_report.rows"

  def validate(issues, artifact) when is_map(artifact) do
    rows = source_rows(artifact)

    issues
    |> validate_operator_review_handoff(artifact, rows)
    |> validate_cadence_handoff(artifact, rows)
  end

  def validate(issues, _artifact), do: issues

  defp source_rows(%{"source_score_term_report" => %{"rows" => rows}})
       when is_list(rows),
       do: rows

  defp source_rows(_artifact), do: []

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_score_term_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source score-term review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_score_term"]],
      "must match the corresponding enclosing Repair source score-term report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _source_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         source_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_score_term_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source score-term import row per enclosing report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      List.duplicate(@repair_source_score_term, length(source_rows)),
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source score-term family"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [["source_score_term"], ["source_review_row", "source_score_term"]],
      "must match the corresponding enclosing Repair source score-term report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _source_rows), do: issues

  defp operator_score_term_row?(row) do
    Map.get(row, "review_type") == "score_term_review" and
      row_source(row) == @repair_source_score_term
  end

  defp cadence_score_term_row?(row) do
    (Map.get(row, "source_review_type") == "score_term_review" or
       Map.get(row, "import_action") == "review_score_term") and
      row_source(row) == @repair_source_score_term
  end
end
