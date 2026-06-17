defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityLifecycleState.SourceReportFields.Flattened do
  @moduledoc false

  alias __MODULE__.Values

  def source_report_fields(source_reports) do
    %{
      "source_report_timeline_activity_lifecycle_state_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_timeline_activity_lifecycle_state_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_timeline_activity_lifecycle_state_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_timeline_activity_lifecycle_state_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_timeline_activity_lifecycle_state_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_timeline_activity_lifecycle_state_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_timeline_activity_lifecycle_state_review_required_count" =>
        source_report_family_count(source_reports, "review_required_count"),
      "source_report_timeline_activity_lifecycle_state_invalid_activity_input_count" =>
        source_report_family_count(source_reports, "invalid_activity_input_count"),
      "source_report_timeline_activity_lifecycle_state_invalid_activity_input_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "invalid_activity_input_reason_counts"
        ),
      "source_report_timeline_activity_lifecycle_state_transition_decision_counts" =>
        source_report_family_merge_count_maps(source_reports, "transition_decision_counts"),
      "source_report_timeline_activity_lifecycle_state_status_transition_decision_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "status_transition_decision_counts"
        ),
      "source_report_timeline_activity_lifecycle_state_approval_transition_decision_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "approval_transition_decision_counts"
        ),
      "source_report_timeline_activity_lifecycle_state_required_operator_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "required_operator_action_counts"),
      "source_report_timeline_activity_lifecycle_state_import_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "import_action_counts"),
      "source_report_timeline_activity_lifecycle_state_planned_status_category_counts" =>
        source_report_family_merge_count_maps(source_reports, "planned_status_category_counts"),
      "source_report_timeline_activity_lifecycle_state_realized_status_category_counts" =>
        source_report_family_merge_count_maps(source_reports, "realized_status_category_counts"),
      "source_report_timeline_activity_lifecycle_state_planned_approval_category_counts" =>
        source_report_family_merge_count_maps(source_reports, "planned_approval_category_counts"),
      "source_report_timeline_activity_lifecycle_state_realized_approval_category_counts" =>
        source_report_family_merge_count_maps(source_reports, "realized_approval_category_counts"),
      "source_report_timeline_activity_lifecycle_state_status_transition_category_counts" =>
        source_report_family_merge_count_maps(source_reports, "status_transition_category_counts"),
      "source_report_timeline_activity_lifecycle_state_approval_transition_category_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "approval_transition_category_counts"
        ),
      "source_report_timeline_activity_lifecycle_state_transition_application_provenance_count" =>
        source_report_family_count(source_reports, "transition_application_provenance_count"),
      "source_report_timeline_activity_lifecycle_state_transition_application_provenance_helper_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "transition_application_provenance_helper_counts"
        ),
      "source_report_timeline_activity_lifecycle_state_transition_application_provenance_category_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "transition_application_provenance_category_counts"
        ),
      "source_report_timeline_activity_lifecycle_state_transition_application_provenance_operator_action_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "transition_application_provenance_operator_action_reason_counts"
        ),
      "source_report_timeline_activity_lifecycle_state_protection_decision_counts" =>
        source_report_family_merge_count_maps(source_reports, "protection_decision_counts"),
      "source_report_timeline_activity_lifecycle_state_protection_category_counts" =>
        source_report_family_merge_count_maps(source_reports, "protection_category_counts"),
      "source_report_timeline_activity_lifecycle_state_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "activity_id_counts"),
      "source_report_timeline_activity_lifecycle_state_timeline_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "timeline_id_counts"),
      "source_report_timeline_activity_lifecycle_state_review_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "review_activity_id_counts"),
      "source_report_timeline_activity_lifecycle_state_action_routing" =>
        source_report_family_field(source_reports, "action_routing")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["timeline_activity_lifecycle_state"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "timeline_activity_lifecycle_state") do
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
    case Map.get(source_reports, "timeline_activity_lifecycle_state") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("timeline_activity_lifecycle_state", %{})
    |> Map.get(field)
  end

  defp source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end
end
