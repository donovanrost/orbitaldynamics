Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationReservationAllocationChallengeTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh

  alias OrbitalDynamics.CampaignPlanner.{
    CandidateSourceContactAllocationReplayRisk,
    StrategyPressureRisk
  }

  alias OrbitalDynamics.Schema

  test "candidate-source provider expiration requires exact contact routing" do
    replay_summary = %{
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["active_review", "expired_review", "unrouted_review"]
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => [
          "active_request",
          "expired_request",
          "missing_request",
          "unrouted_request"
        ]
      },
      "station_reservation_contact_ids_by_expiration_status" => %{
        "active" => ["active_request", "active_review"],
        "expired" => ["expired_request", "expired_review"],
        "missing" => ["missing_request", "unrelated_contact"]
      },
      "station_reservation_expiration_status_counts" => %{"missing" => 99}
    }

    risks = CandidateSourceContactAllocationReplayRisk.provider_reservation(replay_summary)

    assert Enum.find(risks, &(&1["contact_id"] == "active_review"))[
             "station_reservation_expiration_status"
           ] == "active"

    assert Enum.find(risks, &(&1["contact_id"] == "expired_review"))[
             "station_reservation_expiration_status"
           ] == "expired"

    assert %{
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_row_scope" => "request",
             "station_reservation_expiration_status" => "expired",
             "required_operator_action" => "review_provider_reservation_request"
           } = Enum.find(risks, &(&1["contact_id"] == "expired_request"))

    assert Enum.find(risks, &(&1["contact_id"] == "missing_request"))[
             "station_reservation_expiration_status"
           ] == "missing"

    refute Enum.any?(risks, &(&1["contact_id"] == "active_request"))
    refute Enum.any?(risks, &(&1["contact_id"] == "unrouted_request"))

    refute Map.has_key?(
             Enum.find(risks, &(&1["contact_id"] == "unrouted_review")),
             "station_reservation_expiration_status"
           )

    assert StrategyPressureRisk.station_reservation_expiration_pressure_risk_count(risks) == 3
  end

  test "strategy-derived refresh preserves contradictory station reservation allocation evidence" do
    challenge_contact = "challenge_dl_reserved_intruder"

    station_calendar_report = %{
      "schema_contract" => "station_calendar_report.v1",
      "model" => "artifact_only_station_calendar_report",
      "source" => "campaign_planner_test.contradictory_station_calendar",
      "affected_contacts" => [
        %{
          "contact_id" => challenge_contact,
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_calendar_entry_id" => "challenge_station_reserved",
          "station_calendar_provider_id" => "partner_calendar",
          "station_calendar_provider_entry_id" => "partner_reserved_entry",
          "station_calendar_status" => "reserved",
          "availability" => "reserved",
          "station_availability" => "reserved",
          "station_reserved_by" => "partner_ops",
          "station_reservation_id" => "challenge_reservation_1",
          "station_reservation_status" => "confirmed",
          "station_reservation_match_status" => "overlap",
          "station_calendar_reservation_ids" => ["challenge_reservation_1"],
          "station_calendar_reservation_statuses" => ["confirmed"],
          "station_calendar_reservation_overlap_count" => 1,
          "required_operator_action" => "review_station_reservation_overlap",
          "trust_boundary" => "challenge_station_calendar_row"
        }
      ],
      "provider_calendar_contention_groups" => [
        %{
          "provider_calendar_contention_group_id" => "challenge_provider_contention",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "provider_calendar_contention_status" => "review_required",
          "provider_calendar_contention_provider_ids" => ["ops_calendar", "partner_calendar"],
          "provider_calendar_contention_provider_entry_ids" => [
            "ops_selected_entry",
            "partner_reserved_entry"
          ],
          "provider_calendar_contention_availabilities" => ["available", "reserved"],
          "provider_calendar_contention_reservation_ids" => ["challenge_reservation_1"],
          "provider_calendar_contention_reserved_by" => ["partner_ops"],
          "provider_calendar_contention_reservation_statuses" => ["confirmed"],
          "required_operator_action" => "review_station_provider_contention",
          "trust_boundary" => "challenge_provider_contention_row"
        }
      ],
      "provenance" => %{"trust_boundary" => "challenge_station_calendar_report"}
    }

    station_reservation_report = %{
      "schema_contract" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "affected_contacts" => [
        %{
          "contact_id" => challenge_contact,
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_reservation_match_status" => "overlap",
          "station_reservation_id" => "challenge_reservation_1",
          "station_reservation_status" => "confirmed",
          "station_reserved_by" => "partner_ops",
          "station_reservation_expires_at_s" => 300.0,
          "required_operator_action" => "review_station_reservation_overlap",
          "trust_boundary" => "challenge_station_reservation_row"
        }
      ],
      "provider_calendar_contention_groups" => [],
      "provenance" => %{"trust_boundary" => "challenge_station_reservation_report"}
    }

    reservation_hold_summary = %{
      "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
      "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 2,
      "import_readiness_status" => "review_required",
      "import_classification" => "review_only",
      "ready_for_import_count" => 0,
      "review_required_before_import_count" => 2,
      "no_import_required_count" => 0,
      "reservation_hold_import_status_counts" => %{
        "review_required_before_import" => 2
      },
      "required_import_action_counts" => %{
        "review_station_provider_contention" => 1,
        "review_station_reservation_overlap" => 1
      },
      "reservation_hold_ids" => ["challenge_reservation_1", "challenge_provider_hold"],
      "reservation_hold_ids_by_import_status" => %{
        "review_required_before_import" => [
          "challenge_provider_hold",
          "challenge_reservation_1"
        ]
      },
      "reservation_hold_ids_by_required_import_action" => %{
        "review_station_provider_contention" => ["challenge_provider_hold"],
        "review_station_reservation_overlap" => ["challenge_reservation_1"]
      },
      "reservation_hold_contact_ids_by_import_status" => %{
        "review_required_before_import" => [challenge_contact]
      },
      "import_readiness_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => challenge_contact,
          "reservation_ids" => ["challenge_reservation_1"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_ops"],
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_reservation_overlap"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "reservation_ids" => ["challenge_provider_hold"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_provider_contention"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "reservation_acceptance" => "not_performed_by_summary"
      },
      "provenance" => %{
        "trust_boundary" => "challenge_station_reservation_hold_import_readiness"
      }
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_station_calendar_report, station_calendar_report)
      |> Map.put(:source_station_reservation_report, station_reservation_report)
      |> Map.put(
        :source_station_reservation_hold_import_readiness_summary,
        reservation_hold_summary
      )
      |> Map.put(
        :source_contact_allocation_summary,
        contact_allocation_summary_fixture("challenge")
      )
      |> Map.put(
        :source_contact_allocation_station_pressure_summary,
        contact_allocation_station_pressure_summary_fixture("challenge")
      )
      |> Map.put(
        :source_contact_allocation_reservation_conflict_summary,
        contact_allocation_reservation_conflict_summary_fixture("challenge")
      )
      |> Map.put(
        :source_contact_allocation_provider_reservation_request_summary,
        contact_allocation_provider_reservation_request_summary_fixture("challenge")
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "challenge",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    challenge_branch = branch(artifact, "challenge")
    candidate_source = challenge_branch["assumptions"]["candidate_source"]

    source_report_input_paths =
      get_in(challenge_branch, ["assumptions", "candidate_source", "source_report_input_paths"])

    for source_path <- [
          "mission_state.source_contact_allocation_summary",
          "mission_state.source_contact_allocation_station_pressure_summary",
          "mission_state.source_contact_allocation_reservation_conflict_summary",
          "mission_state.source_contact_allocation_provider_reservation_request_summary",
          "mission_state.source_station_calendar_report",
          "mission_state.source_station_reservation_report",
          "mission_state.source_station_reservation_hold_import_readiness_summary"
        ] do
      assert source_path in source_report_input_paths
    end

    contact_allocation_replay_summary =
      CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    assert %{
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_deferred_allocation_pressure" => true,
             "branch_local_station_pressure" => true,
             "branch_local_reservation_conflict_pressure" => true,
             "branch_local_provider_reservation_request_pressure" => true,
             "allocated_contact_ids" => allocated_contact_ids,
             "deferred_contact_ids" => deferred_contact_ids,
             "reservation_conflict_contact_ids" => reservation_conflict_contact_ids,
             "station_reservation_contact_ids_by_expiration_status" => %{
               "expired" => expired_reservation_contact_ids
             },
             "provider_reservation_review_contact_ids" => provider_reservation_review_contact_ids,
             "source_report_paths" => contact_allocation_source_paths
           } = contact_allocation_replay_summary

    assert "challenge_dl_allocated" in allocated_contact_ids
    assert "challenge_dl_deferred" in deferred_contact_ids
    assert challenge_contact in reservation_conflict_contact_ids
    assert challenge_contact in expired_reservation_contact_ids
    assert "challenge_dl_reserved_intruder" in provider_reservation_review_contact_ids

    for source_path <- [
          "mission_state.source_contact_allocation_summary",
          "mission_state.source_contact_allocation_station_pressure_summary",
          "mission_state.source_contact_allocation_reservation_conflict_summary",
          "mission_state.source_contact_allocation_provider_reservation_request_summary"
        ] do
      assert source_path in contact_allocation_source_paths
    end

    station_calendar_replay_summary =
      CandidateRefresh.station_calendar_replay_summary(candidate_source)

    assert %{
             "branch_local_station_calendar_pressure" => true,
             "branch_local_affected_contact_pressure" => true,
             "branch_local_provider_contention_pressure" => true,
             "station_calendar_status_counts" => %{"reserved" => 1},
             "affected_contact_availability_counts" => %{"reserved" => 1},
             "provider_calendar_contention_group_count" => 1,
             "affected_contact_ids" => [^challenge_contact],
             "affected_station_reservation_ids" => ["challenge_reservation_1"],
             "source_report_paths" => station_calendar_source_paths
           } = station_calendar_replay_summary

    assert "mission_state.source_station_calendar_report" in station_calendar_source_paths

    station_reservation_replay_summary =
      CandidateRefresh.station_reservation_replay_summary(candidate_source)

    assert %{
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_review_pressure" => true,
             "branch_local_reservation_hold_import_readiness_pressure" => true,
             "station_reservation_match_status_counts" => %{"overlap" => 1},
             "reservation_ids" => reservation_ids,
             "reservation_hold_import_readiness_status_counts" => %{
               "review_required" => 1
             },
             "reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "source_report_paths" => station_reservation_source_paths
           } = station_reservation_replay_summary

    assert "challenge_reservation_1" in reservation_ids
    assert "challenge_provider_hold" in reservation_ids

    assert challenge_contact in station_reservation_replay_summary["affected_contact_ids"]

    assert challenge_contact in get_in(
             station_reservation_replay_summary,
             ["reservation_hold_contact_ids_by_import_status", "review_required_before_import"]
           )

    assert "mission_state.source_station_reservation_report" in station_reservation_source_paths

    assert "mission_state.source_station_reservation_hold_import_readiness_summary" in station_reservation_source_paths

    assert_station_reservation_conflict_pressure_score_terms(challenge_branch, artifact)
    assert_provider_reservation_request_pressure_score_terms(challenge_branch, artifact)

    assert Enum.any?(
             challenge_branch["risk_indicators"],
             &(&1["feedback_scope"] == "contact_allocation" and
                 &1["contact_id"] == challenge_contact and
                 &1["station_reservation_expiration_status"] == "expired")
           )

    assert Enum.any?(
             challenge_branch["risk_indicators"],
             &(&1["type"] == "provider_reservation_request_review" and
                 &1["contact_id"] == "challenge_dl_reserved_intruder" and
                 &1["station_reservation_expiration_status"] == "expired")
           )

    assert Enum.any?(
             challenge_branch["risk_indicators"],
             &(&1["type"] == "provider_reservation_request_review" and
                 &1["contact_id"] == "challenge_dl_reserved_owner" and
                 &1["provider_reservation_request_status"] == "request_ready" and
                 &1["provider_reservation_row_scope"] == "request" and
                 &1["station_reservation_match_status"] == "matched" and
                 &1["station_reservation_expiration_status"] == "expired")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    station_reservation_expiration_pressure_count =
      Enum.count(
        challenge_branch["risk_indicators"],
        &(&1["station_reservation_expiration_status"] in ["expired", "missing"])
      )

    assert station_reservation_expiration_pressure_count > 0

    assert challenge_branch["score_terms"]["station_reservation_expiration_pressure_penalty"] ==
             -station_reservation_expiration_pressure_count * risk_weight

    challenge_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "challenge"))

    assert "downlink_completion_gap" in challenge_row["risk_types"]
    assert "provider_reservation_request_review" in challenge_row["risk_types"]

    assert challenge_row["branch_station_reservation_conflict_contact_ids"] == [
             challenge_contact,
             "challenge_dl_reserved_owner"
           ]

    assert challenge_row["branch_station_reservation_conflict_reservation_ids"] == [
             "challenge_reservation_1"
           ]

    assert "expired" in challenge_row["branch_station_reservation_expiration_statuses"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp contact_allocation_summary_fixture(prefix) do
    allocated_row = %{
      "contact_id" => "#{prefix}_dl_allocated",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    deferred_row = %{
      "contact_id" => "#{prefix}_dl_deferred",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    %{
      "schema_contract" => "contact_allocation_summary.v1",
      "model" => "artifact_only_contact_allocation_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "campaign_planner_test.#{prefix}.contact_allocation_summary",
      "input_contact_count" => 2,
      "allocated_contact_count" => 1,
      "returned_allocated_contact_count" => 1,
      "policy_blocked_allocated_contact_count" => 0,
      "deferred_contact_count" => 1,
      "blocked_contact_count" => 0,
      "invalid_contact_input_count" => 0,
      "status_blocked_contact_count" => 0,
      "resource_blocked_contact_count" => 0,
      "duplicate_contact_id_count" => 0,
      "allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "effective_allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "allocation_reason_counts" => %{
        "same_station_contention" => 1,
        "selected_by_contention_resolution" => 1
      },
      "contact_ids_by_allocation_reason" => %{
        "same_station_contention" => ["#{prefix}_dl_deferred"],
        "selected_by_contention_resolution" => ["#{prefix}_dl_allocated"]
      },
      "allocated_contact_ids" => ["#{prefix}_dl_allocated"],
      "returned_allocated_contact_ids" => ["#{prefix}_dl_allocated"],
      "deferred_contact_ids" => ["#{prefix}_dl_deferred"],
      "blocked_contact_ids" => [],
      "review_contact_ids" => ["#{prefix}_dl_deferred"],
      "rows" => [allocated_row, deferred_row],
      "review_rows" => [deferred_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_contact_allocation_summary_fixture"}
    }
  end

  defp contact_allocation_station_pressure_summary_fixture(prefix) do
    nominal_row = %{
      "contact_id" => "#{prefix}_dl_nominal",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    station_pressure_row = %{
      "contact_id" => "#{prefix}_dl_station_pressure",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_calendar_entry_id" => "#{prefix}_station_reserved_1",
      "station_calendar_overlap_availabilities" => ["reserved"],
      "station_calendar_precedence_availability" => "reserved",
      "station_calendar_precedence_rank" => 2
    }

    %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "campaign_planner_test.#{prefix}.contact_allocation_station_pressure_summary",
      "input_contact_count" => 2,
      "station_pressure_contact_count" => 1,
      "station_pressure_review_contact_count" => 1,
      "station_pressure_contact_ids" => ["#{prefix}_dl_station_pressure"],
      "station_pressure_review_contact_ids" => ["#{prefix}_dl_station_pressure"],
      "station_pressure_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_ground_station_id" => %{"equator_prime" => 1},
      "station_pressure_contact_ids_by_availability" => %{
        "reserved" => ["#{prefix}_dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_availability" => %{
        "reserved" => ["#{prefix}_dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_rank" => %{
        "2" => ["#{prefix}_dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_precedence_rank" => %{"2" => 1},
      "rows" => [nominal_row, station_pressure_row],
      "review_rows" => [station_pressure_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_station_pressure_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_station_pressure_fixture"}
    }
  end

  defp contact_allocation_reservation_conflict_summary_fixture(prefix) do
    owner_row = %{
      "contact_id" => "#{prefix}_dl_reserved_owner",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_1",
      "station_reservation_match_status" => "matched",
      "station_reservation_status" => "confirmed",
      "station_reserved_by" => "ops_team_b",
      "station_reservation_expires_at_s" => 360.0
    }

    conflict_row = %{
      "contact_id" => "#{prefix}_dl_reserved_intruder",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_1",
      "station_reservation_match_status" => "overlap",
      "station_reservation_status" => "confirmed",
      "station_reserved_by" => "ops_team_b",
      "station_reservation_expires_at_s" => 360.0
    }

    %{
      "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
      "model" => "artifact_only_contact_allocation_reservation_conflict_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" =>
        "campaign_planner_test.#{prefix}.contact_allocation_reservation_conflict_summary",
      "input_contact_count" => 2,
      "station_reservation_contact_count" => 2,
      "reservation_conflict_contact_count" => 1,
      "reservation_review_contact_count" => 1,
      "station_reservation_match_status_counts" => %{"matched" => 1, "overlap" => 1},
      "reservation_conflict_match_status_counts" => %{"overlap" => 1},
      "station_reservation_status_counts" => %{"confirmed" => 2},
      "station_reserved_by_counts" => %{"ops_team_b" => 2},
      "station_reservation_ids" => ["#{prefix}_reservation_1"],
      "station_reservation_expires_at_s" => [360.0],
      "station_reservation_expiration_now_s" => 400.0,
      "station_reservation_expiration_status_counts" => %{"expired" => 2},
      "earliest_station_reservation_expires_at_s" => 360.0,
      "reservation_conflict_contact_ids" => ["#{prefix}_dl_reserved_intruder"],
      "reservation_review_contact_ids" => ["#{prefix}_dl_reserved_intruder"],
      "station_reservation_contact_ids_by_match_status" => %{
        "matched" => ["#{prefix}_dl_reserved_owner"],
        "overlap" => ["#{prefix}_dl_reserved_intruder"]
      },
      "reservation_conflict_contact_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_dl_reserved_intruder"]
      },
      "station_reservation_contact_ids_by_status" => %{
        "confirmed" => [
          "#{prefix}_dl_reserved_intruder",
          "#{prefix}_dl_reserved_owner"
        ]
      },
      "station_reservation_contact_ids_by_reserved_by" => %{
        "ops_team_b" => [
          "#{prefix}_dl_reserved_intruder",
          "#{prefix}_dl_reserved_owner"
        ]
      },
      "station_reservation_contact_ids_by_expiration_status" => %{
        "expired" => [
          "#{prefix}_dl_reserved_intruder",
          "#{prefix}_dl_reserved_owner"
        ]
      },
      "station_reservation_ids_by_match_status" => %{
        "matched" => ["#{prefix}_reservation_1"],
        "overlap" => ["#{prefix}_reservation_1"]
      },
      "reservation_conflict_reservation_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_reservation_1"]
      },
      "station_reservation_ids_by_status" => %{"confirmed" => ["#{prefix}_reservation_1"]},
      "station_reservation_ids_by_reserved_by" => %{"ops_team_b" => ["#{prefix}_reservation_1"]},
      "station_reservation_ids_by_expiration_status" => %{
        "expired" => ["#{prefix}_reservation_1"]
      },
      "rows" => [owner_row, conflict_row],
      "reservation_conflict_rows" => [conflict_row],
      "reservation_review_rows" => [conflict_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_reservation_conflict_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_reservation_conflict_fixture"}
    }
  end

  defp contact_allocation_provider_reservation_request_summary_fixture(prefix) do
    request_row = %{
      "contact_id" => "#{prefix}_dl_reserved_owner",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_1",
      "station_reservation_match_status" => "matched",
      "station_reservation_status" => "confirmed"
    }

    review_row = %{
      "contact_id" => "#{prefix}_dl_reserved_intruder",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_review",
      "station_reservation_match_status" => "overlap",
      "station_reservation_status" => "confirmed"
    }

    %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" =>
        "campaign_planner_test.#{prefix}.contact_allocation_provider_reservation_request_summary",
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["#{prefix}_dl_reserved_owner"],
      "provider_reservation_review_contact_ids" => ["#{prefix}_dl_reserved_intruder"],
      "provider_reservation_no_request_contact_ids" => ["#{prefix}_dl_unreserved"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_reserved_intruder"]
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["#{prefix}_dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_dl_reserved_intruder"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["#{prefix}_reservation_1"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_reservation_review"]
      },
      "provider_reservation_request_rows" => [request_row],
      "provider_reservation_review_rows" => [review_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_provider_reservation_request_fixture"}
    }
  end

  defp assert_station_reservation_conflict_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    contact_allocation_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &contact_allocation_non_conflict_pressure?/1
      )

    station_reservation_conflict_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &station_reservation_conflict_pressure?/1
      )

    assert station_reservation_conflict_pressure_count > 0

    assert branch["score_terms"]["contact_allocation_pressure_penalty"] ==
             -contact_allocation_pressure_count * risk_weight

    assert branch["score_terms"]["station_reservation_conflict_pressure_penalty"] ==
             -station_reservation_conflict_pressure_count * risk_weight

    assert "station_reservation_conflict_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "station_reservation_conflict_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp assert_provider_reservation_request_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    provider_reservation_request_pressure_count =
      Enum.count(branch["risk_indicators"], &provider_reservation_request_pressure?/1)

    assert provider_reservation_request_pressure_count > 0

    assert branch["score_terms"]["provider_reservation_request_pressure_penalty"] ==
             -provider_reservation_request_pressure_count * risk_weight

    assert "provider_reservation_request_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "provider_reservation_request_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp station_reservation_conflict_pressure?(risk) do
    risk["type"] == "downlink_completion_gap" and
      risk["feedback_scope"] == "contact_allocation" and
      (risk["station_reservation_match_status"] in ["overlap"] or
         "contact_allocation_reservation_conflict" in List.wrap(risk["derivation_reasons"]))
  end

  defp provider_reservation_request_pressure?(risk) do
    risk["type"] == "provider_reservation_request_review"
  end

  defp contact_allocation_non_conflict_pressure?(risk) do
    not station_reservation_conflict_pressure?(risk) and
      risk["type"] == "downlink_completion_gap" and
      (risk["feedback_scope"] in [
         "contact_allocation",
         "contact_allocation_provider_reservation_request"
       ] or
         Enum.any?(List.wrap(risk["derivation_reasons"]), fn reason ->
           reason
           |> to_string()
           |> String.starts_with?("contact_allocation")
         end))
  end
end
