defmodule OrbitalDynamics.CandidateRefresh.TimelineTransitionApplicationRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary derives timeline transition application routing maps from rows" do
    refresh = %{
      "source_timeline_transition_application_report" => %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "application_count" => 99,
        "selected_activity_count" => 99,
        "selected_timeline_integrity_review_count" => 99,
        "selected_timeline_integrity_issue_count" => 99,
        "selected_timeline_integrity_issue_type_counts" => %{"stale_integrity_issue" => 99},
        "selected_activity_id_counts" => %{"stale_selected_activity" => 99},
        "review_required_count" => 99,
        "preserved_source_count" => 99,
        "recorded_replacement_count" => 99,
        "withheld_review_count" => 99,
        "duplicate_timeline_identity_count" => 99,
        "duplicate_source_timeline_identity_count" => 99,
        "duplicate_replacement_timeline_identity_count" => 99,
        "application_status_counts" => %{"stale_status" => 99},
        "transition_decision_counts" => %{"stale_decision" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "duplicate_timeline_identity_scope_counts" => %{"stale_scope" => 99},
        "applications" => [
          %{
            "id" => "timeline_application:selected",
            "application_status" => "selected",
            "transition_decision" => "apply",
            "selected_activity" => %{"activity_id" => "selected_downlink_activity"},
            "required_operator_action" => "none"
          },
          %{
            "id" => "timeline_application:review",
            "application_status" => "operator_review_required",
            "transition_decision" => "review",
            "required_operator_action" => "review_timeline_change",
            "timeline_identity_collision" => true,
            "duplicate_timeline_identity_scope" => "source"
          },
          %{
            "id" => "timeline_application:withheld",
            "application_status" => "withheld_review",
            "transition_decision" => "withhold",
            "required_operator_action" => "review_duplicate_timeline_identity",
            "duplicate_timeline_identity_scope" => "replacement"
          }
        ],
        "selected_activities" => [
          %{
            "activity_id" => "selected_downlink_activity",
            "timeline_id" => "timeline:selected_downlink",
            "timeline_integrity_status" => "review_required",
            "timeline_integrity_issue_count" => 2,
            "timeline_integrity_issue_types" => [
              "missing_dependency_activity",
              "self_dependency_timeline"
            ]
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_transition_application"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_timeline_transition_application_contract" =>
               "timeline_transition_application_report.v1",
             "source_report_timeline_transition_application_count" => 1,
             "source_report_timeline_transition_application_row_count" => 3,
             "source_report_timeline_transition_application_paths" => [
               "source_timeline_transition_application_report"
             ],
             "source_report_timeline_transition_application_application_count" => 3,
             "source_report_timeline_transition_application_selected_activity_count" => 1,
             "source_report_timeline_transition_application_selected_activity_id_counts" => %{
               "selected_downlink_activity" => 1
             },
             "source_report_timeline_transition_application_review_required_count" => 2,
             "source_report_timeline_transition_application_preserved_source_count" => 0,
             "source_report_timeline_transition_application_recorded_replacement_count" => 0,
             "source_report_timeline_transition_application_withheld_review_count" => 2,
             "source_report_timeline_transition_application_duplicate_timeline_identity_count" =>
               2,
             "source_report_timeline_transition_application_duplicate_source_timeline_identity_count" =>
               1,
             "source_report_timeline_transition_application_duplicate_replacement_timeline_identity_count" =>
               1,
             "source_report_timeline_transition_application_status_counts" => %{
               "operator_review_required" => 1,
               "selected" => 1,
               "withheld_review" => 1
             },
             "source_report_timeline_transition_application_decision_counts" => %{
               "apply" => 1,
               "review" => 1,
               "withhold" => 1
             },
             "source_report_timeline_transition_application_required_operator_action_counts" => %{
               "none" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_timeline_change" => 1
             },
             "source_report_timeline_transition_application_duplicate_timeline_identity_scope_counts" =>
               %{
                 "replacement" => 1,
                 "source" => 1
               },
             "source_report_timeline_transition_application_branch_local_timeline_transition_application_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_selected_activity_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_review_required_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_preserved_transition_pressure" =>
               false,
             "source_report_timeline_transition_application_branch_local_duplicate_identity_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_operator_review_pressure" =>
               true,
             "source_reports" => %{
               "timeline_transition_application_report" => %{
                 "contract" => "timeline_transition_application_report.v1",
                 "count" => 1,
                 "row_count" => 3,
                 "paths" => ["source_timeline_transition_application_report"],
                 "application_count" => 3,
                 "selected_activity_count" => 1,
                 "selected_timeline_integrity_review_count" => 1,
                 "selected_timeline_integrity_issue_count" => 2,
                 "selected_timeline_integrity_issue_type_counts" => %{
                   "missing_dependency_activity" => 1,
                   "self_dependency_timeline" => 1
                 },
                 "selected_activity_id_counts" => %{"selected_downlink_activity" => 1},
                 "preserved_source_count" => 0,
                 "recorded_replacement_count" => 0,
                 "duplicate_timeline_identity_count" => 2,
                 "application_status_counts" => %{
                   "operator_review_required" => 1,
                   "selected" => 1,
                   "withheld_review" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_timeline_transition_application_replay_summary",
      "source" =>
        "candidate_refresh.source_report_provenance.timeline_transition_application_report",
      "contract" => "timeline_transition_application_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 3,
      "source_application_count" => 3,
      "source_report_paths" => ["source_timeline_transition_application_report"],
      "selected_activity_count" => 1,
      "selected_timeline_integrity_review_count" => 1,
      "selected_timeline_integrity_issue_count" => 2,
      "selected_timeline_integrity_issue_type_counts" => %{
        "missing_dependency_activity" => 1,
        "self_dependency_timeline" => 1
      },
      "selected_activity_id_counts" => %{"selected_downlink_activity" => 1},
      "review_required_count" => 2,
      "preserved_source_count" => 0,
      "recorded_replacement_count" => 0,
      "withheld_review_count" => 2,
      "duplicate_timeline_identity_count" => 2,
      "duplicate_source_timeline_identity_count" => 1,
      "duplicate_replacement_timeline_identity_count" => 1,
      "application_status_counts" => %{
        "operator_review_required" => 1,
        "selected" => 1,
        "withheld_review" => 1
      },
      "transition_decision_counts" => %{
        "apply" => 1,
        "review" => 1,
        "withhold" => 1
      },
      "required_operator_action_counts" => %{
        "none" => 1,
        "review_duplicate_timeline_identity" => 1,
        "review_timeline_change" => 1
      },
      "duplicate_timeline_identity_scope_counts" => %{
        "replacement" => 1,
        "source" => 1
      },
      "review_activity_id_counts" => %{},
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_transition_application"],
      "branch_local_timeline_transition_application_pressure" => true,
      "branch_local_selected_activity_pressure" => true,
      "branch_local_selected_integrity_pressure" => true,
      "branch_local_review_required_pressure" => true,
      "branch_local_preserved_transition_pressure" => false,
      "branch_local_duplicate_identity_pressure" => true,
      "branch_local_operator_review_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "timeline_transition_application_source_report_provenance_only",
        "operator_authority" => "not_granted_by_timeline_transition_application_replay_summary",
        "timeline_application" => "not_performed_by_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_transition_application_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.timeline_transition_application_replay_summary(refresh) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             refresh
           ) == replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_transition_application_contract" =>
               "timeline_transition_application_report.v1",
             "source_report_timeline_transition_application_count" => 1,
             "source_report_timeline_transition_application_row_count" => 3,
             "source_report_timeline_transition_application_paths" => [
               "source_timeline_transition_application_report"
             ],
             "source_report_timeline_transition_application_application_count" => 3,
             "source_report_timeline_transition_application_selected_activity_id_counts" => %{
               "selected_downlink_activity" => 1
             },
             "source_report_timeline_transition_application_required_operator_action_counts" => %{
               "none" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_timeline_change" => 1
             },
             "source_report_timeline_transition_application_duplicate_timeline_identity_scope_counts" =>
               %{
                 "replacement" => 1,
                 "source" => 1
               },
             "source_report_timeline_transition_application_branch_local_timeline_transition_application_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_selected_activity_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_review_required_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_preserved_transition_pressure" =>
               false,
             "source_report_timeline_transition_application_branch_local_duplicate_identity_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_operator_review_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_transition_application_replay_summary(artifact) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             artifact
           ) == replay_summary
  end
end
