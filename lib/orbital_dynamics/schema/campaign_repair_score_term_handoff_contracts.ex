defmodule OrbitalDynamics.Schema.CampaignRepairScoreTermHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, validate_equal: 5, validate_source_copies: 6]

  @repair_score_term_source "campaign_repair.score_term_report.rows"

  def validate(
        issues,
        %{"score_term_report" => %{"rows" => score_term_rows}} = artifact
      )
      when is_list(score_term_rows) do
    issues
    |> validate_operator_review_handoff(artifact, score_term_rows)
    |> validate_cadence_handoff(artifact, score_term_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         score_term_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_score_term_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(score_term_rows),
      "must contain one Repair score-term review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      score_term_rows,
      [["source_score_term"]],
      "must match the corresponding enclosing Repair score-term report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _score_term_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         score_term_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_score_term_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(score_term_rows),
      "must contain one Repair score-term import row per enclosing report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      score_term_rows,
      [["source_score_term"], ["source_review_row", "source_score_term"]],
      "must match the corresponding enclosing Repair score-term report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _score_term_rows), do: issues

  defp operator_score_term_row?(row) do
    Map.get(row, "review_type") == "score_term_review" and
      Map.get(row, "source") == @repair_score_term_source
  end

  defp cadence_score_term_row?(row) do
    (Map.get(row, "source_review_type") == "score_term_review" or
       Map.get(row, "import_action") == "review_score_term") and
      Map.get(row, "source") == @repair_score_term_source
  end
end
