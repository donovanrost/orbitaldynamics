defmodule OrbitalDynamics.Schema.CampaignRepairLinkCapacityHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

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
      [["source_link_capacity"]],
      "must match the corresponding enclosing Repair link-capacity report row"
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
      ],
      "must match the corresponding enclosing Repair link-capacity report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _capacity_rows), do: issues

  defp operator_capacity_row?(row) do
    Map.get(row, "review_type") == "link_capacity_review" and
      row_source(row) == @repair_capacity_source
  end

  defp cadence_capacity_row?(row) do
    (Map.get(row, "source_review_type") == "link_capacity_review" or
       Map.get(row, "import_action") == "review_link_capacity") and
      row_source(row) == @repair_capacity_source
  end
end
