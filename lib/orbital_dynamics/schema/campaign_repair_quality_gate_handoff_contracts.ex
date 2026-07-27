defmodule OrbitalDynamics.Schema.CampaignRepairQualityGateHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_quality_gate_source "campaign_repair.source_quality_gate_report.rows"

  def validate(
        issues,
        %{"source_quality_gate_report" => %{"rows" => gate_rows}} = artifact
      )
      when is_list(gate_rows) do
    source_rows = Enum.filter(gate_rows, &reviewable_gate_row?/1)

    issues
    |> validate_operator_review_handoff(artifact, source_rows)
    |> validate_cadence_handoff(artifact, source_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         gate_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_quality_gate_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(gate_rows),
      "must contain one Repair quality-gate review row per enclosing reviewable gate row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      gate_rows,
      [["source_quality_gate_row"]],
      "must match the corresponding enclosing Repair quality-gate report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _gate_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         gate_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_quality_gate_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(gate_rows),
      "must contain one Repair quality-gate import row per enclosing reviewable gate row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      gate_rows,
      [
        ["source_quality_gate_row"],
        ["source_review_row", "source_quality_gate_row"]
      ],
      "must match the corresponding enclosing Repair quality-gate report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _gate_rows), do: issues

  defp reviewable_gate_row?(%{} = row) do
    (Map.get(row, "status") || Map.get(row, "classification")) not in [
      nil,
      "passed",
      "importable"
    ]
  end

  defp reviewable_gate_row?(_row), do: false

  defp operator_quality_gate_row?(row) do
    Map.get(row, "review_type") == "quality_gate_review" and
      row_source(row) == @repair_quality_gate_source
  end

  defp cadence_quality_gate_row?(row) do
    (Map.get(row, "source_review_type") == "quality_gate_review" or
       Map.get(row, "import_action") == "review_quality_gate") and
      row_source(row) == @repair_quality_gate_source
  end
end
