defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineDiffSummaryHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_source_summary "campaign_repair.source_timeline_diff_summary.review_rows"

  def validate(issues, %{"source_timeline_diff_summary" => %{} = summary} = artifact) do
    reviewable_rows =
      summary
      |> Map.get("review_rows", [])
      |> reviewable_rows()

    issues
    |> validate_operator_review_handoff(artifact, reviewable_rows, summary)
    |> validate_cadence_handoff(artifact, reviewable_rows, summary)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         timeline_diff_rows,
         summary
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_summary_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(timeline_diff_rows),
      "must contain one Repair source timeline-diff summary review row per enclosing review-required row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      timeline_diff_rows,
      [["source_timeline_diff"]],
      "must match the corresponding enclosing Repair source timeline-diff summary review row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      List.duplicate(summary, length(timeline_diff_rows)),
      [["source_timeline_diff_summary"]],
      "must match the enclosing Repair source timeline-diff summary"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _rows, _summary), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         timeline_diff_rows,
         summary
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_summary_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(timeline_diff_rows),
      "must contain one Repair source timeline-diff summary import row per enclosing review-required row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      timeline_diff_rows,
      [["source_timeline_diff"], ["source_review_row", "source_timeline_diff"]],
      "must match the corresponding enclosing Repair source timeline-diff summary review row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      List.duplicate(summary, length(timeline_diff_rows)),
      [
        ["source_timeline_diff_summary"],
        ["source_review_row", "source_timeline_diff_summary"]
      ],
      "must match the enclosing Repair source timeline-diff summary"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _rows, _summary), do: issues

  defp reviewable_rows(rows) when is_list(rows),
    do: Enum.filter(rows, &reviewable_timeline_diff?/1)

  defp reviewable_rows(_rows), do: []

  defp reviewable_timeline_diff?(%{} = row),
    do: Map.get(row, "requires_operator_review", false)

  defp reviewable_timeline_diff?(_row), do: false

  defp operator_summary_row?(row) do
    Map.get(row, "review_type") == "timeline_diff_review" and
      row_source(row) == @repair_source_summary
  end

  defp cadence_summary_row?(row) do
    (Map.get(row, "source_review_type") == "timeline_diff_review" or
       Map.get(row, "import_action") == "review_timeline_diff") and
      row_source(row) == @repair_source_summary
  end
end
