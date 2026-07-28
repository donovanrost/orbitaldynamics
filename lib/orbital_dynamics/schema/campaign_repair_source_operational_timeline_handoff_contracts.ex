defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalTimelineHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.OperationalTimeline

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_operational_timeline_report"
  @row_source @source <> ".rows"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_timeline_rows = Enum.map(expected_rows, &Map.get(&1, "source_operational_timeline"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_timeline_rows)
    |> validate_cadence_handoff(artifact, expected_sources, source_timeline_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_timeline_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_timeline_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one Repair source operational-timeline review row per enclosing reviewable report row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source operational-timeline report identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_timeline_rows,
      [["source_operational_timeline"]],
      "must match the corresponding enclosing Repair source operational-timeline report row"
    )
  end

  defp validate_operator_handoff(issues, _artifact, _expected_sources, _source_timeline_rows),
    do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_timeline_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_timeline_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one Repair source operational-timeline import row per enclosing reviewable report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source operational-timeline report identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_timeline_rows,
      [
        ["source_operational_timeline"],
        ["source_review_row", "source_operational_timeline"]
      ],
      "must match the corresponding enclosing Repair source operational-timeline report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _expected_sources, _source_timeline_rows),
    do: issues

  defp source_rows(%{"source_operational_timeline_report" => report}) do
    OperationalTimeline.source_report_rows(report, @source)
  end

  defp source_rows(_artifact), do: []

  defp operator_timeline_row?(row) do
    Map.get(row, "review_type") == "operational_timeline_review" and
      timeline_source?(row_source(row))
  end

  defp cadence_timeline_row?(row) do
    (Map.get(row, "source_review_type") == "operational_timeline_review" or
       Map.get(row, "import_action") == "review_operational_timeline") and
      timeline_source?(row_source(row))
  end

  defp timeline_source?(source) when is_binary(source),
    do: String.starts_with?(source, @row_source)

  defp timeline_source?(_source), do: false
end
