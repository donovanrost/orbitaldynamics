defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_allocation_source "campaign_repair.contact_allocation_report.rows"
  @repair_source_allocation "campaign_repair.source_contact_allocation_report.rows"

  def validate(issues, artifact) do
    issues
    |> validate_report(
      artifact,
      "contact_allocation_report",
      @repair_allocation_source,
      "generated Repair"
    )
    |> validate_report(
      artifact,
      "source_contact_allocation_report",
      @repair_source_allocation,
      "Repair source"
    )
  end

  defp validate_report(issues, artifact, report_field, source, source_label)
       when is_map(artifact) do
    case Map.get(artifact, report_field) do
      %{"rows" => allocation_rows} when is_list(allocation_rows) ->
        source_rows = Enum.filter(allocation_rows, &is_map/1)

        issues
        |> validate_operator_review_handoff(
          artifact,
          source_rows,
          source,
          source_label
        )
        |> validate_cadence_handoff(artifact, source_rows, source, source_label)

      _report ->
        issues
    end
  end

  defp validate_report(issues, _artifact, _report_field, _source, _source_label), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         allocation_rows,
         source,
         source_label
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_allocation_row?(&1, source))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(allocation_rows),
      "must contain one #{source_label} contact-allocation review row per enclosing report row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      List.duplicate(source, length(allocation_rows)),
      [["source"]],
      "must match the enclosing #{source_label} contact-allocation source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      allocation_rows,
      [["source_contact_allocation"]],
      "must match the corresponding enclosing #{source_label} contact-allocation report row"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _allocation_rows,
         _source,
         _source_label
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         allocation_rows,
         source,
         source_label
       ) do
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_allocation_row?(&1, source))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(allocation_rows),
      "must contain one #{source_label} contact-allocation import row per enclosing report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      List.duplicate(source, length(allocation_rows)),
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing #{source_label} contact-allocation source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      allocation_rows,
      [
        ["source_contact_allocation"],
        ["source_review_row", "source_contact_allocation"]
      ],
      "must match the corresponding enclosing #{source_label} contact-allocation report row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _allocation_rows,
         _source,
         _source_label
       ),
       do: issues

  defp operator_allocation_row?(row, source) do
    Map.get(row, "review_type") == "contact_allocation_review" and
      allocation_source?(row_source(row), source)
  end

  defp cadence_allocation_row?(row, source) do
    (Map.get(row, "source_review_type") == "contact_allocation_review" or
       Map.get(row, "import_action") == "review_contact_allocation") and
      allocation_source?(row_source(row), source)
  end

  defp allocation_source?(actual, expected) when is_binary(actual),
    do: String.starts_with?(actual, expected)

  defp allocation_source?(_actual, _expected), do: false
end
