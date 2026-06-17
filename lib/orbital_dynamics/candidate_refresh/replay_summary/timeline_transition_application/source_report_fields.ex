defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication

  import __MODULE__.Aggregation

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_transition_application_report", %{})
      |> TimelineTransitionApplication.summary(
        "candidate_refresh.source_report_provenance.timeline_transition_application_report",
        "timeline_transition_application_source_report_provenance_only"
      )

    %{
      "source_report_timeline_transition_application_branch_local_timeline_transition_application_pressure" =>
        Map.get(summary, "branch_local_timeline_transition_application_pressure"),
      "source_report_timeline_transition_application_branch_local_selected_activity_pressure" =>
        Map.get(summary, "branch_local_selected_activity_pressure"),
      "source_report_timeline_transition_application_branch_local_review_required_pressure" =>
        Map.get(summary, "branch_local_review_required_pressure"),
      "source_report_timeline_transition_application_branch_local_preserved_transition_pressure" =>
        Map.get(summary, "branch_local_preserved_transition_pressure"),
      "source_report_timeline_transition_application_branch_local_duplicate_identity_pressure" =>
        Map.get(summary, "branch_local_duplicate_identity_pressure"),
      "source_report_timeline_transition_application_branch_local_operator_review_pressure" =>
        Map.get(summary, "branch_local_operator_review_pressure")
    }
    |> Map.merge(flattened_source_report_fields(source_reports))
  end

  defp flattened_source_report_fields(source_reports) do
    %{
      "source_report_timeline_transition_application_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_timeline_transition_application_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_timeline_transition_application_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_timeline_transition_application_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_timeline_transition_application_application_count" =>
        source_report_family_count(source_reports, "application_count"),
      "source_report_timeline_transition_application_selected_activity_count" =>
        source_report_family_count(source_reports, "selected_activity_count"),
      "source_report_timeline_transition_application_selected_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "selected_activity_id_counts"),
      "source_report_timeline_transition_application_review_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "review_activity_id_counts"),
      "source_report_timeline_transition_application_review_required_count" =>
        source_report_family_count(source_reports, "review_required_count"),
      "source_report_timeline_transition_application_preserved_source_count" =>
        source_report_family_count(source_reports, "preserved_source_count"),
      "source_report_timeline_transition_application_recorded_replacement_count" =>
        source_report_family_count(source_reports, "recorded_replacement_count"),
      "source_report_timeline_transition_application_withheld_review_count" =>
        source_report_family_count(source_reports, "withheld_review_count"),
      "source_report_timeline_transition_application_duplicate_timeline_identity_count" =>
        source_report_family_count(source_reports, "duplicate_timeline_identity_count"),
      "source_report_timeline_transition_application_duplicate_source_timeline_identity_count" =>
        source_report_family_count(source_reports, "duplicate_source_timeline_identity_count"),
      "source_report_timeline_transition_application_duplicate_replacement_timeline_identity_count" =>
        source_report_family_count(
          source_reports,
          "duplicate_replacement_timeline_identity_count"
        ),
      "source_report_timeline_transition_application_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "application_status_counts"),
      "source_report_timeline_transition_application_decision_counts" =>
        source_report_family_merge_count_maps(source_reports, "transition_decision_counts"),
      "source_report_timeline_transition_application_required_operator_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "required_operator_action_counts"),
      "source_report_timeline_transition_application_duplicate_timeline_identity_scope_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "duplicate_timeline_identity_scope_counts"
        )
    }
  end
end
