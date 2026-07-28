defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelinePreservationStatusHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      indexed_sources: 3,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_timeline_preservation_statuses"

  def validate(issues, artifact) when is_map(artifact) do
    statuses = source_statuses(artifact)
    expected_sources = indexed_sources(statuses, @repair_source_prefix, "status")

    issues
    |> validate_operator_review_handoff(artifact, statuses, expected_sources)
    |> validate_cadence_handoff(artifact, statuses, expected_sources)
  end

  def validate(issues, _artifact), do: issues

  defp source_statuses(%{"source_timeline_preservation_statuses" => statuses})
       when is_list(statuses),
       do: statuses

  defp source_statuses(_artifact), do: []

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         statuses,
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
      length(statuses),
      "must contain one Repair source timeline preservation review row per enclosing status"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the corresponding enclosing Repair source timeline preservation-status index"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      statuses,
      [["source_timeline_preservation"]],
      "must match the corresponding enclosing Repair source timeline preservation status"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _statuses, _sources), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         statuses,
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
      length(statuses),
      "must contain one Repair source timeline preservation import row per enclosing status"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the corresponding enclosing Repair source timeline preservation-status index"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      statuses,
      [
        ["source_timeline_preservation"],
        ["source_review_row", "source_timeline_preservation"]
      ],
      "must match the corresponding enclosing Repair source timeline preservation status"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _statuses, _sources), do: issues

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
    do: String.starts_with?(source, @repair_source_prefix <> "[")

  defp repair_preservation_source?(_source), do: false
end
