defmodule OrbitalDynamics.Schema.CampaignRepairResourceProjectionHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_projection_source "campaign_repair.source_resource_projection_report.projected_resources"

  def validate(
        issues,
        %{"source_resource_projection_report" => %{"projected_resources" => projection_rows}} =
          artifact
      )
      when is_list(projection_rows) do
    issues
    |> validate_operator_review_handoff(artifact, projection_rows)
    |> validate_cadence_handoff(artifact, projection_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         projection_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_projection_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(projection_rows),
      "must contain one Repair resource-projection review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      projection_rows,
      [["source_resource_projection"]],
      "must match the corresponding enclosing Repair resource-projection report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _projection_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         projection_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_projection_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(projection_rows),
      "must contain one Repair resource-projection import row per enclosing report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      projection_rows,
      [
        ["source_resource_projection"],
        ["source_review_row", "source_resource_projection"]
      ],
      "must match the corresponding enclosing Repair resource-projection report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _projection_rows), do: issues

  defp operator_projection_row?(row) do
    Map.get(row, "review_type") == "resource_projection_review" and
      row_source(row) == @repair_projection_source
  end

  defp cadence_projection_row?(row) do
    (Map.get(row, "source_review_type") == "resource_projection_review" or
       Map.get(row, "import_action") == "review_resource_projection") and
      row_source(row) == @repair_projection_source
  end
end
