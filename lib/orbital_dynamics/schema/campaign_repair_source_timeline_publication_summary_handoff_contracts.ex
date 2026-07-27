defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelinePublicationSummaryHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      indexed_sources: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_timeline_publication_summaries"

  def validate(issues, %{"source_timeline_publication_summaries" => summaries} = artifact)
      when is_list(summaries) do
    expected_sources = indexed_sources(summaries, @repair_source_prefix)

    issues
    |> validate_operator_review_handoff(artifact, summaries, expected_sources)
    |> validate_cadence_handoff(artifact, summaries, expected_sources)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         summaries,
         expected_sources
       ) do
    review_rows =
      indexed_rows(
        Map.get(package, "rows"),
        &operator_publication_row?(&1, expected_sources)
      )

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(summaries),
      "must contain one Repair source timeline publication review row per enclosing summary"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the corresponding enclosing Repair source timeline publication-summary index"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      summaries,
      [["source_timeline_publication_summary"]],
      "must match the corresponding enclosing Repair source timeline publication summary"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _summaries, _sources), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         summaries,
         expected_sources
       ) do
    import_rows =
      indexed_rows(
        Map.get(manifest, "rows"),
        &cadence_publication_row?(&1, expected_sources)
      )

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(summaries),
      "must contain one Repair source timeline publication import row per enclosing summary"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the corresponding enclosing Repair source timeline publication-summary index"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      summaries,
      [
        ["source_timeline_publication_summary"],
        ["source_review_row", "source_timeline_publication_summary"]
      ],
      "must match the corresponding enclosing Repair source timeline publication summary"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _summaries, _sources), do: issues

  defp operator_publication_row?(row, expected_sources) do
    Map.get(row, "review_type") == "timeline_publication_review" and
      row_source(row) in expected_sources
  end

  defp cadence_publication_row?(row, expected_sources) do
    (Map.get(row, "source_review_type") == "timeline_publication_review" or
       Map.get(row, "import_action") == "review_timeline_publication") and
      row_source(row) in expected_sources
  end
end
