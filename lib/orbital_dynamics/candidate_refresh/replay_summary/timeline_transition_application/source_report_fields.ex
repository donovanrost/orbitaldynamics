defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.Summary
  alias __MODULE__.Pressure

  import __MODULE__.Aggregation

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_transition_application_report", %{})
      |> Summary.summary(
        "candidate_refresh.source_report_provenance.timeline_transition_application_report",
        "timeline_transition_application_source_report_provenance_only"
      )

    summary
    |> Pressure.source_report_fields()
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
