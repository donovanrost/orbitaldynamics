defmodule OrbitalDynamics.Schema.CampaignRepairContactIntentSummaryHandoffContracts do
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

  @source_prefix "campaign_repair.source_contact_intent_summary"
  @source @source_prefix <> ".summary_contacts"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_intents = Enum.map(expected_rows, &Map.get(&1, "source_contact_intent"))
    summary_contexts = Enum.map(expected_rows, &Map.get(&1, "source_contact_intent_summary"))

    issues
    |> validate_operator_handoff(
      artifact,
      expected_sources,
      source_intents,
      summary_contexts
    )
    |> validate_cadence_handoff(
      artifact,
      expected_sources,
      source_intents,
      summary_contexts
    )
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_intents,
         summary_contexts
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_summary_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one source contact-intent-summary review row per producer row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source contact-intent-summary identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_intents,
      [["source_contact_intent"]],
      "must match the corresponding source contact-intent-summary producer row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      summary_contexts,
      [["source_contact_intent_summary"]],
      "must match the enclosing source contact-intent-summary context"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_intents,
         _summary_contexts
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_intents,
         summary_contexts
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_summary_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one source contact-intent-summary import row per producer row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source contact-intent-summary identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_intents,
      [["source_contact_intent"], ["source_review_row", "source_contact_intent"]],
      "must match the corresponding source contact-intent-summary producer row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      summary_contexts,
      [
        ["source_contact_intent_summary"],
        ["source_review_row", "source_contact_intent_summary"]
      ],
      "must match the enclosing source contact-intent-summary context"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_intents,
         _summary_contexts
       ),
       do: issues

  defp source_rows(%{"source_contact_intent_summary" => %{} = summary}) do
    if safe_summary_shape?(summary) do
      ContactIntent.source_summary_rows(summary, @source_prefix)
    else
      []
    end
  end

  defp source_rows(_artifact), do: []

  defp safe_summary_shape?(%{"rows" => rows}) when is_list(rows) and rows != [],
    do: Enum.all?(rows, &is_map/1)

  defp safe_summary_shape?(summary) do
    map_or_absent?(summary, "contact_ids_by_direction") and
      map_or_absent?(summary, "capacity_pack_contact_ids_by_direction") and
      map_or_absent?(summary, "capacity_pack_required_capacity_fraction_by_direction") and
      map_or_absent?(summary, "contact_ids_by_ground_station_id") and
      direction_routing_shape?(Map.get(summary, "direction_routing"))
  end

  defp direction_routing_shape?(nil), do: true

  defp direction_routing_shape?(%{} = routing),
    do: Enum.all?(routing, fn {_direction, route} -> is_map(route) end)

  defp direction_routing_shape?(_routing), do: true

  defp map_or_absent?(summary, field),
    do: is_nil(Map.get(summary, field)) or is_map(Map.get(summary, field))

  defp operator_summary_row?(row) do
    Map.get(row, "review_type") == "contact_intent_review" and
      summary_source?(row_source(row))
  end

  defp cadence_summary_row?(row) do
    (Map.get(row, "source_review_type") == "contact_intent_review" or
       Map.get(row, "import_action") == "review_contact_intent") and
      summary_source?(row_source(row))
  end

  defp summary_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source)

  defp summary_source?(_source), do: false
end
