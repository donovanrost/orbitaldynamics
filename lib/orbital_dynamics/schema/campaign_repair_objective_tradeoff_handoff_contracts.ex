defmodule OrbitalDynamics.Schema.CampaignRepairObjectiveTradeoffHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_tradeoff_source "campaign_repair.objective_tradeoff_report.tradeoffs"

  def validate(
        issues,
        %{"objective_tradeoff_report" => %{"tradeoffs" => tradeoffs}} = artifact
      )
      when is_list(tradeoffs) do
    issues
    |> validate_operator_review_handoff(artifact, tradeoffs)
    |> validate_cadence_handoff(artifact, tradeoffs)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         tradeoffs
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_tradeoff_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(tradeoffs),
      "must contain one Repair objective-tradeoff review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      tradeoffs,
      [["source_objective_tradeoff"]],
      "must match the corresponding enclosing Repair objective-tradeoff report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _tradeoffs), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         tradeoffs
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_tradeoff_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(tradeoffs),
      "must contain one Repair objective-tradeoff import row per enclosing report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      List.duplicate(@repair_tradeoff_source, length(tradeoffs)),
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair objective-tradeoff family"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      tradeoffs,
      [
        ["source_objective_tradeoff"],
        ["source_review_row", "source_objective_tradeoff"]
      ],
      "must match the corresponding enclosing Repair objective-tradeoff report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _tradeoffs), do: issues

  defp operator_tradeoff_row?(row) do
    Map.get(row, "review_type") == "objective_tradeoff_review" and
      Map.get(row, "source") == @repair_tradeoff_source
  end

  defp cadence_tradeoff_row?(row) do
    (Map.get(row, "source_review_type") == "objective_tradeoff_review" or
       Map.get(row, "import_action") == "review_objective_tradeoff") and
      Map.get(row, "source") == @repair_tradeoff_source
  end
end
