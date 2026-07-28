defmodule OrbitalDynamics.Schema.CampaignRepairOperationalReadinessHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @repair_readiness_source "campaign_repair.source_operational_readiness_report"
  @repair_readiness_gate_source "#{@repair_readiness_source}.gates"
  @report_context_fields ~w(
    schema_contract
    report_id
    source_summary_model
    source_summary_schema_contract
    source_artifact_type
    source_artifact_id
    readiness_level
    import_classification
    import_eligible
    status
    handoff_only
    execution_allowed
    cadence_write_allowed
    operator_authority_granted
    execution_boundary
    analysis_mode
    analysis_mode_source
    operational_mode_gate
    gate_count
    passed_gate_count
    review_gate_count
    analysis_gate_count
    blocked_gate_count
    gate_status_counts
    gate_classification_counts
    gate_ids_by_status
    gate_ids_by_classification
    passed_gate_ids
    review_required_gate_ids
    analysis_only_gate_ids
    blocked_gate_ids
    non_passed_gate_count
    non_passed_gate_ids
    non_passed_gates
    gates
    evidence
    model_limits
    assumptions
  )

  def validate(issues, artifact) when is_map(artifact) do
    {report_count, report_context, gate_rows} = source_handoff(artifact)

    issues
    |> validate_operator_review_handoff(artifact, report_count, report_context, gate_rows)
    |> validate_cadence_handoff(artifact, report_count, report_context, gate_rows)
  end

  def validate(issues, _artifact), do: issues

  defp source_handoff(%{"source_operational_readiness_report" => %{} = report}) do
    {1, Map.take(report, @report_context_fields), reviewable_gate_rows(report)}
  end

  defp source_handoff(_artifact), do: {0, %{}, []}

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         report_count,
         report_context,
         gate_rows
       ) do
    report_reviews = indexed_rows(Map.get(package, "rows"), &operator_report_row?/1)
    gate_reviews = indexed_rows(Map.get(package, "rows"), &operator_gate_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(report_reviews),
      report_count,
      "must contain one Repair operational-readiness source-report review row"
    )
    |> validate_equal(
      "$.operator_review_package.rows",
      length(gate_reviews),
      length(gate_rows),
      "must contain one Repair operational-readiness gate review row per enclosing non-passed gate"
    )
    |> validate_report_copies(
      "$.operator_review_package.rows",
      report_reviews ++ gate_reviews,
      report_context,
      [["source_operational_readiness_report"]]
    )
    |> validate_gate_copies(
      "$.operator_review_package.rows",
      gate_reviews,
      gate_rows,
      [["source_operational_readiness_gate"]]
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _report_count,
         _report_context,
         _gate_rows
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         report_count,
         report_context,
         gate_rows
       ) do
    report_imports = indexed_rows(Map.get(manifest, "rows"), &cadence_report_row?/1)
    gate_imports = indexed_rows(Map.get(manifest, "rows"), &cadence_gate_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(report_imports),
      report_count,
      "must contain one Repair operational-readiness source-report import row"
    )
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(gate_imports),
      length(gate_rows),
      "must contain one Repair operational-readiness gate import row per enclosing non-passed gate"
    )
    |> validate_report_copies(
      "$.cadence_import_manifest.rows",
      report_imports ++ gate_imports,
      report_context,
      [
        ["source_operational_readiness_report"],
        ["source_review_row", "source_operational_readiness_report"]
      ]
    )
    |> validate_gate_copies(
      "$.cadence_import_manifest.rows",
      gate_imports,
      gate_rows,
      [
        ["source_operational_readiness_gate"],
        ["source_review_row", "source_operational_readiness_gate"]
      ]
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _report_count,
         _report_context,
         _gate_rows
       ),
       do: issues

  defp reviewable_gate_rows(report) do
    case Map.get(report, "gates") do
      rows when is_list(rows) -> Enum.filter(rows, &reviewable_gate_row?/1)
      _rows -> []
    end
  end

  defp reviewable_gate_row?(%{} = row),
    do: Map.get(row, "status") not in [nil, "passed"]

  defp reviewable_gate_row?(_row), do: false

  defp indexed_rows(rows, predicate) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} -> is_map(row) and predicate.(row) end)
  end

  defp indexed_rows(_rows, _predicate), do: []

  defp operator_report_row?(row),
    do: operator_readiness_row?(row) and Map.get(row, "source") == @repair_readiness_source

  defp operator_gate_row?(row),
    do: operator_readiness_row?(row) and Map.get(row, "source") == @repair_readiness_gate_source

  defp operator_readiness_row?(row),
    do: Map.get(row, "review_type") == "operational_readiness_review"

  defp cadence_report_row?(row),
    do: cadence_readiness_row?(row) and row_source(row) == @repair_readiness_source

  defp cadence_gate_row?(row),
    do: cadence_readiness_row?(row) and row_source(row) == @repair_readiness_gate_source

  defp cadence_readiness_row?(row) do
    Map.get(row, "source_review_type") == "operational_readiness_review" or
      Map.get(row, "import_action") == "review_operational_readiness"
  end

  defp row_source(row),
    do: Map.get(row, "source") || get_in(row, ["source_review_row", "source"])

  defp validate_report_copies(issues, base_path, indexed_rows, report_context, copy_paths) do
    Enum.reduce(indexed_rows, issues, fn {row, row_index}, acc ->
      validate_optional_copies(
        acc,
        base_path,
        row_index,
        row,
        copy_paths,
        report_context,
        "must match the Repair operational-readiness report handoff projection"
      )
    end)
  end

  defp validate_gate_copies(issues, base_path, indexed_rows, gate_rows, copy_paths) do
    indexed_rows
    |> Enum.zip(gate_rows)
    |> Enum.reduce(issues, fn {{row, row_index}, gate_row}, acc ->
      validate_optional_copies(
        acc,
        base_path,
        row_index,
        row,
        copy_paths,
        gate_row,
        "must match the corresponding enclosing Repair operational-readiness gate"
      )
    end)
  end

  defp validate_optional_copies(
         issues,
         base_path,
         row_index,
         row,
         copy_paths,
         expected,
         message
       ) do
    Enum.reduce(copy_paths, issues, fn copy_path, acc ->
      case get_in(row, copy_path) do
        %{} = copy ->
          validate_equal(
            acc,
            Enum.join([base_path <> "[#{row_index}]" | copy_path], "."),
            copy,
            expected,
            message
          )

        _copy ->
          acc
      end
    end)
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
