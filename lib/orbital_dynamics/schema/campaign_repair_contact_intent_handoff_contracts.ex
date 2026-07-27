defmodule OrbitalDynamics.Schema.CampaignRepairContactIntentHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.ContactIntent

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_contact_intents"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_intents = Enum.map(expected_rows, &Map.get(&1, "source_contact_intent"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_intents)
    |> validate_cadence_handoff(artifact, expected_sources, source_intents)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_intents
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_intent_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one direct source contact-intent review row per review-eligible producer row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing direct source contact-intent identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_intents,
      [["source_contact_intent"]],
      "must match the corresponding enclosing direct source contact-intent row"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_intents
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_intents
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_intent_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one direct source contact-intent import row per review-eligible producer row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing direct source contact-intent identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_intents,
      [["source_contact_intent"], ["source_review_row", "source_contact_intent"]],
      "must match the corresponding enclosing direct source contact-intent row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_intents
       ),
       do: issues

  defp source_rows(artifact) do
    artifact
    |> Map.get("source_contact_intents", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> ContactIntent.rows(@source)
  end

  defp operator_intent_row?(row) do
    Map.get(row, "review_type") == "contact_intent_review" and
      direct_intent_source?(row_source(row))
  end

  defp cadence_intent_row?(row) do
    (Map.get(row, "source_review_type") == "contact_intent_review" or
       Map.get(row, "import_action") == "review_contact_intent") and
      direct_intent_source?(row_source(row))
  end

  defp direct_intent_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source)

  defp direct_intent_source?(_source), do: false
end
