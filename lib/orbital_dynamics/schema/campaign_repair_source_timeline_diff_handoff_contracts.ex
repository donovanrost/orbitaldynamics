defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineDiffHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_source_timeline_diff "campaign_repair.source_timeline_diff_report.rows"

  def validate(issues, artifact) when is_map(artifact) do
    rows = source_rows(artifact)
    reviewable_rows = Enum.filter(rows, &reviewable_timeline_diff?/1)

    issues
    |> validate_operator_review_handoff(artifact, reviewable_rows)
    |> validate_cadence_handoff(artifact, reviewable_rows)
  end

  def validate(issues, _artifact), do: issues

  defp source_rows(%{"source_timeline_diff_report" => %{"rows" => rows}})
       when is_list(rows),
       do: rows

  defp source_rows(_artifact), do: []

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         timeline_diff_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_timeline_diff_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(timeline_diff_rows),
      "must contain one Repair source timeline-diff review row per enclosing review-required report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      timeline_diff_rows,
      [["source_timeline_diff"]],
      "must match the corresponding enclosing Repair source timeline-diff report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _timeline_diff_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         timeline_diff_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_timeline_diff_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(timeline_diff_rows),
      "must contain one Repair source timeline-diff import row per enclosing review-required report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      timeline_diff_rows,
      [["source_timeline_diff"], ["source_review_row", "source_timeline_diff"]],
      "must match the corresponding enclosing Repair source timeline-diff report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _timeline_diff_rows), do: issues

  defp reviewable_timeline_diff?(%{} = row),
    do: Map.get(row, "requires_operator_review", false)

  defp reviewable_timeline_diff?(_row), do: false

  defp operator_timeline_diff_row?(row) do
    Map.get(row, "review_type") == "timeline_diff_review" and
      row_source(row) == @repair_source_timeline_diff
  end

  defp cadence_timeline_diff_row?(row) do
    (Map.get(row, "source_review_type") == "timeline_diff_review" or
       Map.get(row, "import_action") == "review_timeline_diff") and
      row_source(row) == @repair_source_timeline_diff
  end
end
