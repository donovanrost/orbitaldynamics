defmodule OrbitalDynamics.Schema.CampaignRepairQualityGateHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.QualityGate

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source_field "source_quality_gate_report"
  @source "campaign_repair.source_quality_gate_report"

  def validate(issues, artifact) when is_map(artifact) do
    validate_source(issues, artifact, @source_field, @source)
  end

  def validate(issues, _artifact), do: issues

  def validate_source(issues, artifact, source_field, source) when is_map(artifact) do
    expected_rows = QualityGate.source_report_rows(Map.get(artifact, source_field), source)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    source_rows = Enum.map(expected_rows, &Map.get(&1, "source_quality_gate_row"))
    source_reports = Enum.map(expected_rows, &Map.get(&1, "source_quality_gate_report"))

    issues
    |> validate_operator_review_handoff(
      artifact,
      expected_sources,
      source_rows,
      source_reports,
      source
    )
    |> validate_cadence_handoff(artifact, expected_sources, source_rows, source_reports, source)
  end

  def validate_source(issues, _artifact, _source_field, _source), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         source_rows,
         source_reports,
         source
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_quality_gate_row?(&1, source))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one Repair quality-gate review row per enclosing reviewable gate row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair quality-gate source identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_quality_gate_row"]],
      "must match the corresponding enclosing Repair quality-gate report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_reports,
      [["source_quality_gate_report"]],
      "must match the enclosing normalized Repair quality-gate report"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_rows,
         _source_reports,
         _source
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         source_rows,
         source_reports,
         source
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_quality_gate_row?(&1, source))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one Repair quality-gate import row per enclosing reviewable gate row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair quality-gate source identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [
        ["source_quality_gate_row"],
        ["source_review_row", "source_quality_gate_row"]
      ],
      "must match the corresponding enclosing Repair quality-gate report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_reports,
      [
        ["source_quality_gate_report"],
        ["source_review_row", "source_quality_gate_report"]
      ],
      "must match the enclosing normalized Repair quality-gate report"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _source_rows,
         _source_reports,
         _source
       ),
       do: issues

  defp operator_quality_gate_row?(row, source) do
    Map.get(row, "review_type") == "quality_gate_review" and
      quality_gate_source?(row_source(row), source)
  end

  defp cadence_quality_gate_row?(row, source) do
    (Map.get(row, "source_review_type") == "quality_gate_review" or
       Map.get(row, "import_action") == "review_quality_gate") and
      quality_gate_source?(row_source(row), source)
  end

  defp quality_gate_source?(row_source, source) when is_binary(row_source),
    do: String.starts_with?(row_source, source)

  defp quality_gate_source?(_row_source, _source), do: false
end
