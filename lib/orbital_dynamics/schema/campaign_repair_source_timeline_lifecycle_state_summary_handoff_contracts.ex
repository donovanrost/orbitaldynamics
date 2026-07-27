defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineLifecycleStateSummaryHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_source_summary "campaign_repair.source_timeline_lifecycle_state_summary.review_rows"

  def validate(
        issues,
        %{"source_timeline_lifecycle_state_summary" => %{"review_rows" => rows}} = artifact
      )
      when is_list(rows) do
    issues
    |> validate_operator_review_handoff(artifact, rows)
    |> validate_cadence_handoff(artifact, rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         lifecycle_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_lifecycle_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(lifecycle_rows),
      "must contain one Repair source timeline lifecycle-state review row per enclosing summary review row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      lifecycle_rows,
      [["source_timeline_lifecycle_state"]],
      "must match the corresponding enclosing Repair source timeline lifecycle-state summary review row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _lifecycle_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         lifecycle_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_lifecycle_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(lifecycle_rows),
      "must contain one Repair source timeline lifecycle-state import row per enclosing summary review row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      lifecycle_rows,
      [
        ["source_timeline_lifecycle_state"],
        ["source_review_row", "source_timeline_lifecycle_state"]
      ],
      "must match the corresponding enclosing Repair source timeline lifecycle-state summary review row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _lifecycle_rows), do: issues

  defp operator_lifecycle_row?(row) do
    Map.get(row, "review_type") == "timeline_lifecycle_state_review" and
      row_source(row) == @repair_source_summary
  end

  defp cadence_lifecycle_row?(row) do
    (Map.get(row, "source_review_type") == "timeline_lifecycle_state_review" or
       Map.get(row, "import_action") == "review_timeline_lifecycle_state") and
      row_source(row) == @repair_source_summary
  end
end
