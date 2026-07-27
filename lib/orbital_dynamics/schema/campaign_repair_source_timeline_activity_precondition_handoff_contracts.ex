defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineActivityPreconditionHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_source_prefix "campaign_repair.source_timeline_activity_precondition_summaries"

  def validate(
        issues,
        %{"source_timeline_activity_precondition_summaries" => summaries} = artifact
      )
      when is_list(summaries) do
    expected_sources =
      summaries
      |> Enum.with_index()
      |> Enum.map(fn {_summary, index} -> "#{@repair_source_prefix}[#{index}].summary" end)

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
        &operator_precondition_row?(&1, expected_sources)
      )

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(summaries),
      "must contain one Repair source timeline activity-precondition review row per enclosing summary"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]]
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      summaries,
      [["source_timeline_activity_precondition_summary"]],
      "must match the corresponding enclosing Repair source timeline activity-precondition summary"
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
        &cadence_precondition_row?(&1, expected_sources)
      )

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(summaries),
      "must contain one Repair source timeline activity-precondition import row per enclosing summary"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]]
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      summaries,
      [
        ["source_timeline_activity_precondition_summary"],
        ["source_review_row", "source_timeline_activity_precondition_summary"]
      ],
      "must match the corresponding enclosing Repair source timeline activity-precondition summary"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _summaries, _sources), do: issues

  defp validate_source_identities(
         issues,
         base_path,
         indexed_rows,
         expected_sources,
         source_paths
       ) do
    indexed_rows
    |> Enum.zip(expected_sources)
    |> Enum.reduce(issues, fn {{row, row_index}, expected_source}, acc ->
      Enum.reduce(source_paths, acc, fn source_path, inner_acc ->
        case get_in(row, source_path) do
          source when is_binary(source) ->
            validate_equal(
              inner_acc,
              Enum.join([base_path <> "[#{row_index}]" | source_path], "."),
              source,
              expected_source,
              "must match the corresponding enclosing Repair source timeline activity-precondition summary index"
            )

          _source ->
            inner_acc
        end
      end)
    end)
  end

  defp operator_precondition_row?(row, expected_sources) do
    Map.get(row, "review_type") == "timeline_activity_precondition_review" and
      row_source(row) in expected_sources
  end

  defp cadence_precondition_row?(row, expected_sources) do
    (Map.get(row, "source_review_type") == "timeline_activity_precondition_review" or
       Map.get(row, "import_action") == "review_timeline_precondition") and
      row_source(row) in expected_sources
  end
end
