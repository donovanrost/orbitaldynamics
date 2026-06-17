defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.SourceReportFields.Flattened do
  @moduledoc false

  alias __MODULE__.Values

  def source_report_fields(source_reports) do
    %{
      "source_report_timeline_activity_precondition_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_timeline_activity_precondition_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_timeline_activity_precondition_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_timeline_activity_precondition_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_timeline_activity_precondition_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_timeline_activity_precondition_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_timeline_activity_precondition_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "precondition_status_counts"),
      "source_report_timeline_activity_precondition_blocked_precondition_count" =>
        source_report_family_count(source_reports, "blocked_precondition_count"),
      "source_report_timeline_activity_precondition_review_precondition_count" =>
        source_report_family_count(source_reports, "review_precondition_count"),
      "source_report_timeline_activity_precondition_blocked_precondition_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "blocked_precondition_type_counts"),
      "source_report_timeline_activity_precondition_review_precondition_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "review_precondition_type_counts"),
      "source_report_timeline_activity_precondition_invalid_activity_input_count" =>
        source_report_family_count(source_reports, "invalid_activity_input_count"),
      "source_report_timeline_activity_precondition_invalid_activity_input_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "invalid_activity_input_reason_counts"
        ),
      "source_report_timeline_activity_precondition_invalid_activity_input_reasons" =>
        source_report_family_merge_string_lists(source_reports, "invalid_activity_input_reasons"),
      "source_report_timeline_activity_precondition_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "activity_id_counts"),
      "source_report_timeline_activity_precondition_timeline_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "timeline_id_counts"),
      "source_report_timeline_activity_precondition_dependency_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "dependency_activity_id_counts"),
      "source_report_timeline_activity_precondition_dependency_timeline_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "dependency_timeline_id_counts"),
      "source_report_timeline_activity_precondition_exclusive_with_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "exclusive_with_activity_id_counts"),
      "source_report_timeline_activity_precondition_exclusive_with_timeline_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "exclusive_with_timeline_id_counts"),
      "source_report_timeline_activity_precondition_duplicate_dependency_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "duplicate_dependency_activity_id_counts"
        ),
      "source_report_timeline_activity_precondition_duplicate_dependency_timeline_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "duplicate_dependency_timeline_id_counts"
        ),
      "source_report_timeline_activity_precondition_duplicate_exclusivity_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "duplicate_exclusivity_activity_id_counts"
        ),
      "source_report_timeline_activity_precondition_duplicate_exclusivity_timeline_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "duplicate_exclusivity_timeline_id_counts"
        ),
      "source_report_timeline_activity_precondition_allow_overlap_counts" =>
        source_report_family_merge_count_maps(source_reports, "allow_overlap_counts")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["timeline_activity_precondition_summary"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "timeline_activity_precondition_summary") do
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
    case Map.get(source_reports, "timeline_activity_precondition_summary") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("timeline_activity_precondition_summary", %{})
    |> Map.get(field)
  end

  defp source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end

  defp source_report_family_merge_string_lists(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_string_lists()
  end
end
