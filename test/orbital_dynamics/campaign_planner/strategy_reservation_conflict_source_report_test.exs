Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyReservationConflictSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh

  test "strategy carries mission-state reservation-conflict summaries into branch refresh requests" do
    direct_summary = contact_allocation_reservation_conflict_summary_fixture("direct")
    canonical_summary = contact_allocation_reservation_conflict_summary_fixture("canonical")
    wrapped_summary = contact_allocation_reservation_conflict_summary_fixture("wrapped")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_allocation_reservation_conflict_summary", direct_summary)
      |> Map.put("contact_allocation_reservation_conflict_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_allocation_reservation_conflict_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_reservation_conflict_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    assert "mission_state.source_contact_allocation_reservation_conflict_summary" in source_report_input_paths

    assert "mission_state.contact_allocation_reservation_conflict_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.source_contact_allocation_reservation_conflict_summary" in source_report_input_paths

    assert "mission_state.source_contact_allocation_reservation_conflict_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.contact_allocation_reservation_conflict_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.source_contact_allocation_reservation_conflict_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    request_source_report_summary =
      candidate_source["candidate_refresh_request_source_report_summary"]

    assert Map.take(request_source_report_summary, [
             "source_report_count",
             "source_report_row_count",
             "source_report_contact_allocation_reservation_conflict_contact_count",
             "source_report_contact_allocation_reservation_conflict_match_status_counts",
             "source_report_contact_allocation_station_reservation_match_status_counts"
           ]) == %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_contact_allocation_reservation_conflict_contact_count" => 3,
             "source_report_contact_allocation_reservation_conflict_match_status_counts" => %{
               "overlap" => 4
             },
             "source_report_contact_allocation_station_reservation_match_status_counts" => %{
               "matched" => 4,
               "overlap" => 4
             }
           }

    reservation_conflict_replay_summary =
      CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    replay_source_paths = reservation_conflict_replay_summary["source_report_paths"]

    assert Map.take(reservation_conflict_replay_summary, [
             "source_report_count",
             "source_report_row_count",
             "source_report_paths",
             "reservation_conflict_contact_count",
             "reservation_conflict_contact_ids",
             "reservation_conflict_match_status_counts",
             "station_reservation_match_status_counts",
             "station_reservation_expiration_status_counts",
             "reservation_conflict_summary_schema_contract",
             "branch_local_contact_allocation_pressure",
             "branch_local_reservation_conflict_pressure"
           ]) == %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "reservation_conflict_contact_count" => 3,
             "reservation_conflict_contact_ids" => [
               "canonical_dl_reserved_intruder",
               "direct_dl_reserved_intruder",
               "wrapped_dl_reserved_intruder"
             ],
             "reservation_conflict_match_status_counts" => %{"overlap" => 4},
             "station_reservation_match_status_counts" => %{
               "matched" => 4,
               "overlap" => 4
             },
             "station_reservation_expiration_status_counts" => %{"expired" => 8},
             "reservation_conflict_summary_schema_contract" =>
               "contact_allocation_reservation_conflict_summary.v1",
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_reservation_conflict_pressure" => true
           }

    assert %{
             "contact_allocation" => "not_performed_by_summary",
             "candidate_selection" => "not_performed_by_summary"
           } = reservation_conflict_replay_summary["assumptions"]

    for source_path <- [
          "mission_state.source_contact_allocation_reservation_conflict_summary[0]",
          "mission_state.source_contact_allocation_reservation_conflict_summary[1]",
          "mission_state.contact_allocation_reservation_conflict_summary",
          "mission_state.source_result_artifact.source_contact_allocation_reservation_conflict_summary"
        ] do
      assert source_path in replay_source_paths
    end
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
end
