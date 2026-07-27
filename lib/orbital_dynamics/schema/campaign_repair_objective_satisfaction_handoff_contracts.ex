defmodule OrbitalDynamics.Schema.CampaignRepairObjectiveSatisfactionHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_source_objective "campaign_repair.source_objective_satisfaction_report.rows"
  @pass_statuses ~w(met selected no_requirement)

  def validate(
        issues,
        %{"source_objective_satisfaction_report" => %{"rows" => objective_rows}} = artifact
      )
      when is_list(objective_rows) do
    source_rows = Enum.filter(objective_rows, &reviewable_objective?/1)

    issues
    |> validate_operator_review_handoff(artifact, source_rows)
    |> validate_cadence_handoff(artifact, source_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         objective_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_objective_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(objective_rows),
      "must contain one Repair source objective-satisfaction review row per enclosing non-pass report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      objective_rows,
      [["source_objective_satisfaction"]],
      "must match the corresponding enclosing Repair source objective-satisfaction report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _objective_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         objective_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_objective_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(objective_rows),
      "must contain one Repair source objective-satisfaction import row per enclosing non-pass report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      objective_rows,
      [
        ["source_objective_satisfaction"],
        ["source_review_row", "source_objective_satisfaction"]
      ],
      "must match the corresponding enclosing Repair source objective-satisfaction report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _objective_rows), do: issues

  defp reviewable_objective?(%{} = row), do: Map.get(row, "status") not in @pass_statuses
  defp reviewable_objective?(_row), do: false

  defp operator_objective_row?(row) do
    Map.get(row, "review_type") == "objective_satisfaction_review" and
      row_source(row) == @repair_source_objective
  end

  defp cadence_objective_row?(row) do
    (Map.get(row, "source_review_type") == "objective_satisfaction_review" or
       Map.get(row, "import_action") == "review_objective_satisfaction") and
      row_source(row) == @repair_source_objective
  end
end
