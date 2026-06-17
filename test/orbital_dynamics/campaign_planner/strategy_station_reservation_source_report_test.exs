Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationReservationSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state station-reservation reports into branch refresh requests" do
    station_reservation_report =
      fn prefix, ground_station_id, direction, match_status, reservation_status, reserved_by ->
        %{
          "schema_contract" => "station_reservation_report.v1",
          "source" => "campaign_planner_test.#{prefix}.station_reservation_report",
          "affected_contacts" => [
            %{
              "contact_id" => "#{prefix}_contact",
              "direction" => direction,
              "ground_station_id" => ground_station_id,
              "station_reservation_match_status" => match_status,
              "station_reservation_id" => "#{prefix}_reservation",
              "station_reservation_status" => reservation_status,
              "station_reservation_expires_at_s" =>
                if(prefix == "direct", do: 240.0, else: 480.0),
              "reserved_by" => reserved_by,
              "required_operator_action" => "review_station_reservation_overlap",
              "trust_boundary" => "#{prefix}_station_reservation_row_boundary"
            }
          ],
          "provider_calendar_contention_groups" => [
            %{
              "id" => "#{prefix}_provider_contention",
              "provider_calendar_contention_status" => "provider_calendar_overlap",
              "provider_ids" => ["#{prefix}_provider"],
              "provider_entry_ids" => ["#{prefix}_provider_entry"],
              "ground_station_id" => ground_station_id,
              "directions" => [direction],
              "source_station_calendar_entries" => [
                %{
                  "id" => "#{prefix}_source_entry",
                  "ground_station_id" => ground_station_id
                }
              ],
              "reservation_ids" => ["#{prefix}_reservation"],
              "reservation_statuses" => [reservation_status],
              "reserved_by" => [reserved_by],
              "required_operator_action" => "review_station_provider_contention",
              "trust_boundary" => "#{prefix}_provider_contention_boundary"
            }
          ],
          "provenance" => %{
            "trust_boundary" => "#{prefix}_station_reservation_report_boundary"
          }
        }
      end

    direct_report =
      station_reservation_report.(
        "direct",
        "equator_prime",
        "Down Link",
        "overlap",
        "confirmed",
        "partner_ops"
      )

    canonical_direct_report =
      station_reservation_report.(
        "canonical_direct",
        "canberra_deep",
        "Down Link",
        "matched",
        "confirmed",
        "partner_ops"
      )

    source_wrapped_report =
      station_reservation_report.(
        "source_wrapped",
        "dss_43",
        "s-band command",
        "matched",
        "hold",
        "ops"
      )

    result_wrapped_report =
      station_reservation_report.(
        "result_wrapped",
        "polar_prime",
        "Down Link",
        "overlap",
        "planned",
        "partner_ops"
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_station_reservation_report", direct_report)
      |> Map.put("station_reservation_report", canonical_direct_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "station_reservation_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_station_reservation_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_station_reservation_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_station_reservation_boundary"}
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

    for source_path <- [
          "mission_state.station_reservation_report",
          "mission_state.source_station_reservation_report",
          "mission_state.source_result_artifact.station_reservation_report",
          "mission_state.result_artifact.source_station_reservation_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_station_reservation_affected_contact_count" => 4,
             "source_report_station_reservation_provider_calendar_contention_group_count" => 4,
             "source_report_station_reservation_reservation_review_count" => 8,
             "source_report_station_reservation_direction_counts" => %{
               "command" => 1,
               "downlink" => 3
             },
             "source_report_station_reservation_match_status_counts" => %{
               "matched" => 2,
               "overlap" => 2
             },
             "source_report_station_reservation_status_counts" => %{
               "confirmed" => 4,
               "hold" => 2,
               "planned" => 2
             },
             "source_report_station_reservation_provider_calendar_contention_provider_counts" =>
               %{
                 "canonical_direct_provider" => 1,
                 "direct_provider" => 1,
                 "result_wrapped_provider" => 1,
                 "source_wrapped_provider" => 1
               }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "station_reservation_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "affected_contact_count" => 4,
             "provider_calendar_contention_group_count" => 4,
             "reservation_review_count" => 8,
             "station_reservation_evidence_row_count" => 8,
             "station_reservation_expiration_evidence_row_count" => 4,
             "direction_counts" => %{"command" => 1, "downlink" => 3},
             "contact_ids_by_direction" => %{
               "command" => ["source_wrapped_contact"],
               "downlink" => [
                 "direct_contact",
                 "canonical_direct_contact",
                 "result_wrapped_contact"
               ]
             },
             "station_reservation_match_status_counts" => %{
               "matched" => 2,
               "overlap" => 2
             },
             "reservation_status_counts" => %{
               "confirmed" => 4,
               "hold" => 2,
               "planned" => 2
             },
             "reservation_ids" => [
               "canonical_direct_reservation",
               "direct_reservation",
               "result_wrapped_reservation",
               "source_wrapped_reservation"
             ],
             "reserved_by_counts" => %{"ops" => 2, "partner_ops" => 6},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_review_pressure" => true,
             "branch_local_reservation_expiration_pressure" => true,
             "branch_local_reservation_owner_pressure" => true,
             "branch_local_provider_contention_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "station_calendar_mutation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.station_reservation_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.result_artifact.source_station_reservation_report",
             "mission_state.source_result_artifact.station_reservation_report",
             "mission_state.source_station_reservation_report",
             "mission_state.station_reservation_report"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_direct_provider_contention_boundary",
             "canonical_direct_station_reservation_report_boundary",
             "canonical_direct_station_reservation_row_boundary",
             "direct_provider_contention_boundary",
             "direct_station_reservation_report_boundary",
             "direct_station_reservation_row_boundary",
             "result_wrapped_provider_contention_boundary",
             "result_wrapped_station_reservation_boundary",
             "result_wrapped_station_reservation_row_boundary",
             "source_wrapped_provider_contention_boundary",
             "source_wrapped_station_reservation_boundary",
             "source_wrapped_station_reservation_row_boundary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
