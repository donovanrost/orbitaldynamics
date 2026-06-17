defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.SourceReportFields.Flattened do
  @moduledoc false

  alias __MODULE__.EvidenceCount
  alias __MODULE__.Values

  def source_report_fields(source_reports) do
    %{
      "source_report_validation_safety_case_evidence_count" =>
        EvidenceCount.source_report_evidence_count(source_reports),
      "source_report_validation_safety_case_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_validation_safety_case_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_validation_safety_case_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_validation_safety_case_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_validation_safety_case_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "status_counts"),
      "source_report_validation_safety_case_evidence_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "evidence_status_counts"),
      "source_report_validation_safety_case_input_contract_counts" =>
        source_report_family_merge_count_maps(source_reports, "input_contract_counts"),
      "source_report_validation_safety_case_evidence_refs_by_status" =>
        source_report_family_merge_string_list_maps(source_reports, "evidence_refs_by_status"),
      "source_report_validation_safety_case_evidence_refs_by_contract" =>
        source_report_family_merge_string_list_maps(source_reports, "evidence_refs_by_contract"),
      "source_report_validation_safety_case_accepted_evidence_count" =>
        EvidenceCount.source_report_evidence_status_count(
          source_reports,
          "accepted_for_use",
          "accepted_evidence_count"
        ),
      "source_report_validation_safety_case_review_required_evidence_count" =>
        EvidenceCount.source_report_evidence_status_count(
          source_reports,
          "review_required",
          "review_required_evidence_count"
        ),
      "source_report_validation_safety_case_blocked_evidence_count" =>
        EvidenceCount.source_report_evidence_status_count(
          source_reports,
          "blocked",
          "blocked_evidence_count"
        ),
      "source_report_validation_safety_case_model_accepted_count" =>
        source_report_family_count(source_reports, "model_accepted_count"),
      "source_report_validation_safety_case_model_review_required_count" =>
        source_report_family_count(source_reports, "model_review_required_count"),
      "source_report_validation_safety_case_model_blocked_count" =>
        source_report_family_count(source_reports, "model_blocked_count"),
      "source_report_validation_safety_case_unknown_model_count" =>
        source_report_family_count(source_reports, "unknown_model_count"),
      "source_report_validation_safety_case_readiness_review_required_count" =>
        source_report_family_count(source_reports, "readiness_review_required_count"),
      "source_report_validation_safety_case_readiness_blocked_count" =>
        source_report_family_count(source_reports, "readiness_blocked_count"),
      "source_report_validation_safety_case_ready_for_import_count" =>
        source_report_family_count(source_reports, "ready_for_import_count"),
      "source_report_validation_safety_case_quality_gate_review_count" =>
        source_report_family_count(source_reports, "quality_gate_review_count"),
      "source_report_validation_safety_case_quality_gate_blocked_count" =>
        source_report_family_count(source_reports, "quality_gate_blocked_count"),
      "source_report_validation_safety_case_schema_error_count" =>
        source_report_family_count(source_reports, "schema_error_count"),
      "source_report_validation_safety_case_schema_warning_count" =>
        source_report_family_count(source_reports, "schema_warning_count"),
      "source_report_validation_safety_case_schema_validation_report_count" =>
        source_report_family_count(source_reports, "schema_validation_report_count"),
      "source_report_validation_safety_case_schema_validation_failed_report_count" =>
        source_report_family_count(source_reports, "schema_validation_failed_report_count"),
      "source_report_validation_safety_case_fixture_passed_count" =>
        source_report_family_count(source_reports, "fixture_passed_count"),
      "source_report_validation_safety_case_fixture_failed_count" =>
        source_report_family_count(source_reports, "fixture_failed_count")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["validation_safety_case_summary"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "validation_safety_case_summary") do
      source_reports
      |> source_report_family_reports()
      |> Enum.map(&Values.numeric_report_count(&1, field))
      |> Enum.sum()
      |> Values.report_count()
    end
  end

  defp source_report_family_identity_count(source_reports, field) do
    if source_report_family_has_identity_counts?(source_reports) do
      source_report_family_count(source_reports, field)
    end
  end

  defp source_report_family_identity_field(source_reports, field) do
    if source_report_family_has_identity_counts?(source_reports) do
      source_report_family_field(source_reports, field)
    end
  end

  defp source_report_family_has_identity_counts?(source_reports) do
    case Map.get(source_reports, "validation_safety_case_summary") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("validation_safety_case_summary", %{})
    |> Map.get(field)
  end

  defp source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end

  defp source_report_family_merge_string_list_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_string_list_maps()
  end
end
