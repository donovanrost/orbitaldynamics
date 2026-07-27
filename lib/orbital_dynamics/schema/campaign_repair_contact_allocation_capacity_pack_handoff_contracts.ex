defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationCapacityPackHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.ContactAllocation

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_contact_allocation_report.reduced_capacity_pack_groups"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))

    source_capacity_packs =
      Enum.map(expected_rows, &Map.get(&1, "source_contact_allocation_capacity_pack"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_capacity_packs)
    |> validate_cadence_handoff(artifact, expected_sources, source_capacity_packs)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_capacity_packs
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_capacity_pack_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one source contact-allocation capacity-pack row per reduced-capacity group"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source contact-allocation capacity-pack identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_capacity_packs,
      [["source_contact_allocation_capacity_pack"]],
      "must match the corresponding enclosing source contact-allocation reduced-capacity group"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_capacity_packs
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_capacity_packs
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_capacity_pack_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one source contact-allocation capacity-pack import row per reduced-capacity group"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source contact-allocation capacity-pack identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_capacity_packs,
      [
        ["source_contact_allocation_capacity_pack"],
        ["source_review_row", "source_contact_allocation_capacity_pack"]
      ],
      "must match the corresponding enclosing source contact-allocation reduced-capacity group"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_capacity_packs
       ),
       do: issues

  defp source_rows(%{"source_contact_allocation_report" => %{} = report}) do
    groups =
      report
      |> Map.get("reduced_capacity_pack_groups", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    ContactAllocation.capacity_pack_rows(groups, @source)
  end

  defp source_rows(_artifact), do: []

  defp operator_capacity_pack_row?(row) do
    Map.get(row, "review_type") == "contact_allocation_capacity_pack_review" and
      source_capacity_pack?(row_source(row))
  end

  defp cadence_capacity_pack_row?(row) do
    (Map.get(row, "source_review_type") == "contact_allocation_capacity_pack_review" or
       Map.get(row, "import_action") == "review_contact_allocation_capacity_pack") and
      source_capacity_pack?(row_source(row))
  end

  defp source_capacity_pack?(source) when is_binary(source),
    do: String.starts_with?(source, @source)

  defp source_capacity_pack?(_source), do: false
end
