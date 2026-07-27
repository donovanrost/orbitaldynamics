defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineTransitionApplicationReportHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_timeline_transition_application_report"
  @repair_source @repair_source_prefix <> ".applications"

  def validate(
        issues,
        %{"source_timeline_transition_application_report" => %{} = report} = artifact
      ) do
    source_rows = review_required_applications(report)
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
        &operator_application_row?/1
      )

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source timeline transition-application review row per review-required enclosing application"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source timeline transition-application-report source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_timeline_application"]],
      "must match the corresponding review-required enclosing Repair source timeline application"
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
        &cadence_application_row?/1
      )

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source timeline transition-application import row per review-required enclosing application"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source timeline transition-application-report source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [
        ["source_timeline_application"],
        ["source_review_row", "source_timeline_application"]
      ],
      "must match the corresponding review-required enclosing Repair source timeline application"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _source_rows, _sources), do: issues

  defp operator_application_row?(row) do
    Map.get(row, "review_type") == "timeline_diff_review" and
      repair_application_source?(row_source(row))
  end

  defp cadence_application_row?(row) do
    (Map.get(row, "source_review_type") == "timeline_diff_review" or
       Map.get(row, "import_action") == "review_timeline_diff") and
      repair_application_source?(row_source(row))
  end

  defp repair_application_source?(source) when is_binary(source),
    do: String.starts_with?(source, @repair_source_prefix)

  defp repair_application_source?(_source), do: false

  defp review_required_applications(%{"applications" => applications})
       when is_list(applications),
       do:
         Enum.filter(
           applications,
           &(is_map(&1) and Map.get(&1, "requires_operator_review") == true)
         )

  defp review_required_applications(_report), do: []
end
