defmodule OrbitalDynamics.Schema.CampaignRepairFreshnessHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.RefreshState

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_freshness_report"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_reports = Enum.map(expected_rows, &Map.get(&1, "source_freshness_report"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_reports)
    |> validate_cadence_handoff(artifact, expected_sources, source_reports)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_reports
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_freshness_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain the Repair source freshness review row when required"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source freshness identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_reports,
      [["source_freshness_report"]],
      "must match the enclosing Repair source freshness report"
    )
  end

  defp validate_operator_handoff(issues, _artifact, _expected_sources, _source_reports),
    do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_reports
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_freshness_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain the Repair source freshness import row when required"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source freshness identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_reports,
      [
        ["source_freshness_report"],
        ["source_review_row", "source_freshness_report"]
      ],
      "must match the enclosing Repair source freshness report"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _expected_sources, _source_reports),
    do: issues

  defp source_rows(%{"source_freshness_report" => %{} = report}) do
    RefreshState.freshness_rows(report, @source)
  end

  defp source_rows(_artifact), do: []

  defp operator_freshness_row?(row) do
    Map.get(row, "review_type") == "freshness_review" and source_report?(row_source(row))
  end

  defp cadence_freshness_row?(row) do
    (Map.get(row, "source_review_type") == "freshness_review" or
       Map.get(row, "import_action") == "review_refresh_freshness") and
      source_report?(row_source(row))
  end

  defp source_report?(source) when is_binary(source), do: String.starts_with?(source, @source)
  defp source_report?(_source), do: false
end
