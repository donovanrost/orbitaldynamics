defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelinePreservationReportHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_timeline_preservation_report"
  @repair_source @repair_source_prefix <> ".rows"

  def validate(issues, %{"source_timeline_preservation_report" => %{} = report} = artifact) do
    source_rows = report_rows(report)
    expected_sources = List.duplicate(@repair_source, length(source_rows))

    issues
    |> validate_operator_review_handoff(artifact, source_rows, expected_sources)
    |> validate_cadence_handoff(artifact, source_rows, expected_sources)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         expected_sources
       ) do
    review_rows =
      indexed_rows(
        Map.get(package, "rows"),
        &operator_preservation_row?/1
      )

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source timeline preservation review row per enclosing report row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source timeline preservation-report row source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_timeline_preservation"]],
      "must match the corresponding enclosing Repair source timeline preservation-report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _source_rows, _sources), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         source_rows,
         expected_sources
       ) do
    import_rows =
      indexed_rows(
        Map.get(manifest, "rows"),
        &cadence_preservation_row?/1
      )

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source timeline preservation import row per enclosing report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source timeline preservation-report row source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [
        ["source_timeline_preservation"],
        ["source_review_row", "source_timeline_preservation"]
      ],
      "must match the corresponding enclosing Repair source timeline preservation-report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _source_rows, _sources), do: issues

  defp operator_preservation_row?(row) do
    Map.get(row, "review_type") == "timeline_preservation_review" and
      repair_preservation_source?(row_source(row))
  end

  defp cadence_preservation_row?(row) do
    (Map.get(row, "source_review_type") == "timeline_preservation_review" or
       Map.get(row, "import_action") == "review_timeline_preservation") and
      repair_preservation_source?(row_source(row))
  end

  defp repair_preservation_source?(source) when is_binary(source),
    do: String.starts_with?(source, @repair_source_prefix)

  defp repair_preservation_source?(_source), do: false

  defp report_rows(%{"rows" => rows}) when is_list(rows), do: rows
  defp report_rows(_report), do: []
end
