defmodule OrbitalDynamics.Schema.CampaignRepairContactFilterHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Suppression

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_contact_filter_report.suppressed_candidates"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_suppressions = Enum.map(expected_rows, &Map.get(&1, "source_contact_suppression"))

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
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_suppression_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one source contact-filter review row per suppressed candidate"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source contact-filter family and identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_suppressions,
      [["source_contact_suppression"]],
      "must match the corresponding enclosing source contact-filter suppression"
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
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_suppression_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one source contact-filter import row per suppressed candidate"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source contact-filter family and identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_suppressions,
      [["source_contact_suppression"], ["source_review_row", "source_contact_suppression"]],
      "must match the corresponding enclosing source contact-filter suppression"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_suppressions
       ),
       do: issues

  defp source_rows(%{"source_contact_filter_report" => %{} = report}) do
    candidates =
      report
      |> Map.get("suppressed_candidates", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    Suppression.contact_rows(candidates, @source)
  end

  defp source_rows(_artifact), do: []

  defp operator_suppression_row?(row) do
    Map.get(row, "review_type") == "contact_suppression" and
      contact_filter_source?(row_source(row))
  end

  defp cadence_suppression_row?(row) do
    (Map.get(row, "source_review_type") == "contact_suppression" or
       Map.get(row, "import_action") == "review_contact_suppression") and
      contact_filter_source?(row_source(row))
  end

  defp contact_filter_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source)

  defp contact_filter_source?(_source), do: false
end
