defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalImportEligibilityHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.OperationalReadiness

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_operational_import_eligibility_summary"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))

    source_reports =
      Enum.map(expected_rows, &Map.get(&1, "source_operational_readiness_report"))

    source_gates =
      Enum.map(expected_rows, &Map.get(&1, "source_operational_readiness_gate"))

    issues
    |> validate_operator_handoff(artifact, expected_sources, source_reports, source_gates)
    |> validate_cadence_handoff(artifact, expected_sources, source_reports, source_gates)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_reports,
         source_gates
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_readiness_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain the exact Repair source operational import-eligibility review rows"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source operational import-eligibility identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_reports,
      [["source_operational_readiness_report"]],
      "must match the enclosing Repair source operational import-eligibility projection"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_gates,
      [["source_operational_readiness_gate"]],
      "must match the corresponding enclosing Repair source operational import-eligibility gate"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_reports,
         _source_gates
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_reports,
         source_gates
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_readiness_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain the exact Repair source operational import-eligibility import rows"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source operational import-eligibility identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_reports,
      [
        ["source_operational_readiness_report"],
        ["source_review_row", "source_operational_readiness_report"]
      ],
      "must match the enclosing Repair source operational import-eligibility projection"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_gates,
      [
        ["source_operational_readiness_gate"],
        ["source_review_row", "source_operational_readiness_gate"]
      ],
      "must match the corresponding enclosing Repair source operational import-eligibility gate"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_reports,
         _source_gates
       ),
       do: issues

  defp source_rows(%{"source_operational_import_eligibility_summary" => summary}) do
    OperationalReadiness.source_report_rows(summary, @source)
  end

  defp source_rows(_artifact), do: []

  defp operator_readiness_row?(row) do
    Map.get(row, "review_type") == "operational_readiness_review" and
      readiness_source?(row_source(row))
  end

  defp cadence_readiness_row?(row) do
    (Map.get(row, "source_review_type") == "operational_readiness_review" or
       Map.get(row, "import_action") == "review_operational_readiness") and
      readiness_source?(row_source(row))
  end

  defp readiness_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source)

  defp readiness_source?(_source), do: false
end
