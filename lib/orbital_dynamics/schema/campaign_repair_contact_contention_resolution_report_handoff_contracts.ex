defmodule OrbitalDynamics.Schema.CampaignRepairContactContentionResolutionReportHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_contact_contention_resolution_report.recommendations"

  def validate(issues, artifact) when is_map(artifact) do
    recommendations = source_recommendations(artifact)
    expected_sources = List.duplicate(@source, length(recommendations))

    issues
    |> validate_operator_handoff(artifact, recommendations, expected_sources)
    |> validate_cadence_handoff(artifact, recommendations, expected_sources)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         recommendations,
         expected_sources
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_resolution_report_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(recommendations),
      "must contain one source contention-resolution-report review row per recommendation"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source contention-resolution-report identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      recommendations,
      [["source_recommendation"]],
      "must match the corresponding enclosing source contention-resolution-report recommendation"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _recommendations,
         _expected_sources
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         recommendations,
         expected_sources
       ) do
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_resolution_report_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(recommendations),
      "must contain one source contention-resolution-report import row per recommendation"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source contention-resolution-report identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      recommendations,
      [["source_recommendation"], ["source_review_row", "source_recommendation"]],
      "must match the corresponding enclosing source contention-resolution-report recommendation"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _recommendations,
         _expected_sources
       ),
       do: issues

  defp source_recommendations(artifact) do
    case Map.get(artifact, "source_contact_contention_resolution_report") do
      %{} = report ->
        report
        |> Map.get("recommendations", [])
        |> List.wrap()
        |> Enum.filter(&is_map/1)

      _report ->
        []
    end
  end

  defp operator_resolution_report_row?(row) do
    Map.get(row, "review_type") == "contact_contention_recommendation" and
      resolution_report_source?(row_source(row))
  end

  defp cadence_resolution_report_row?(row) do
    (Map.get(row, "source_review_type") == "contact_contention_recommendation" or
       Map.get(row, "import_action") == "review_contact_contention_resolution") and
      resolution_report_source?(row_source(row))
  end

  defp resolution_report_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source)

  defp resolution_report_source?(_source), do: false
end
