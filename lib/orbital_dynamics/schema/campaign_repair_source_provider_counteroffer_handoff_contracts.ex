defmodule OrbitalDynamics.Schema.CampaignRepairSourceProviderCounterofferHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_provider_counteroffer_report"
  @repair_source @repair_source_prefix <> ".rows"

  def validate(
        issues,
        %{"source_provider_counteroffer_report" => %{} = report} = artifact
      ) do
    source_rows = eligible_rows(report)
    expected_sources = List.duplicate(@repair_source, length(source_rows))

    issues
    |> validate_operator_review_handoff(artifact, source_rows, expected_sources)
    |> validate_cadence_handoff(artifact, source_rows, expected_sources)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         expected_sources
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_counteroffer_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source provider-counteroffer review row per eligible enclosing report row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source provider-counteroffer report source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_provider_counteroffer"]],
      "must match the corresponding eligible enclosing Repair source provider-counteroffer report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _source_rows, _expected_sources),
    do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         source_rows,
         expected_sources
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_counteroffer_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source provider-counteroffer import row per eligible enclosing report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source provider-counteroffer report source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [["source_provider_counteroffer"], ["source_review_row", "source_provider_counteroffer"]],
      "must match the corresponding eligible enclosing Repair source provider-counteroffer report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _source_rows, _expected_sources), do: issues

  defp operator_counteroffer_row?(row) do
    Map.get(row, "review_type") == "provider_counteroffer_review" and
      repair_counteroffer_source?(row_source(row))
  end

  defp cadence_counteroffer_row?(row) do
    (Map.get(row, "source_review_type") == "provider_counteroffer_review" or
       Map.get(row, "import_action") == "review_provider_counteroffer") and
      repair_counteroffer_source?(row_source(row))
  end

  defp repair_counteroffer_source?(source) when is_binary(source),
    do: String.starts_with?(source, @repair_source_prefix)

  defp repair_counteroffer_source?(_source), do: false

  defp eligible_rows(report) do
    case Map.get(report, "rows") do
      rows when is_list(rows) -> Enum.filter(rows, &eligible_row?/1)
      _rows -> []
    end
  end

  defp eligible_row?(%{} = row) do
    Map.get(row, "reviewable") == true and
      Map.get(row, "required_operator_action") == "review_provider_counteroffer"
  end

  defp eligible_row?(_row), do: false
end
