defmodule OrbitalDynamics.CandidateRefresh.TimelineDiffReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "source report summary aggregates timeline diff feedback routing maps" do
    refresh = %{
      "source_timeline_diff_report" => %{
        "schema_contract" => "timeline_diff_report.v1",
        "rows" => [
          %{
            "id" => "duplicate_source",
            "diff_status" => "duplicate",
            "source_activity_id" => "dup_source_a",
            "duplicate_timeline_identity_scope" => "source",
            "required_operator_action" => "review_duplicate_timeline_identity"
          },
          %{
            "id" => "removed_downlink",
            "diff_status" => "removed",
            "source_activity_id" => "dl_removed",
            "source_activity_type" => "downlink",
            "source_ground_station_id" => "equator_prime",
            "source_required_downlink_mb" => 360.0,
            "required_operator_action" => "review_removed_activity"
          },
          %{
            "id" => "removed_observation",
            "diff_status" => "removed",
            "source_activity_context" => %{"id" => "obs_removed"},
            "source_activity_type" => "observe",
            "source_target_id" => "target_a",
            "required_operator_action" => "review_removed_activity"
          },
          %{
            "id" => "changed_downlink",
            "diff_status" => "changed",
            "source_activity_id" => "dl_source",
            "replacement_activity_id" => "dl_replacement",
            "source_activity_type" => "downlink",
            "replacement_activity_type" => "downlink",
            "replacement_ground_station_id" => "equator_prime",
            "selected_downlink_shortfall_mb" => 120.0,
            "required_operator_action" => "review_timeline_change"
          },
          %{
            "id" => "changed_contact",
            "diff_status" => "changed",
            "source_activity_context" => %{"activity_id" => "contact_source"},
            "replacement_activity_context" => %{"id" => "contact_replacement"},
            "replacement_activity_type" => "tracking",
            "replacement_ground_station_id" => "dss_43",
            "contact_success_factor" => 0.25,
            "required_operator_action" => "review_timeline_change"
          },
          %{
            "id" => "changed_observation",
            "diff_status" => "changed",
            "activity_id" => "obs_source",
            "selected_activity_id" => "obs_selected",
            "replacement_activity_type" => "observe",
            "replacement_target_id" => "target_b",
            "observation_success_factor" => 0.5,
            "image_quality_status" => "marginal",
            "required_operator_action" => "review_timeline_change"
          },
          %{
            "id" => "changed_command",
            "diff_status" => "changed",
            "source_timeline_identity" => %{"activity_id" => "cmd_source"},
            "replacement_timeline_identity" => %{"activity_id" => "cmd_replacement"},
            "replacement_activity_type" => "command",
            "replacement_command_window_id" => "cmd_health_1",
            "command_success_factor" => 0.0,
            "required_operator_action" => "review_timeline_change"
          },
          %{
            "id" => "changed_maneuver",
            "diff_status" => "changed",
            "source_activity" => %{"id" => "maneuver_source"},
            "replacement_activity" => %{"activity_id" => "maneuver_replacement"},
            "replacement_activity_type" => "maneuver",
            "replacement_maneuver_id" => "burn_trim_1",
            "maneuver_success_factor" => 0.2,
            "required_operator_action" => "review_timeline_change"
          }
        ],
        "removed_downlink_count" => 99,
        "diff_status_counts" => %{"stale_status" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "duplicate_timeline_identity_scope_counts" => %{"stale_scope" => 99},
        "source_activity_id_counts" => %{"stale_source" => 99},
        "replacement_activity_id_counts" => %{"stale_replacement" => 99},
        "provenance" => %{"trust_boundary" => "ops_timeline_diff"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_timeline_diff_duplicate_timeline_identity_count" => 1,
             "source_report_timeline_diff_duplicate_source_timeline_identity_count" => 1,
             "source_report_timeline_diff_duplicate_replacement_timeline_identity_count" => 0,
             "source_report_timeline_diff_removed_downlink_count" => 1,
             "source_report_timeline_diff_removed_observation_count" => 1,
             "source_report_timeline_diff_changed_downlink_shortfall_count" => 1,
             "source_report_timeline_diff_changed_contact_feedback_count" => 1,
             "source_report_timeline_diff_changed_observation_count" => 1,
             "source_report_timeline_diff_changed_observation_quality_feedback_count" => 1,
             "source_report_timeline_diff_changed_command_feedback_count" => 1,
             "source_report_timeline_diff_changed_maneuver_feedback_count" => 1,
             "source_report_timeline_diff_status_counts" => %{
               "changed" => 5,
               "duplicate" => 1,
               "removed" => 2
             },
             "source_report_timeline_diff_required_operator_action_counts" => %{
               "review_duplicate_timeline_identity" => 1,
               "review_removed_activity" => 2,
               "review_timeline_change" => 5
             },
             "source_report_timeline_diff_duplicate_timeline_identity_scope_counts" => %{
               "source" => 1
             },
             "source_report_timeline_diff_source_activity_id_counts" => %{
               "cmd_source" => 1,
               "contact_source" => 1,
               "dl_removed" => 1,
               "dl_source" => 1,
               "dup_source_a" => 1,
               "maneuver_source" => 1,
               "obs_removed" => 1,
               "obs_source" => 1
             },
             "source_report_timeline_diff_replacement_activity_id_counts" => %{
               "cmd_replacement" => 1,
               "contact_replacement" => 1,
               "dl_replacement" => 1,
               "maneuver_replacement" => 1,
               "obs_selected" => 1
             },
             "source_report_timeline_diff_branch_local_timeline_diff_pressure" => true,
             "source_report_timeline_diff_branch_local_duplicate_identity_pressure" => true,
             "source_report_timeline_diff_branch_local_removed_activity_pressure" => true,
             "source_report_timeline_diff_branch_local_changed_activity_pressure" => true,
             "source_report_timeline_diff_branch_local_activity_routing_pressure" => true,
             "source_report_timeline_diff_branch_local_operator_review_pressure" => true,
             "source_reports" => %{
               "timeline_diff_report" => %{
                 "row_count" => 8,
                 "removed_downlink_count" => 1,
                 "changed_command_feedback_count" => 1,
                 "diff_status_counts" => %{
                   "changed" => 5,
                   "duplicate" => 1,
                   "removed" => 2
                 },
                 "source_activity_id_counts" => %{
                   "cmd_source" => 1,
                   "contact_source" => 1,
                   "dl_removed" => 1,
                   "dl_source" => 1,
                   "dup_source_a" => 1,
                   "maneuver_source" => 1,
                   "obs_removed" => 1,
                   "obs_source" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_timeline_diff_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.timeline_diff_report",
      "contract" => "timeline_diff_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 8,
      "source_report_paths" => ["source_timeline_diff_report"],
      "duplicate_timeline_identity_count" => 1,
      "duplicate_source_timeline_identity_count" => 1,
      "duplicate_replacement_timeline_identity_count" => 0,
      "removed_downlink_count" => 1,
      "removed_observation_count" => 1,
      "changed_downlink_shortfall_count" => 1,
      "changed_contact_feedback_count" => 1,
      "changed_observation_count" => 1,
      "changed_observation_quality_feedback_count" => 1,
      "changed_command_feedback_count" => 1,
      "changed_maneuver_feedback_count" => 1,
      "diff_status_counts" => %{
        "changed" => 5,
        "duplicate" => 1,
        "removed" => 2
      },
      "required_operator_action_counts" => %{
        "review_duplicate_timeline_identity" => 1,
        "review_removed_activity" => 2,
        "review_timeline_change" => 5
      },
      "duplicate_timeline_identity_scope_counts" => %{
        "source" => 1
      },
      "source_activity_id_counts" => %{
        "cmd_source" => 1,
        "contact_source" => 1,
        "dl_removed" => 1,
        "dl_source" => 1,
        "dup_source_a" => 1,
        "maneuver_source" => 1,
        "obs_removed" => 1,
        "obs_source" => 1
      },
      "replacement_activity_id_counts" => %{
        "cmd_replacement" => 1,
        "contact_replacement" => 1,
        "dl_replacement" => 1,
        "maneuver_replacement" => 1,
        "obs_selected" => 1
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_timeline_diff"],
      "branch_local_timeline_diff_pressure" => true,
      "branch_local_duplicate_identity_pressure" => true,
      "branch_local_removed_activity_pressure" => true,
      "branch_local_changed_activity_pressure" => true,
      "branch_local_activity_routing_pressure" => true,
      "branch_local_operator_review_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "timeline_diff_source_report_provenance_only",
        "operator_authority" => "not_granted_by_timeline_diff_replay_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_diff_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.timeline_diff_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_diff_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_diff_changed_maneuver_feedback_count" => 1,
             "source_report_timeline_diff_required_operator_action_counts" => %{
               "review_duplicate_timeline_identity" => 1,
               "review_removed_activity" => 2,
               "review_timeline_change" => 5
             },
             "source_report_timeline_diff_duplicate_timeline_identity_scope_counts" => %{
               "source" => 1
             },
             "source_report_timeline_diff_source_activity_id_counts" => %{
               "cmd_source" => 1,
               "contact_source" => 1,
               "dl_removed" => 1,
               "dl_source" => 1,
               "dup_source_a" => 1,
               "maneuver_source" => 1,
               "obs_removed" => 1,
               "obs_source" => 1
             },
             "source_report_timeline_diff_branch_local_timeline_diff_pressure" => true,
             "source_report_timeline_diff_branch_local_duplicate_identity_pressure" => true,
             "source_report_timeline_diff_branch_local_removed_activity_pressure" => true,
             "source_report_timeline_diff_branch_local_changed_activity_pressure" => true,
             "source_report_timeline_diff_branch_local_activity_routing_pressure" => true,
             "source_report_timeline_diff_branch_local_operator_review_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_diff_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_diff_replay_summary(artifact) ==
             replay_summary
  end

  test "timeline diff replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_timeline_diff_pressure"]
  end

  test "timeline diff replay treats duplicate scope maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_diff_report" => %{
            "contract" => "timeline_diff_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_diff_report"],
            "duplicate_timeline_identity_count" => 0,
            "duplicate_source_timeline_identity_count" => 0,
            "duplicate_replacement_timeline_identity_count" => 0,
            "removed_downlink_count" => 0,
            "removed_observation_count" => 0,
            "changed_downlink_shortfall_count" => 0,
            "changed_contact_feedback_count" => 0,
            "changed_observation_count" => 0,
            "changed_observation_quality_feedback_count" => 0,
            "changed_command_feedback_count" => 0,
            "changed_maneuver_feedback_count" => 0,
            "diff_status_counts" => %{},
            "required_operator_action_counts" => %{},
            "duplicate_timeline_identity_scope_counts" => %{"source" => 1},
            "source_activity_id_counts" => %{},
            "replacement_activity_id_counts" => %{},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_timeline_diff"]
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["duplicate_timeline_identity_count"] == 0
    assert summary["duplicate_timeline_identity_scope_counts"] == %{"source" => 1}
    assert summary["branch_local_timeline_diff_pressure"]
    assert summary["branch_local_duplicate_identity_pressure"]
    refute summary["branch_local_removed_activity_pressure"]
    refute summary["branch_local_changed_activity_pressure"]
    refute summary["branch_local_activity_routing_pressure"]
    refute summary["branch_local_operator_review_pressure"]
  end

  test "timeline diff replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_diff_report" => %{
              "contract" => "timeline_diff_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_diff_report"
              ],
              "duplicate_timeline_identity_count" => 1,
              "duplicate_source_timeline_identity_count" => 1,
              "duplicate_replacement_timeline_identity_count" => 0,
              "removed_downlink_count" => 1,
              "removed_observation_count" => 0,
              "changed_downlink_shortfall_count" => 1,
              "changed_contact_feedback_count" => 1,
              "changed_observation_count" => 0,
              "changed_observation_quality_feedback_count" => 0,
              "changed_command_feedback_count" => 1,
              "changed_maneuver_feedback_count" => 0,
              "diff_status_counts" => %{"changed" => 3, "duplicate" => 1, "removed" => 1},
              "required_operator_action_counts" => %{
                "review_duplicate_timeline_identity" => 1,
                "review_removed_activity" => 1,
                "review_timeline_change" => 3
              },
              "duplicate_timeline_identity_scope_counts" => %{"source" => 1},
              "source_activity_id_counts" => %{
                "branch_command_source" => 1,
                "branch_downlink_removed" => 1
              },
              "replacement_activity_id_counts" => %{
                "branch_command_replacement" => 1,
                "branch_contact_replacement" => 1
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_timeline_diff"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_diff_report"

    assert summary["contract"] == "timeline_diff_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_diff_report"
           ]

    assert summary["duplicate_timeline_identity_count"] == 1
    assert summary["duplicate_source_timeline_identity_count"] == 1
    assert summary["duplicate_replacement_timeline_identity_count"] == 0
    assert summary["removed_downlink_count"] == 1
    assert summary["removed_observation_count"] == 0
    assert summary["changed_downlink_shortfall_count"] == 1
    assert summary["changed_contact_feedback_count"] == 1
    assert summary["changed_observation_count"] == 0
    assert summary["changed_observation_quality_feedback_count"] == 0
    assert summary["changed_command_feedback_count"] == 1
    assert summary["changed_maneuver_feedback_count"] == 0

    assert summary["diff_status_counts"] == %{"changed" => 3, "duplicate" => 1, "removed" => 1}

    assert summary["required_operator_action_counts"] == %{
             "review_duplicate_timeline_identity" => 1,
             "review_removed_activity" => 1,
             "review_timeline_change" => 3
           }

    assert summary["duplicate_timeline_identity_scope_counts"] == %{"source" => 1}

    assert summary["source_activity_id_counts"] == %{
             "branch_command_source" => 1,
             "branch_downlink_removed" => 1
           }

    assert summary["replacement_activity_id_counts"] == %{
             "branch_command_replacement" => 1,
             "branch_contact_replacement" => 1
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_timeline_diff"]
    assert summary["branch_local_timeline_diff_pressure"]
    assert summary["branch_local_duplicate_identity_pressure"]
    assert summary["branch_local_removed_activity_pressure"]
    assert summary["branch_local_changed_activity_pressure"]
    assert summary["branch_local_activity_routing_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_diff_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_diff_replay_summary(artifact) ==
             summary
  end

  test "timeline diff replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_diff_report" => %{
            "contract" => "timeline_diff_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_diff_report"
            ],
            "duplicate_timeline_identity_scope_counts" => %{"source" => 1},
            "source_activity_id_counts" => %{"direct_source_activity" => 1},
            "replacement_activity_id_counts" => %{"direct_replacement_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_diff_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_diff_report"
           ]

    assert summary["duplicate_timeline_identity_scope_counts"] == %{"source" => 1}
    assert summary["source_activity_id_counts"] == %{"direct_source_activity" => 1}
    assert summary["replacement_activity_id_counts"] == %{"direct_replacement_activity" => 1}
    assert summary["branch_local_timeline_diff_pressure"]
    assert summary["branch_local_duplicate_identity_pressure"]
    assert summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_diff_candidate_source_report_summary_only"
  end

  test "timeline diff replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_diff_report" => %{},
            "command_window_report" => %{
              "contract" => "command_window_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_command_window_report"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_diff_report" => %{
            "contract" => "timeline_diff_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_diff_report"],
            "removed_downlink_count" => 1,
            "diff_status_counts" => %{"removed" => 1},
            "required_operator_action_counts" => %{"review_removed_activity" => 1},
            "source_activity_id_counts" => %{"provenance_removed" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(artifact)

    assert summary["source"] == "candidate_refresh.source_report_provenance.timeline_diff_report"
    assert summary["source_report_paths"] == ["source_timeline_diff_report"]
    assert summary["removed_downlink_count"] == 1
    assert summary["diff_status_counts"] == %{"removed" => 1}
    assert summary["required_operator_action_counts"] == %{"review_removed_activity" => 1}
    assert summary["source_activity_id_counts"] == %{"provenance_removed" => 1}
    assert summary["branch_local_timeline_diff_pressure"]
    assert summary["branch_local_removed_activity_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_diff_source_report_provenance_only"
  end

  test "timeline diff replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_diff_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_diff_report"
              ],
              "source_activity_id_counts" => %{"branch_source_activity" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_diff_report" => %{
            "contract" => "timeline_diff_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_diff_report"],
            "removed_downlink_count" => 9,
            "diff_status_counts" => %{"removed" => 9},
            "source_activity_id_counts" => %{"provenance_source_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_diff_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_diff_report"
           ]

    assert summary["removed_downlink_count"] == 0
    assert summary["diff_status_counts"] == %{}
    assert summary["source_activity_id_counts"] == %{"branch_source_activity" => 1}
    assert summary["branch_local_timeline_diff_pressure"]
    refute summary["branch_local_removed_activity_pressure"]
    assert summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_diff_candidate_source_report_summary_only"
  end

  test "source report summary replays compact timeline diff summaries" do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :dl_removed,
        type: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:dl_removed"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :cmd_added,
        type: :command,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      }
    ]

    summary =
      source
      |> Timeline.diff_report(replacement, source: "candidate_refresh.prior_timeline_diff")
      |> Timeline.diff_summary()
      |> Map.put("provenance", %{"trust_boundary" => "ops_timeline_diff_summary"})

    refresh = %{
      "accepted_planning_state" => %{"timeline_diff_summary" => summary},
      "mission_state" => %{"source_timeline_diff_summary" => summary},
      "source_timeline_diff_summary" => summary,
      "source_result_artifact" => %{"timeline_diff_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_timeline_diff_status_counts" => %{
               "added" => 4,
               "changed" => 4,
               "removed" => 4
             },
             "source_report_timeline_diff_required_operator_action_counts" => %{
               "review_added_activity" => 4,
               "review_changed_protected_activity" => 4,
               "review_removed_activity" => 4
             },
             "source_reports" => %{
               "timeline_diff_report" => %{
                 "paths" => [
                   "accepted_planning_state.timeline_diff_summary",
                   "mission_state.source_timeline_diff_summary",
                   "source_timeline_diff_summary",
                   "source_result_artifact.timeline_diff_summary"
                 ],
                 "contract" => "timeline_diff_summary.v1",
                 "count" => 4,
                 "row_count" => 12,
                 "removed_downlink_count" => 0,
                 "changed_command_feedback_count" => 0,
                 "diff_status_counts" => %{
                   "added" => 4,
                   "changed" => 4,
                   "removed" => 4
                 },
                 "required_operator_action_counts" => %{
                   "review_added_activity" => 4,
                   "review_changed_protected_activity" => 4,
                   "review_removed_activity" => 4
                 },
                 "source_activity_id_counts" => %{"cmd_lock" => 4, "dl_removed" => 4},
                 "replacement_activity_id_counts" => %{"cmd_added" => 4, "cmd_lock" => 4},
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_timeline_diff_summary"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.timeline_diff_replay_summary(refresh)

    assert replay_summary["contract"] == "timeline_diff_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 12

    assert replay_summary["source_report_paths"] == [
             "accepted_planning_state.timeline_diff_summary",
             "mission_state.source_timeline_diff_summary",
             "source_timeline_diff_summary",
             "source_result_artifact.timeline_diff_summary"
           ]

    assert replay_summary["diff_status_counts"] == %{
             "added" => 4,
             "changed" => 4,
             "removed" => 4
           }

    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["ops_timeline_diff_summary"]
    assert replay_summary["branch_local_timeline_diff_pressure"]
    refute replay_summary["branch_local_removed_activity_pressure"]
    assert replay_summary["branch_local_activity_routing_pressure"]
    assert replay_summary["branch_local_operator_review_pressure"]
    refute replay_summary["branch_local_changed_activity_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.timeline_diff_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_diff_replay_summary(refresh) ==
             replay_summary
  end

  test "source report summary replays exact timeline diff summaries from result artifacts" do
    source = [
      %{
        id: :exact_cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:exact_cmd_lock"}
      },
      %{
        id: :exact_dl_removed,
        type: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:exact_dl_removed"}
      }
    ]

    replacement = [
      %{
        id: :exact_cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:exact_cmd_lock"}
      },
      %{
        id: :exact_cmd_added,
        type: :command,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        metadata: %{timeline_id: :"timeline:exact_cmd_added"}
      }
    ]

    summary =
      source
      |> Timeline.diff_report(replacement, source: "candidate_refresh.exact_timeline_diff")
      |> Timeline.diff_summary()

    assert {:ok, %{"schema_contract" => "timeline_diff_summary.v1"}} =
             Schema.validate_artifact(summary)

    source_summary =
      Map.put(summary, "provenance", %{"trust_boundary" => "exact_source_timeline_diff"})

    result_summary =
      Map.put(summary, "provenance", %{"trust_boundary" => "exact_result_timeline_diff"})

    refresh = %{
      "source_result_artifact" => source_summary,
      "result_artifact" => result_summary
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 2,
             "source_report_counts_by_contract" => %{"timeline_diff_summary.v1" => 2},
             "source_reports" => %{
               "timeline_diff_report" => %{
                 "paths" => ["source_result_artifact", "result_artifact"],
                 "contract" => "timeline_diff_summary.v1",
                 "count" => 2,
                 "row_count" => 6,
                 "diff_status_counts" => %{
                   "added" => 2,
                   "changed" => 2,
                   "removed" => 2
                 },
                 "required_operator_action_counts" => %{
                   "review_added_activity" => 2,
                   "review_changed_protected_activity" => 2,
                   "review_removed_activity" => 2
                 },
                 "source_activity_id_counts" => %{
                   "exact_cmd_lock" => 2,
                   "exact_dl_removed" => 2
                 },
                 "replacement_activity_id_counts" => %{
                   "exact_cmd_added" => 2,
                   "exact_cmd_lock" => 2
                 },
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "exact_result_timeline_diff",
                   "exact_source_timeline_diff"
                 ]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "timeline_diff_summary.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 6,
             "source_report_paths" => ["source_result_artifact", "result_artifact"],
             "diff_status_counts" => %{
               "added" => 2,
               "changed" => 2,
               "removed" => 2
             },
             "required_operator_action_counts" => %{
               "review_added_activity" => 2,
               "review_changed_protected_activity" => 2,
               "review_removed_activity" => 2
             },
             "trust_boundaries" => [
               "exact_result_timeline_diff",
               "exact_source_timeline_diff"
             ],
             "branch_local_timeline_diff_pressure" => true,
             "branch_local_activity_routing_pressure" => true,
             "branch_local_operator_review_pressure" => true
           } = CandidateRefresh.timeline_diff_replay_summary(refresh)
  end
end
