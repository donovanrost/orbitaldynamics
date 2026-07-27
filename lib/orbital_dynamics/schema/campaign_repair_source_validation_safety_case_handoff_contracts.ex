defmodule OrbitalDynamics.Schema.CampaignRepairSourceValidationSafetyCaseHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_validation_safety_case_summary"
  @repair_source @repair_source_prefix <> ".evidence"
  @context_fields [
    "schema_contract",
    "schema_version",
    "model",
    "source",
    "summary_id",
    "case_id",
    "status",
    "evidence_count",
    "input_contracts",
    "evidence_status_counts",
    "evidence_refs_by_status",
    "evidence_refs_by_contract",
    "blocked_evidence_count",
    "review_required_evidence_count",
    "accepted_evidence_count",
    "model_accepted_count",
    "model_review_required_count",
    "model_blocked_count",
    "unknown_model_count",
    "readiness_review_required_count",
    "readiness_blocked_count",
    "ready_for_import_count",
    "quality_gate_review_count",
    "quality_gate_blocked_count",
    "schema_error_count",
    "schema_warning_count",
    "schema_validation_report_count",
    "schema_validation_failed_report_count",
    "fixture_passed_count",
    "fixture_failed_count",
    "assumptions",
    "model_limits"
  ]

  def validate(
        issues,
        %{"source_validation_safety_case_summary" => %{} = summary} = artifact
      ) do
    source_rows = reviewable_evidence(summary)
    expected_sources = List.duplicate(@repair_source, length(source_rows))
    summary_contexts = List.duplicate(Map.take(summary, @context_fields), length(source_rows))

    validate_operator_review_handoff(
      issues,
      artifact,
      source_rows,
      summary_contexts,
      expected_sources
    )
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         summary_contexts,
         expected_sources
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_safety_case_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source validation-safety-case review row per reviewable enclosing evidence row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source validation-safety-case summary source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_validation_safety_case_evidence"]],
      "must match the corresponding reviewable enclosing Repair source validation-safety-case evidence"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      summary_contexts,
      [["source_validation_safety_case_summary"]],
      "must match the producer-derived enclosing Repair source validation-safety-case summary context"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _source_rows,
         _summary_contexts,
         _expected_sources
       ),
       do: issues

  defp operator_safety_case_row?(row) do
    Map.get(row, "review_type") == "validation_safety_case_review" and
      repair_safety_case_source?(row_source(row))
  end

  defp repair_safety_case_source?(source) when is_binary(source),
    do: String.starts_with?(source, @repair_source_prefix)

  defp repair_safety_case_source?(_source), do: false

  defp reviewable_evidence(summary) do
    case Map.get(summary, "evidence") do
      rows when is_list(rows) ->
        Enum.filter(
          rows,
          &(is_map(&1) and Map.get(&1, "status") in ["blocked", "review_required"])
        )

      _rows ->
        []
    end
  end
end
