defmodule OrbitalDynamics.Schema.CampaignRepairSourceSchemaValidationBatchHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_schema_validation_batch_report"

  def validate(issues, %{"source_schema_validation_batch_report" => %{} = batch} = artifact) do
    evidence = source_evidence(batch)
    sources = Enum.map(evidence, & &1.source)
    source_issues = Enum.map(evidence, & &1.issue)
    remediations = Enum.map(evidence, & &1.remediation)
    report_copies = Enum.map(evidence, & &1.report)

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
      "must contain one Repair source schema-validation-batch review row per nested error and warning"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      sources,
      [["source"]],
      "must match the corresponding indexed Repair source schema-validation-batch issue collection"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_issues,
      [["source_validation_issue"]],
      "must match the corresponding nested Repair source schema-validation-batch issue"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      remediations,
      [["source_validation_remediation"]],
      "must match the corresponding nested Repair source schema-validation-batch remediation"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      report_copies,
      [["source_schema_validation_report"]],
      "must match the producer-derived nested Repair source schema-validation report"
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
      "must contain one Repair source schema-validation-batch import row per nested error and warning"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      sources,
      [["source"], ["source_review_row", "source"]],
      "must match the corresponding indexed Repair source schema-validation-batch issue collection"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_issues,
      [["source_validation_issue"], ["source_review_row", "source_validation_issue"]],
      "must match the corresponding nested Repair source schema-validation-batch issue"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      remediations,
      [
        ["source_validation_remediation"],
        ["source_review_row", "source_validation_remediation"]
      ],
      "must match the corresponding nested Repair source schema-validation-batch remediation"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      report_copies,
      [
        ["source_schema_validation_report"],
        ["source_review_row", "source_schema_validation_report"]
      ],
      "must match the producer-derived nested Repair source schema-validation report"
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

  defp source_evidence(batch) do
    batch
    |> map_rows("reports")
    |> Enum.with_index()
    |> Enum.flat_map(fn {entry, index} -> entry_evidence(entry, index) end)
  end

  defp entry_evidence(entry, index) do
    case Map.get(entry, "report") do
      %{} = report ->
        report =
          report
          |> Map.put_new("artifact_path", Map.get(entry, "path"))
          |> Map.put("batch_entry_path", Map.get(entry, "path"))

        report_evidence(report, index)

      _report ->
        []
    end
  end

  defp report_evidence(report, index) do
    remediation_by_path =
      report
      |> map_rows("remediation")
      |> Map.new(&{Map.get(&1, "path"), &1})

    source_prefix = @repair_source_prefix <> ".reports[#{index}].report"

    error_evidence =
      report
      |> map_rows("errors")
      |> Enum.map(&evidence(&1, source_prefix <> ".errors", report, remediation_by_path))

    warning_evidence =
      report
      |> map_rows("warnings")
      |> Enum.map(&evidence(&1, source_prefix <> ".warnings", report, remediation_by_path))

    error_evidence ++ warning_evidence
  end

  defp evidence(issue, source, report, remediation_by_path) do
    %{
      issue: issue,
      remediation: Map.get(remediation_by_path, Map.get(issue, "path")),
      report: report,
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
