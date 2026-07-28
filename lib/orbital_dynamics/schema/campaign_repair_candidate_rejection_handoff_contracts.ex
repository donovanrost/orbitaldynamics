defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRejectionHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, validate_equal: 5, validate_source_copies: 6]

  @repair_rejection_source "campaign_repair.source_candidate_rejection_report.rows"

  def validate(issues, artifact) when is_map(artifact) do
    rejection_rows = source_rows(artifact)

    issues
    |> validate_operator_review_handoff(artifact, rejection_rows)
    |> validate_cadence_handoff(artifact, rejection_rows)
  end

  def validate(issues, _artifact), do: issues

  defp source_rows(%{"source_candidate_rejection_report" => %{"rows" => rows}})
       when is_list(rows),
       do: rows

  defp source_rows(_artifact), do: []

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         rejection_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_rejection_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(rejection_rows),
      "must contain one Repair candidate-rejection review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      rejection_rows,
      [["source_candidate_rejection"]],
      "must match the corresponding enclosing Repair candidate-rejection report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _rejection_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         rejection_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_rejection_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(rejection_rows),
      "must contain one Repair candidate-rejection import row per enclosing report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      rejection_rows,
      [
        ["source_candidate_rejection"],
        ["source_review_row", "source_candidate_rejection"]
      ],
      "must match the corresponding enclosing Repair candidate-rejection report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _rejection_rows), do: issues

  defp operator_rejection_row?(row) do
    Map.get(row, "review_type") == "candidate_rejection_review" and
      Map.get(row, "source") == @repair_rejection_source
  end

  defp cadence_rejection_row?(row) do
    (Map.get(row, "source_review_type") == "candidate_rejection_review" or
       Map.get(row, "import_action") == "review_candidate_rejection") and
      Map.get(row, "source") == @repair_rejection_source
  end
end
