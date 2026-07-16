defmodule OrbitalDynamics.CandidateRefresh.StationReservationHoldSummaryReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "station reservation replay accepts hold summaries" do
    summary = %{
      "model" => "artifact_only_station_reservation_hold_summary",
      "schema_contract" => "station_reservation_hold_summary.v1",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 2,
      "affected_contact_reservation_hold_count" => 1,
      "provider_calendar_contention_hold_count" => 1,
      "reservation_hold_review_status" => "review_required",
      "reservation_hold_expiration_count" => 1,
      "earliest_reservation_hold_expires_at_s" => 240.0,
      "reservation_hold_expiration_status_counts" => %{"expired" => 1, "missing" => 1},
      "reservation_hold_status_counts" => %{"held" => 2},
      "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
      "reservation_hold_ids_by_expiration_status" => %{
        "expired" => ["reservation_expired"],
        "missing" => ["reservation_missing"]
      },
      "reservation_hold_ids_by_status" => %{
        "held" => ["reservation_expired", "reservation_missing"]
      },
      "reservation_hold_ids_by_reserved_by" => %{
        "ops_calendar" => ["reservation_expired"],
        "partner_calendar" => ["reservation_missing"]
      },
      "reservation_hold_ids_by_row_type" => %{
        "affected_contact" => ["reservation_expired"],
        "provider_calendar_contention_group" => ["reservation_missing"]
      },
      "reservation_hold_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_source_reserved"]
      },
      "review_contact_ids" => ["dl_source_reserved"],
      "review_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "reservation_expires_at_s" => [240.0],
          "station_reservation_expiration_status" => "expired"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "directions" => ["uplink"],
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "station_reservation_expiration_status" => "missing"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "source" => "station_reservation_report.v1",
        "operator_authority" => "not_granted_by_summary",
        "deadline_evaluation" => "evaluated_from_now_s",
        "now_s" => 300.0
      }
    }

    refresh = %{"source_station_reservation_hold_summary" => summary}

    expected_direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_source_reserved"],
        "reservation_hold_ids" => ["reservation_expired"],
        "reservation_hold_contact_ids" => ["dl_source_reserved"]
      },
      "uplink" => %{
        "contact_ids" => [],
        "reservation_hold_ids" => ["reservation_missing"],
        "reservation_hold_contact_ids" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_station_reservation_contract" => "station_reservation_report.v1",
             "source_report_station_reservation_count" => 1,
             "source_report_station_reservation_row_count" => 2,
             "source_report_station_reservation_paths" => [
               "source_station_reservation_hold_summary"
             ],
             "source_report_station_reservation_hold_count" => 2,
             "source_report_station_reservation_affected_contact_hold_count" => 1,
             "source_report_station_reservation_provider_calendar_contention_hold_count" => 1,
             "source_report_station_reservation_hold_review_status_counts" => %{
               "review_required" => 1
             },
             "source_report_station_reservation_hold_expiration_count" => 1,
             "source_report_station_reservation_earliest_hold_expires_at_s" => 240.0,
             "source_report_station_reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "source_report_station_reservation_hold_status_counts" => %{"held" => 2},
             "source_report_station_reservation_source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 1
             },
             "source_report_station_reservation_source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 1
             },
             "source_report_station_reservation_source_artifact_type_counts" => %{
               "station_reservation_report.v1" => 1
             },
             "source_report_station_reservation_hold_ids" => [
               "reservation_expired",
               "reservation_missing"
             ],
             "source_report_station_reservation_hold_ids_by_expiration_status" => %{
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_ids_by_status" => %{
               "held" => ["reservation_expired", "reservation_missing"]
             },
             "source_report_station_reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_ids_by_row_type" => %{
               "affected_contact" => ["reservation_expired"],
               "provider_calendar_contention_group" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_direction_routing" => ^expected_direction_routing,
             "source_report_station_reservation_hold_review_contact_ids" => [
               "dl_source_reserved"
             ],
             "source_reports" => %{
               "station_reservation_report" => %{
                 "paths" => ["source_station_reservation_hold_summary"],
                 "contract" => "station_reservation_report.v1",
                 "count" => 1,
                 "row_count" => 2,
                 "source_summary_model_counts" => %{
                   "artifact_only_station_reservation_hold_summary" => 1
                 },
                 "source_summary_schema_contract_counts" => %{
                   "station_reservation_hold_summary.v1" => 1
                 },
                 "source_artifact_type_counts" => %{
                   "station_reservation_report.v1" => 1
                 },
                 "affected_contact_count" => 1,
                 "provider_calendar_contention_group_count" => 1,
                 "reservation_hold_count" => 2,
                 "affected_contact_reservation_hold_count" => 1,
                 "provider_calendar_contention_hold_count" => 1,
                 "reservation_hold_review_status_counts" => %{"review_required" => 1},
                 "reservation_hold_expiration_count" => 1,
                 "earliest_reservation_hold_expires_at_s" => 240.0,
                 "reservation_hold_expiration_status_counts" => %{
                   "expired" => 1,
                   "missing" => 1
                 },
                 "reservation_hold_status_counts" => %{"held" => 2},
                 "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
                 "reservation_hold_ids_by_expiration_status" => %{
                   "expired" => ["reservation_expired"],
                   "missing" => ["reservation_missing"]
                 },
                 "reservation_hold_ids_by_row_type" => %{
                   "affected_contact" => ["reservation_expired"],
                   "provider_calendar_contention_group" => ["reservation_missing"]
                 },
                 "reservation_hold_ids_by_direction" => %{
                   "downlink" => ["reservation_expired"],
                   "uplink" => ["reservation_missing"]
                 },
                 "reservation_hold_contact_ids_by_expiration_status" => %{
                   "expired" => ["dl_source_reserved"]
                 },
                 "reservation_hold_contact_ids_by_direction" => %{
                   "downlink" => ["dl_source_reserved"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "reservation_hold_review_contact_ids" => ["dl_source_reserved"]
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.station_reservation_replay_summary(refresh)

    assert %{
             "source_report_paths" => ["source_station_reservation_hold_summary"],
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "reservation_hold_count" => 2,
             "affected_contact_reservation_hold_count" => 1,
             "provider_calendar_contention_hold_count" => 1,
             "reservation_hold_review_status_counts" => %{"review_required" => 1},
             "reservation_hold_expiration_count" => 1,
             "earliest_reservation_hold_expires_at_s" => 240.0,
             "reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "reservation_hold_status_counts" => %{"held" => 2},
             "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "reservation_hold_ids_by_expiration_status" => %{
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_status" => %{
               "held" => ["reservation_expired", "reservation_missing"]
             },
             "reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_row_type" => %{
               "affected_contact" => ["reservation_expired"],
               "provider_calendar_contention_group" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "reservation_hold_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_source_reserved"]
             },
             "reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "direction_routing" => ^expected_direction_routing,
             "reservation_hold_review_contact_ids" => ["dl_source_reserved"],
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_hold_pressure" => true,
             "branch_local_reservation_hold_import_readiness_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.station_reservation_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_station_reservation_replay_summary(artifact) ==
             replay_summary
  end

  test "station reservation replay accepts wrapped hold summaries" do
    summary = %{
      "model" => "artifact_only_station_reservation_hold_summary",
      "schema_contract" => "station_reservation_hold_summary.v1",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 1,
      "affected_contact_reservation_hold_count" => 1,
      "provider_calendar_contention_hold_count" => 0,
      "reservation_hold_review_status" => "review_required",
      "reservation_hold_expiration_count" => 1,
      "earliest_reservation_hold_expires_at_s" => 240.0,
      "reservation_hold_expiration_status_counts" => %{"expired" => 1},
      "reservation_hold_status_counts" => %{"held" => 1},
      "reservation_hold_ids" => ["reservation_expired"],
      "reservation_hold_ids_by_expiration_status" => %{
        "expired" => ["reservation_expired"]
      },
      "reservation_hold_ids_by_status" => %{"held" => ["reservation_expired"]},
      "reservation_hold_ids_by_reserved_by" => %{"ops_calendar" => ["reservation_expired"]},
      "reservation_hold_ids_by_row_type" => %{
        "affected_contact" => ["reservation_expired"]
      },
      "reservation_hold_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_source_reserved"]
      },
      "review_contact_ids" => ["dl_source_reserved"],
      "review_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "reservation_expires_at_s" => [240.0],
          "station_reservation_expiration_status" => "expired"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "source" => "station_reservation_report.v1",
        "operator_authority" => "not_granted_by_summary"
      }
    }

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "ground_partner_api"},
      "source_station_reservation_hold_summary" => summary
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", [wrapper]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => [
               "source_result_artifact[0].source_station_reservation_hold_summary"
             ],
             "contract" => "station_reservation_report.v1",
             "count" => 1,
             "row_count" => 1,
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "reservation_hold_count" => 1,
             "reservation_hold_review_status_counts" => %{"review_required" => 1},
             "reservation_hold_expiration_count" => 1,
             "reservation_hold_expiration_status_counts" => %{"expired" => 1},
             "reservation_hold_ids_by_expiration_status" => %{
               "expired" => ["reservation_expired"]
             },
             "reservation_hold_review_contact_ids" => ["dl_source_reserved"]
           } =
             get_in(artifact, ["provenance", "source_reports", "station_reservation_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_station_reservation_hold_summary"
             ],
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 1
             },
             "reservation_hold_count" => 1,
             "reservation_hold_review_status_counts" => %{"review_required" => 1},
             "reservation_hold_expiration_count" => 1,
             "reservation_hold_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_source_reserved"]
             },
             "branch_local_reservation_hold_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end
end
