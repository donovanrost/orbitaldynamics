defmodule OrbitalDynamics.Schema.CampaignRepairSourceSchemaValidationReportHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_schema_validation_report"

  def validate(issues, artifact) when is_map(artifact) do
    report = source_report(artifact)
    evidence = source_evidence(report)
    sources = Enum.map(evidence, & &1.source)
    source_issues = Enum.map(evidence, & &1.issue)
    remediations = Enum.map(evidence, & &1.remediation)
    report_copies = List.duplicate(report, length(evidence))

    issues
    |> validate_operator_review_handoff(
      artifact,
      sources,
      source_issues,
      remediations,
      report_copies
    )
    |> validate_cadence_handoff(
      artifact,
      sources,
      source_issues,
      remediations,
      report_copies
    )
  end

  def validate(issues, _artifact), do: issues

  defp source_report(%{"source_schema_validation_report" => %{} = report}), do: report
  defp source_report(_artifact), do: %{}

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         sources,
         source_issues,
         remediations,
         report_copies
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_schema_validation_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_issues),
      "must contain one Repair source schema-validation review row per enclosing error and warning"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      sources,
      [["source"]],
      "must match the corresponding enclosing Repair source schema-validation issue collection"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_issues,
      [["source_validation_issue"]],
      "must match the corresponding enclosing Repair source schema-validation issue"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      remediations,
      [["source_validation_remediation"]],
      "must match the corresponding enclosing Repair source schema-validation remediation"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      report_copies,
      [["source_schema_validation_report"]],
      "must match the complete enclosing Repair source schema-validation report"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _sources,
         _source_issues,
         _remediations,
         _report_copies
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         sources,
         source_issues,
         remediations,
         report_copies
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_schema_validation_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_issues),
      "must contain one Repair source schema-validation import row per enclosing error and warning"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      sources,
      [["source"], ["source_review_row", "source"]],
      "must match the corresponding enclosing Repair source schema-validation issue collection"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_issues,
      [["source_validation_issue"], ["source_review_row", "source_validation_issue"]],
      "must match the corresponding enclosing Repair source schema-validation issue"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      remediations,
      [
        ["source_validation_remediation"],
        ["source_review_row", "source_validation_remediation"]
      ],
      "must match the corresponding enclosing Repair source schema-validation remediation"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      report_copies,
      [
        ["source_schema_validation_report"],
        ["source_review_row", "source_schema_validation_report"]
      ],
      "must match the complete enclosing Repair source schema-validation report"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _sources,
         _source_issues,
         _remediations,
         _report_copies
       ),
       do: issues

  defp operator_schema_validation_row?(row) do
    Map.get(row, "review_type") == "schema_validation_review" and
      repair_schema_validation_source?(row_source(row))
  end

  defp cadence_schema_validation_row?(row) do
    (Map.get(row, "source_review_type") == "schema_validation_review" or
       Map.get(row, "import_action") == "review_schema_validation") and
      repair_schema_validation_source?(row_source(row))
  end

  defp repair_schema_validation_source?(source) when is_binary(source),
    do: String.starts_with?(source, @repair_source_prefix)

  defp repair_schema_validation_source?(_source), do: false

  defp source_evidence(report) do
    remediation_by_path =
      report
      |> map_rows("remediation")
      |> Map.new(&{Map.get(&1, "path"), &1})

    error_evidence =
      report
      |> map_rows("errors")
      |> Enum.map(&evidence(&1, @repair_source_prefix <> ".errors", remediation_by_path))

    warning_evidence =
      report
      |> map_rows("warnings")
      |> Enum.map(&evidence(&1, @repair_source_prefix <> ".warnings", remediation_by_path))

    error_evidence ++ warning_evidence
  end

  defp evidence(issue, source, remediation_by_path) do
    %{
      issue: issue,
      remediation: Map.get(remediation_by_path, Map.get(issue, "path")),
      source: source
    }
  end

  defp map_rows(report, field) do
    case Map.get(report, field) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end
end
