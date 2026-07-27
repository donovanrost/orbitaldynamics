defmodule OrbitalDynamics.Schema.CampaignRepairResourceFilterSummaryHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.FilterReview

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source_prefix "campaign_repair.source_resource_filter_summary"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_suppressions = Enum.map(expected_rows, &Map.get(&1, "source_resource_suppression"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_suppressions)
    |> validate_cadence_handoff(artifact, expected_sources, source_suppressions)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_suppressions
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_summary_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one source resource-filter summary review row per producer row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source resource-filter summary family and identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_suppressions,
      [["source_resource_suppression"]],
      "must match the corresponding enclosing source resource-filter summary row"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_suppressions
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_suppressions
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_summary_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one source resource-filter summary import row per producer row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source resource-filter summary family and identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_suppressions,
      [["source_resource_suppression"], ["source_review_row", "source_resource_suppression"]],
      "must match the corresponding enclosing source resource-filter summary row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_suppressions
       ),
       do: issues

  defp source_rows(%{
         "source_resource_filter_summary" =>
           %{
             "schema_contract" => "resource_filter_summary.v1"
           } = summary
       }) do
    FilterReview.resource_rows(summary, @source_prefix)
  end

  defp source_rows(_artifact), do: []

  defp operator_summary_row?(row) do
    Map.get(row, "review_type") == "resource_suppression" and
      summary_source?(row_source(row))
  end

  defp cadence_summary_row?(row) do
    (Map.get(row, "source_review_type") == "resource_suppression" or
       Map.get(row, "import_action") == "review_resource_suppression") and
      summary_source?(row_source(row))
  end

  defp summary_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source_prefix)

  defp summary_source?(_source), do: false
end
