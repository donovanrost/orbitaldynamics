defmodule OrbitalDynamics.Schema.CampaignRepairManeuverReviewHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_source_maneuver_review "campaign_repair.source_maneuver_review_report.rows"

  def validate(
        issues,
        %{"source_maneuver_review_report" => %{"rows" => maneuver_rows}} = artifact
      )
      when is_list(maneuver_rows) do
    source_rows = Enum.filter(maneuver_rows, &is_map/1)

    issues
    |> validate_operator_review_handoff(artifact, source_rows)
    |> validate_cadence_handoff(artifact, source_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         maneuver_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_maneuver_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(maneuver_rows),
      "must contain one Repair source maneuver-review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      maneuver_rows,
      [["source_maneuver_review"]],
      "must match the corresponding enclosing Repair source maneuver-review report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _maneuver_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         maneuver_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_maneuver_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(maneuver_rows),
      "must contain one Repair source maneuver-review import row per enclosing report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      maneuver_rows,
      [
        ["source_maneuver_review"],
        ["source_review_row", "source_maneuver_review"]
      ],
      "must match the corresponding enclosing Repair source maneuver-review report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _maneuver_rows), do: issues

  defp operator_maneuver_row?(row) do
    Map.get(row, "review_type") == "maneuver_review" and
      row_source(row) == @repair_source_maneuver_review
  end

  defp cadence_maneuver_row?(row) do
    (Map.get(row, "source_review_type") == "maneuver_review" or
       Map.get(row, "import_action") == "review_maneuver") and
      row_source(row) == @repair_source_maneuver_review
  end
end
