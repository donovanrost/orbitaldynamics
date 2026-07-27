defmodule OrbitalDynamics.Schema.CampaignRepairCandidateDiffHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.CandidateDiff

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source_prefix "campaign_repair.source_candidate_diff_report"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_diffs = Enum.map(expected_rows, &Map.get(&1, "source_candidate_diff"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_diffs)
    |> validate_cadence_handoff(artifact, expected_sources, source_diffs)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_diffs
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_diff_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one source candidate-diff review row per review-eligible producer row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source candidate-diff family and identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_diffs,
      [["source_candidate_diff"]],
      "must match the corresponding enclosing source candidate-diff row"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_diffs
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_diffs
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_diff_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one source candidate-diff import row per review-eligible producer row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source candidate-diff family and identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_diffs,
      [["source_candidate_diff"], ["source_review_row", "source_candidate_diff"]],
      "must match the corresponding enclosing source candidate-diff row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_diffs
       ),
       do: issues

  defp source_rows(%{"source_candidate_diff_report" => %{} = report} = artifact) do
    report =
      Enum.reduce(
        ["invalidated_candidates", "new_candidates", "retained_candidates"],
        report,
        fn field, acc ->
          rows =
            acc
            |> Map.get(field, [])
            |> List.wrap()
            |> Enum.filter(&is_map/1)

          Map.put(acc, field, rows)
        end
      )

    CandidateDiff.report_rows(
      report,
      @source_prefix,
      Map.get(artifact, "source_window_lineage", [])
    )
  end

  defp source_rows(_artifact), do: []

  defp operator_diff_row?(row) do
    Map.get(row, "review_type") == "candidate_diff_review" and
      candidate_diff_source?(row_source(row))
  end

  defp cadence_diff_row?(row) do
    (Map.get(row, "source_review_type") == "candidate_diff_review" or
       Map.get(row, "import_action") == "review_candidate_diff") and
      candidate_diff_source?(row_source(row))
  end

  defp candidate_diff_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source_prefix)

  defp candidate_diff_source?(_source), do: false
end
