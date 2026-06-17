defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineIntegrity.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineIntegrity

  import __MODULE__.Aggregation

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_integrity_report", %{})
      |> TimelineIntegrity.summary(
        "candidate_refresh.source_report_provenance.timeline_integrity_report",
        "timeline_integrity_source_report_provenance_only"
      )

    %{
      "source_report_timeline_integrity_branch_local_timeline_integrity_pressure" =>
        Map.get(summary, "branch_local_timeline_integrity_pressure"),
      "source_report_timeline_integrity_branch_local_timeline_integrity_review_pressure" =>
        Map.get(summary, "branch_local_timeline_integrity_review_pressure"),
      "source_report_timeline_integrity_branch_local_dependency_integrity_pressure" =>
        Map.get(summary, "branch_local_dependency_integrity_pressure"),
      "source_report_timeline_integrity_branch_local_exclusivity_integrity_pressure" =>
        Map.get(summary, "branch_local_exclusivity_integrity_pressure")
    }
    |> Map.merge(flattened_source_report_fields(source_reports))
  end

  defp flattened_source_report_fields(source_reports) do
    %{
      "source_report_timeline_integrity_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_timeline_integrity_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_timeline_integrity_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_timeline_integrity_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_timeline_integrity_issue_count" =>
        source_report_family_count(source_reports, "timeline_integrity_issue_count"),
      "source_report_timeline_integrity_review_count" =>
        source_report_family_count(source_reports, "timeline_integrity_review_count"),
      "source_report_timeline_integrity_dependency_issue_count" =>
        source_report_family_count(source_reports, "dependency_issue_count"),
      "source_report_timeline_integrity_exclusivity_issue_count" =>
        source_report_family_count(source_reports, "exclusivity_issue_count"),
      "source_report_timeline_integrity_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "timeline_integrity_status_counts"),
      "source_report_timeline_integrity_issue_type_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "timeline_integrity_issue_type_counts"
        ),
      "source_report_timeline_integrity_required_operator_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "required_operator_action_counts"),
      "source_report_timeline_integrity_review_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "review_activity_id_counts"),
      "source_report_timeline_integrity_review_timeline_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "review_timeline_id_counts"),
      "source_report_timeline_integrity_missing_dependency_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "missing_dependency_activity_id_counts"
        ),
      "source_report_timeline_integrity_missing_dependency_timeline_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "missing_dependency_timeline_id_counts"
        ),
      "source_report_timeline_integrity_exclusivity_violation_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "exclusivity_violation_activity_id_counts"
        ),
      "source_report_timeline_integrity_exclusivity_violation_timeline_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "exclusivity_violation_timeline_id_counts"
        )
    }
  end
end
