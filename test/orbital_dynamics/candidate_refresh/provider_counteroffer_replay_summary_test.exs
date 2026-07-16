defmodule OrbitalDynamics.CandidateRefresh.ProviderCounterofferReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary accepts provider counteroffer review summaries" do
    review_summary = %{
      "model" => "artifact_only_provider_counteroffer_review_summary",
      "schema_contract" => "provider_counteroffer_review_summary.v1",
      "source_artifact_type" => "provider_counteroffer_report.v1",
      "source_counteroffer_artifact_type" => "station_calendar_report.v1",
      "source_artifact_id" => "provider_counteroffer_artifact_1",
      "counteroffer_count" => 1,
      "reviewable_count" => 1,
      "counteroffer_review_status" => "review_required",
      "counteroffer_status_counts" => %{"proposed" => 1},
      "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
      "counteroffer_lock_deadline_count" => 1,
      "earliest_counteroffer_lock_deadline_s" => 150.0,
      "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
      "counteroffer_ids_by_lock_deadline_status" => %{
        "expired" => ["provider_offer_1"]
      },
      "review_counteroffer_ids" => ["provider_offer_1"],
      "review_rows" => [
        %{
          "provider_counteroffer_id" => "provider_offer_1",
          "provider_counteroffer_status" => "proposed",
          "provider_counteroffer_negotiation_state" => "proposed",
          "provider_counteroffer_lock_deadline_s" => 150.0,
          "provider_counteroffer_lock_deadline_status" => "expired",
          "reviewable" => true,
          "required_operator_action" => "review_provider_counteroffer"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_writes",
        "source" => "provider_counteroffer_report.v1",
        "operator_authority" => "not_granted_by_summary"
      }
    }

    refresh = %{"source_provider_counteroffer_review_summary" => review_summary}

    assert %{
             "source_report_family_count" => 1,
             "source_report_provider_counteroffer_contract" =>
               "provider_counteroffer_review_summary.v1",
             "source_report_provider_counteroffer_count" => 1,
             "source_report_provider_counteroffer_row_count" => 1,
             "source_report_provider_counteroffer_paths" => [
               "source_provider_counteroffer_review_summary"
             ],
             "source_report_provider_counteroffer_reviewable_count" => 1,
             "source_report_provider_counteroffer_lock_deadline_count" => 1,
             "source_report_provider_counteroffer_earliest_lock_deadline_s" => 150.0,
             "source_report_provider_counteroffer_status_counts" => %{"proposed" => 1},
             "source_report_provider_counteroffer_required_operator_action_counts" => %{
               "review_provider_counteroffer" => 1
             },
             "source_report_provider_counteroffer_review_summary_count" => 1,
             "source_report_provider_counteroffer_review_status_counts" => %{
               "review_required" => 1
             },
             "source_report_provider_counteroffer_negotiation_state_counts" => %{
               "proposed" => 1
             },
             "source_report_provider_counteroffer_lock_deadline_status_counts" => %{
               "expired" => 1
             },
             "source_report_provider_counteroffer_counteroffer_ids_by_lock_deadline_status" => %{
               "expired" => ["provider_offer_1"]
             },
             "source_report_provider_counteroffer_review_counteroffer_ids" => [
               "provider_offer_1"
             ],
             "source_reports" => %{
               "provider_counteroffer_report" => %{
                 "paths" => ["source_provider_counteroffer_review_summary"],
                 "contract" => "provider_counteroffer_review_summary.v1",
                 "count" => 1,
                 "row_count" => 1,
                 "reviewable_count" => 1,
                 "review_summary_count" => 1,
                 "counteroffer_review_status_counts" => %{"review_required" => 1},
                 "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
                 "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
                 "counteroffer_ids_by_lock_deadline_status" => %{
                   "expired" => ["provider_offer_1"]
                 },
                 "review_counteroffer_ids" => ["provider_offer_1"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "provider_counteroffer_review_summary.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["source_provider_counteroffer_review_summary"],
             "reviewable_count" => 1,
             "counteroffer_lock_deadline_count" => 1,
             "earliest_counteroffer_lock_deadline_s" => 150.0,
             "counteroffer_status_counts" => %{"proposed" => 1},
             "required_operator_action_counts" => %{
               "review_provider_counteroffer" => 1
             },
             "review_summary_count" => 1,
             "counteroffer_review_status_counts" => %{"review_required" => 1},
             "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
             "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
             "counteroffer_ids_by_lock_deadline_status" => %{
               "expired" => ["provider_offer_1"]
             },
             "review_counteroffer_ids" => ["provider_offer_1"],
             "branch_local_counteroffer_pressure" => true,
             "branch_local_counteroffer_review_pressure" => true,
             "branch_local_counteroffer_lock_pressure" => true,
             "branch_local_counteroffer_import_readiness_pressure" => false,
             "branch_local_plan_impact_pressure" => false,
             "assumptions" => %{
               "provider_write" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.provider_counteroffer_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.provider_counteroffer_replay_summary(artifact) == replay_summary

    wrapped_summary =
      CandidateRefresh.source_report_summary(%{
        "source_result_artifact" => [
          %{"source_provider_counteroffer_review_summary" => review_summary}
        ]
      })

    assert get_in(wrapped_summary, [
             "source_reports",
             "provider_counteroffer_report",
             "paths"
           ]) == [
             "source_result_artifact[0].source_provider_counteroffer_review_summary"
           ]
  end

  test "source report summary derives provider counteroffer routing maps from rows" do
    refresh = %{
      "source_provider_counteroffer_report" => %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "counteroffer_status_counts" => %{"stale_status" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "rows" => [
          %{
            "id" => "provider_counteroffer:offer_1",
            "provider_counteroffer_id" => "offer_1",
            "provider_counteroffer_status" => "proposed",
            "provider_counteroffer_cost_delta" => 40.0,
            "provider_counteroffer_lock_deadline_s" => 180.0,
            "provider_counteroffer_start_delta_s" => 15.0,
            "provider_counteroffer_end_delta_s" => 20.0,
            "provider_counteroffer_duration_delta_s" => 5.0,
            "reviewable" => true,
            "required_operator_action" => "review_provider_counteroffer",
            "trust_boundary" => "counterparty_provider"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_provider_counteroffer"}
      },
      "source_provider_counteroffer_plan_impact_summary" => %{
        "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
        "plan_impact_status" => "review_required",
        "affected_station_calendar_entry_ids" => ["contact_original"],
        "affected_provider_entry_ids" => ["provider_offer_2"],
        "impact_counteroffer_ids" => ["offer_2"],
        "timing_shift_counteroffer_ids" => ["offer_2"],
        "cost_delta_counteroffer_ids" => ["offer_2"],
        "counteroffer_status_counts" => %{"stale_impact_status" => 99},
        "required_operator_action_counts" => %{"stale_impact_action" => 99},
        "impact_rows" => [
          %{
            "id" => "provider_counteroffer:offer_2",
            "provider_counteroffer_id" => "offer_2",
            "provider_counteroffer_status" => "proposed",
            "provider_counteroffer_cost_delta" => 60.0,
            "provider_counteroffer_lock_deadline_s" => 120.0,
            "provider_counteroffer_start_delta_s" => 30.0,
            "provider_counteroffer_end_delta_s" => 30.0,
            "provider_counteroffer_duration_delta_s" => 0.0,
            "reviewable" => true,
            "required_operator_action" => "review_provider_counteroffer",
            "trust_boundary" => "provider_calendar_feed"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_plan_impact_summary"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_provider_counteroffer_contract" => "provider_counteroffer_report.v1",
             "source_report_provider_counteroffer_count" => 2,
             "source_report_provider_counteroffer_row_count" => 2,
             "source_report_provider_counteroffer_paths" => [
               "source_provider_counteroffer_report",
               "source_provider_counteroffer_plan_impact_summary"
             ],
             "source_report_provider_counteroffer_reviewable_count" => 2,
             "source_report_provider_counteroffer_cost_delta_count" => 2,
             "source_report_provider_counteroffer_cost_delta_total" => 100.0,
             "source_report_provider_counteroffer_timing_shift_count" => 2,
             "source_report_provider_counteroffer_start_delta_count" => 2,
             "source_report_provider_counteroffer_end_delta_count" => 2,
             "source_report_provider_counteroffer_duration_delta_count" => 2,
             "source_report_provider_counteroffer_lock_deadline_count" => 2,
             "source_report_provider_counteroffer_earliest_lock_deadline_s" => 120.0,
             "source_report_provider_counteroffer_status_counts" => %{"proposed" => 2},
             "source_report_provider_counteroffer_required_operator_action_counts" => %{
               "review_provider_counteroffer" => 2
             },
             "source_report_provider_counteroffer_plan_impact_summary_count" => 1,
             "source_report_provider_counteroffer_plan_impact_status_counts" => %{
               "review_required" => 1
             },
             "source_report_provider_counteroffer_affected_station_calendar_entry_ids" => [
               "contact_original"
             ],
             "source_report_provider_counteroffer_affected_provider_entry_ids" => [
               "provider_offer_2"
             ],
             "source_report_provider_counteroffer_impact_counteroffer_ids" => ["offer_2"],
             "source_report_provider_counteroffer_timing_shift_counteroffer_ids" => ["offer_2"],
             "source_report_provider_counteroffer_cost_delta_counteroffer_ids" => ["offer_2"],
             "source_report_provider_counteroffer_branch_local_counteroffer_pressure" => true,
             "source_report_provider_counteroffer_branch_local_review_pressure" => true,
             "source_report_provider_counteroffer_branch_local_cost_pressure" => true,
             "source_report_provider_counteroffer_branch_local_timing_pressure" => true,
             "source_report_provider_counteroffer_branch_local_lock_pressure" => true,
             "source_report_provider_counteroffer_branch_local_import_readiness_pressure" =>
               false,
             "source_report_provider_counteroffer_branch_local_plan_impact_pressure" => true,
             "source_reports" => %{
               "provider_counteroffer_report" => %{
                 "count" => 2,
                 "row_count" => 2,
                 "counteroffer_cost_delta_total" => 100.0,
                 "earliest_counteroffer_lock_deadline_s" => 120.0,
                 "plan_impact_summary_count" => 1
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_provider_counteroffer_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.provider_counteroffer_report",
      "contract" => "provider_counteroffer_report.v1",
      "source_report_count" => 2,
      "source_report_row_count" => 2,
      "source_report_paths" => [
        "source_provider_counteroffer_report",
        "source_provider_counteroffer_plan_impact_summary"
      ],
      "reviewable_count" => 2,
      "counteroffer_cost_delta_count" => 2,
      "counteroffer_cost_delta_total" => 100.0,
      "counteroffer_timing_shift_count" => 2,
      "counteroffer_start_delta_count" => 2,
      "counteroffer_end_delta_count" => 2,
      "counteroffer_duration_delta_count" => 2,
      "counteroffer_lock_deadline_count" => 2,
      "earliest_counteroffer_lock_deadline_s" => 120.0,
      "counteroffer_status_counts" => %{"proposed" => 2},
      "required_operator_action_counts" => %{"review_provider_counteroffer" => 2},
      "review_summary_count" => 0,
      "counteroffer_review_status_counts" => %{},
      "counteroffer_negotiation_state_counts" => %{},
      "plan_impact_summary_count" => 1,
      "plan_impact_status_counts" => %{"review_required" => 1},
      "import_readiness_summary_count" => 0,
      "import_readiness_status_counts" => %{},
      "import_classification_counts" => %{},
      "provider_counteroffer_import_status_counts" => %{},
      "counteroffer_ids_by_import_status" => %{},
      "counteroffer_ids_by_required_import_action" => %{},
      "counteroffer_ids_by_lock_deadline_status" => %{},
      "counteroffer_lock_deadline_status_counts" => %{},
      "review_counteroffer_ids" => [],
      "no_import_required_counteroffer_ids" => [],
      "affected_station_calendar_entry_ids" => ["contact_original"],
      "affected_provider_entry_ids" => ["provider_offer_2"],
      "impact_counteroffer_ids" => ["offer_2"],
      "timing_shift_counteroffer_ids" => ["offer_2"],
      "cost_delta_counteroffer_ids" => ["offer_2"],
      "trust_boundary_status" => "declared",
      "trust_boundaries" => [
        "counterparty_provider",
        "ops_plan_impact_summary",
        "ops_provider_counteroffer",
        "provider_calendar_feed"
      ],
      "branch_local_counteroffer_pressure" => true,
      "branch_local_counteroffer_review_pressure" => true,
      "branch_local_counteroffer_cost_pressure" => true,
      "branch_local_counteroffer_timing_pressure" => true,
      "branch_local_counteroffer_lock_pressure" => true,
      "branch_local_counteroffer_import_readiness_pressure" => false,
      "branch_local_plan_impact_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "provider_counteroffer_source_report_provenance_only",
        "operator_authority" => "not_granted_by_provider_counteroffer_replay_summary",
        "provider_write" => "not_performed_by_summary",
        "schedule_mutation" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_provider_counteroffer_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.provider_counteroffer_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_provider_counteroffer_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "quality_gate_report", %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "counteroffer_status_counts" => %{"unrelated" => 99},
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_provider_counteroffer_contract" => "provider_counteroffer_report.v1",
             "source_report_provider_counteroffer_count" => 2,
             "source_report_provider_counteroffer_row_count" => 2,
             "source_report_provider_counteroffer_paths" => [
               "source_provider_counteroffer_report",
               "source_provider_counteroffer_plan_impact_summary"
             ],
             "source_report_provider_counteroffer_reviewable_count" => 2,
             "source_report_provider_counteroffer_cost_delta_total" => 100.0,
             "source_report_provider_counteroffer_earliest_lock_deadline_s" => 120.0,
             "source_report_provider_counteroffer_status_counts" => %{"proposed" => 2},
             "source_report_provider_counteroffer_plan_impact_status_counts" => %{
               "review_required" => 1
             },
             "source_report_provider_counteroffer_cost_delta_counteroffer_ids" => ["offer_2"],
             "source_report_provider_counteroffer_branch_local_counteroffer_pressure" => true,
             "source_report_provider_counteroffer_branch_local_review_pressure" => true,
             "source_report_provider_counteroffer_branch_local_cost_pressure" => true,
             "source_report_provider_counteroffer_branch_local_timing_pressure" => true,
             "source_report_provider_counteroffer_branch_local_lock_pressure" => true,
             "source_report_provider_counteroffer_branch_local_import_readiness_pressure" =>
               false,
             "source_report_provider_counteroffer_branch_local_plan_impact_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.provider_counteroffer_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_provider_counteroffer_replay_summary(artifact) ==
             replay_summary
  end

  test "source report summary replays exact provider counteroffer reports from result artifacts" do
    source_report = %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "source" => "exact.source.provider_counteroffers",
      "counteroffer_status_counts" => %{"stale_status" => 99},
      "required_operator_action_counts" => %{"stale_action" => 99},
      "rows" => [
        %{
          "id" => "provider_counteroffer:exact:offer_source",
          "provider_counteroffer_id" => "offer_source",
          "provider_counteroffer_status" => "proposed",
          "provider_counteroffer_cost_delta" => 40.0,
          "provider_counteroffer_lock_deadline_s" => 180.0,
          "provider_counteroffer_start_delta_s" => 15.0,
          "provider_counteroffer_end_delta_s" => 20.0,
          "provider_counteroffer_duration_delta_s" => 5.0,
          "reviewable" => true,
          "required_operator_action" => "review_provider_counteroffer",
          "trust_boundary" => "exact_source_provider_row",
          "source_station_calendar_entry" => %{
            "id" => "contact_source",
            "trust_boundary" => "provider_calendar_feed"
          }
        }
      ],
      "provenance" => %{"trust_boundary" => "exact_source_provider_report"}
    }

    result_report = %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "source" => "exact.result.provider_counteroffers",
      "counteroffer_status_counts" => %{"stale_result_status" => 99},
      "required_operator_action_counts" => %{"stale_result_action" => 99},
      "rows" => [
        %{
          "id" => "provider_counteroffer:exact:offer_result",
          "provider_counteroffer_id" => "offer_result",
          "provider_counteroffer_status" => "accepted",
          "provider_counteroffer_cost_delta" => 60.0,
          "provider_counteroffer_lock_deadline_s" => 120.0,
          "provider_counteroffer_start_delta_s" => 30.0,
          "provider_counteroffer_end_delta_s" => 35.0,
          "provider_counteroffer_duration_delta_s" => 5.0,
          "reviewable" => false,
          "required_operator_action" => "none",
          "trust_boundary" => "exact_result_provider_row",
          "source_station_calendar_entry" => %{
            "id" => "contact_result",
            "trust_boundary" => "provider_calendar_feed"
          }
        }
      ],
      "provenance" => %{"trust_boundary" => "exact_result_provider_report"}
    }

    refresh = %{
      "source_result_artifact" => source_report,
      "result_artifact" => result_report
    }

    assert %{
             "source_report_provider_counteroffer_contract" => "provider_counteroffer_report.v1",
             "source_report_provider_counteroffer_count" => 2,
             "source_report_provider_counteroffer_row_count" => 2,
             "source_report_provider_counteroffer_paths" => [
               "source_result_artifact",
               "result_artifact"
             ],
             "source_report_provider_counteroffer_reviewable_count" => 1,
             "source_report_provider_counteroffer_cost_delta_count" => 2,
             "source_report_provider_counteroffer_cost_delta_total" => 100.0,
             "source_report_provider_counteroffer_timing_shift_count" => 2,
             "source_report_provider_counteroffer_start_delta_count" => 2,
             "source_report_provider_counteroffer_end_delta_count" => 2,
             "source_report_provider_counteroffer_duration_delta_count" => 2,
             "source_report_provider_counteroffer_lock_deadline_count" => 2,
             "source_report_provider_counteroffer_earliest_lock_deadline_s" => 120.0,
             "source_report_provider_counteroffer_status_counts" => %{
               "accepted" => 1,
               "proposed" => 1
             },
             "source_report_provider_counteroffer_required_operator_action_counts" => %{
               "none" => 1,
               "review_provider_counteroffer" => 1
             },
             "source_reports" => %{
               "provider_counteroffer_report" => %{
                 "paths" => ["source_result_artifact", "result_artifact"],
                 "contract" => "provider_counteroffer_report.v1",
                 "count" => 2,
                 "row_count" => 2,
                 "reviewable_count" => 1,
                 "counteroffer_cost_delta_count" => 2,
                 "counteroffer_cost_delta_total" => 100.0,
                 "counteroffer_timing_shift_count" => 2,
                 "counteroffer_start_delta_count" => 2,
                 "counteroffer_end_delta_count" => 2,
                 "counteroffer_duration_delta_count" => 2,
                 "counteroffer_lock_deadline_count" => 2,
                 "earliest_counteroffer_lock_deadline_s" => 120.0,
                 "counteroffer_status_counts" => %{
                   "accepted" => 1,
                   "proposed" => 1
                 },
                 "required_operator_action_counts" => %{
                   "none" => 1,
                   "review_provider_counteroffer" => 1
                 },
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "exact_result_provider_report",
                   "exact_result_provider_row",
                   "exact_source_provider_report",
                   "exact_source_provider_row",
                   "provider_calendar_feed"
                 ]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "provider_counteroffer_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => ["source_result_artifact", "result_artifact"],
             "reviewable_count" => 1,
             "counteroffer_cost_delta_count" => 2,
             "counteroffer_cost_delta_total" => 100.0,
             "counteroffer_timing_shift_count" => 2,
             "counteroffer_start_delta_count" => 2,
             "counteroffer_end_delta_count" => 2,
             "counteroffer_duration_delta_count" => 2,
             "counteroffer_lock_deadline_count" => 2,
             "earliest_counteroffer_lock_deadline_s" => 120.0,
             "counteroffer_status_counts" => %{"accepted" => 1, "proposed" => 1},
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_provider_counteroffer" => 1
             },
             "trust_boundaries" => [
               "exact_result_provider_report",
               "exact_result_provider_row",
               "exact_source_provider_report",
               "exact_source_provider_row",
               "provider_calendar_feed"
             ],
             "branch_local_counteroffer_pressure" => true,
             "branch_local_counteroffer_review_pressure" => true,
             "branch_local_counteroffer_cost_pressure" => true,
             "branch_local_counteroffer_timing_pressure" => true,
             "branch_local_counteroffer_lock_pressure" => true,
             "branch_local_counteroffer_import_readiness_pressure" => false,
             "branch_local_plan_impact_pressure" => false
           } = CandidateRefresh.provider_counteroffer_replay_summary(refresh)
  end

  test "provider counteroffer replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.provider_counteroffer_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_provider_counteroffer_contract")
    refute Map.has_key?(source_summary, "source_report_provider_counteroffer_count")
    refute Map.has_key?(source_summary, "source_report_provider_counteroffer_row_count")
    refute Map.has_key?(source_summary, "source_report_provider_counteroffer_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_counteroffer_pressure"]
  end

  test "provider counteroffer source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "provider_counteroffer_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.provider_counteroffer_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.provider_counteroffer_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "provider_counteroffer_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_provider_counteroffer_contract"] ==
                 "provider_counteroffer_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_provider_counteroffer_contract")
      end

      refute Map.has_key?(source_summary, "source_report_provider_counteroffer_count")
      refute Map.has_key?(source_summary, "source_report_provider_counteroffer_row_count")
      refute Map.has_key?(source_summary, "source_report_provider_counteroffer_paths")
    end
  end

  test "provider counteroffer replay treats preserved ID maps as family pressure" do
    base_summary = %{
      "contract" => "provider_counteroffer_report.v1",
      "count" => 1,
      "row_count" => 1,
      "paths" => ["provenance.source_reports.provider_counteroffer_report"],
      "reviewable_count" => 0,
      "counteroffer_cost_delta_count" => 0,
      "counteroffer_cost_delta_total" => 0.0,
      "counteroffer_timing_shift_count" => 0,
      "counteroffer_start_delta_count" => 0,
      "counteroffer_end_delta_count" => 0,
      "counteroffer_duration_delta_count" => 0,
      "counteroffer_lock_deadline_count" => 0,
      "counteroffer_status_counts" => %{},
      "required_operator_action_counts" => %{},
      "plan_impact_summary_count" => 0,
      "plan_impact_status_counts" => %{},
      "affected_station_calendar_entry_ids" => [],
      "affected_provider_entry_ids" => [],
      "impact_counteroffer_ids" => [],
      "timing_shift_counteroffer_ids" => [],
      "cost_delta_counteroffer_ids" => []
    }

    cases = [
      {"cost id", %{"cost_delta_counteroffer_ids" => ["offer_cost"]},
       "branch_local_counteroffer_cost_pressure"},
      {"timing id", %{"timing_shift_counteroffer_ids" => ["offer_timing"]},
       "branch_local_counteroffer_timing_pressure"},
      {"plan status", %{"plan_impact_status_counts" => %{"review_required" => 1}},
       "branch_local_plan_impact_pressure"},
      {"station entry", %{"affected_station_calendar_entry_ids" => ["station_entry_1"]},
       "branch_local_plan_impact_pressure"},
      {"provider entry", %{"affected_provider_entry_ids" => ["provider_entry_1"]},
       "branch_local_plan_impact_pressure"},
      {"impact id", %{"impact_counteroffer_ids" => ["offer_impact"]},
       "branch_local_plan_impact_pressure"}
    ]

    for {label, evidence, expected_pressure} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "provider_counteroffer_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.provider_counteroffer_replay_summary(artifact)

      assert summary["source_report_count"] == 1, label
      assert summary["reviewable_count"] == 0, label
      assert summary["counteroffer_cost_delta_count"] == 0, label
      assert summary["counteroffer_timing_shift_count"] == 0, label
      assert summary["counteroffer_lock_deadline_count"] == 0, label
      assert summary["counteroffer_status_counts"] == %{}, label
      assert summary["required_operator_action_counts"] == %{}, label
      refute summary["branch_local_counteroffer_review_pressure"], label
      refute summary["branch_local_counteroffer_lock_pressure"], label
      assert summary[expected_pressure], label
      assert summary["branch_local_counteroffer_pressure"], label
    end
  end
end
