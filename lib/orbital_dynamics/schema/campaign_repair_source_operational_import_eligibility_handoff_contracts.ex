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
    validate_source(
      issues,
      artifact,
      "source_operational_import_eligibility_summary",
      @source
    )
  end

  def validate(issues, _artifact), do: issues

  def validate_source(issues, artifact, source_field, source) when is_map(artifact) do
    expected_rows = source_rows(artifact, source_field, source)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))

    source_reports =
      Enum.map(expected_rows, &Map.get(&1, "source_operational_readiness_report"))

    source_gates =
      Enum.map(expected_rows, &Map.get(&1, "source_operational_readiness_gate"))

    issues
    |> validate_operator_handoff(
      artifact,
      expected_sources,
      source_reports,
      source_gates,
      source
    )
    |> validate_cadence_handoff(artifact, expected_sources, source_reports, source_gates, source)
  end

  def validate_source(issues, _artifact, _source_field, _source), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_reports,
         source_gates,
         source
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_readiness_row?(&1, source))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain the exact Repair source operational-readiness summary review rows"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source operational-readiness summary identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_reports,
      [["source_operational_readiness_report"]],
      "must match the enclosing Repair source operational-readiness summary projection"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_gates,
      [["source_operational_readiness_gate"]],
      "must match the corresponding enclosing Repair source operational-readiness summary gate"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_reports,
         _source_gates,
         _source
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_reports,
         source_gates,
         source
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_readiness_row?(&1, source))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain the exact Repair source operational-readiness summary import rows"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source operational-readiness summary identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_reports,
      [
        ["source_operational_readiness_report"],
        ["source_review_row", "source_operational_readiness_report"]
      ],
      "must match the enclosing Repair source operational-readiness summary projection"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_gates,
      [
        ["source_operational_readiness_gate"],
        ["source_review_row", "source_operational_readiness_gate"]
      ],
      "must match the corresponding enclosing Repair source operational-readiness summary gate"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_reports,
         _source_gates,
         _source
       ),
       do: issues

  defp source_rows(artifact, source_field, source) do
    OperationalReadiness.source_report_rows(Map.get(artifact, source_field), source)
  end

  defp operator_readiness_row?(row, source) do
    Map.get(row, "review_type") == "operational_readiness_review" and
      readiness_source?(row_source(row), source)
  end

  defp cadence_readiness_row?(row, source) do
    (Map.get(row, "source_review_type") == "operational_readiness_review" or
       Map.get(row, "import_action") == "review_operational_readiness") and
      readiness_source?(row_source(row), source)
  end

  defp readiness_source?(row_source, source) when is_binary(row_source),
    do: String.starts_with?(row_source, source)

  defp readiness_source?(_row_source, _source), do: false
end
