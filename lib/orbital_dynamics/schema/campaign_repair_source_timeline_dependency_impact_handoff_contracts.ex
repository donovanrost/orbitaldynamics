defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineDependencyImpactHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.TimelinePublication

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_timeline_dependency_impact_summary"
  @row_source @source <> ".dependency_impact_rows"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))

    source_impact_rows =
      Enum.map(expected_rows, &Map.get(&1, "source_timeline_dependency_impact"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_impact_rows)
    |> validate_cadence_handoff(artifact, expected_sources, source_impact_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_impact_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_impact_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one Repair source dependency-impact review row per enclosing review-required summary row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source dependency-impact summary identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_impact_rows,
      [["source_timeline_dependency_impact"]],
      "must match the corresponding enclosing Repair source dependency-impact summary row"
    )
  end

  defp validate_operator_handoff(issues, _artifact, _expected_sources, _source_impact_rows),
    do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_impact_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_impact_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one Repair source dependency-impact import row per enclosing review-required summary row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source dependency-impact summary identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_impact_rows,
      [
        ["source_timeline_dependency_impact"],
        ["source_review_row", "source_timeline_dependency_impact"]
      ],
      "must match the corresponding enclosing Repair source dependency-impact summary row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _expected_sources, _source_impact_rows),
    do: issues

  defp source_rows(%{"source_timeline_dependency_impact_summary" => summary}) do
    TimelinePublication.source_dependency_impact_rows(summary, @source)
  end

  defp source_rows(_artifact), do: []

  defp operator_impact_row?(row) do
    Map.get(row, "review_type") == "timeline_dependency_impact_review" and
      impact_source?(row_source(row))
  end

  defp cadence_impact_row?(row) do
    (Map.get(row, "source_review_type") == "timeline_dependency_impact_review" or
       Map.get(row, "import_action") == "review_timeline_dependency_impact") and
      impact_source?(row_source(row))
  end

  defp impact_source?(source) when is_binary(source),
    do: String.starts_with?(source, @row_source)

  defp impact_source?(_source), do: false
end
