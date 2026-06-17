Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationCalendarSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state station-calendar reports into branch refresh requests" do
    station_calendar_report = fn prefix, ground_station_id, availability, direction ->
      %{
        "schema_contract" => "station_calendar_report.v1",
        "source" => "campaign_planner_test.#{prefix}.station_calendar_report",
        "affected_contacts" => [
          %{
            "id" => "#{prefix}_affected_contact",
            "contact_id" => "#{prefix}_contact",
            "ground_station_id" => ground_station_id,
            "direction" => direction,
            "station_calendar_entry_id" => "#{prefix}_station_entry",
            "station_calendar_status" => availability,
            "station_availability" => availability,
            "station_reservation_id" => "#{prefix}_reservation",
            "capacity_fraction" => 0.5,
            "trust_boundary" => "#{prefix}_station_calendar_row_boundary"
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "#{prefix}_contention_group",
            "provider_ids" => ["#{prefix}_provider"],
            "provider_entry_ids" => ["#{prefix}_provider_entry"],
            "ground_station_id" => ground_station_id,
            "capacity_fraction" => 0.5,
            "directions" => [direction],
            "trust_boundary" => "#{prefix}_provider_contention_boundary",
            "source_station_calendar_entries" => [
              %{
                "id" => "#{prefix}_station_entry",
                "provider_id" => "#{prefix}_provider",
                "provider_entry_id" => "#{prefix}_provider_entry",
                "ground_station_id" => ground_station_id,
                "availability" => availability,
                "directions" => [direction],
                "reservation_id" => "#{prefix}_reservation"
              }
            ]
          }
        ],
        "provenance" => %{
          "trust_boundary" => "#{prefix}_station_calendar_report_boundary"
        }
      }
    end

    direct_report =
      station_calendar_report.("direct", "equator_prime", "reserved", "downlink")

    canonical_direct_report =
      station_calendar_report.("canonical_direct", "canberra_deep", "reserved", "downlink")

    source_wrapped_report =
      station_calendar_report.("source_wrapped", "dss_43", "unavailable", "downlink")

    result_wrapped_report =
      station_calendar_report.(
        "result_wrapped",
        "polar_prime",
        "reduced_capacity",
        "downlink"
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_station_calendar_report", direct_report)
      |> Map.put("station_calendar_report", canonical_direct_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "station_calendar_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_station_calendar_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_station_calendar_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_station_calendar_boundary"}
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
          "mission_state.station_calendar_report",
          "mission_state.source_station_calendar_report",
          "mission_state.source_result_artifact.station_calendar_report",
          "mission_state.result_artifact.source_station_calendar_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_station_calendar_affected_contact_count" => 4,
             "source_report_station_calendar_provider_calendar_contention_group_count" => 4,
             "source_report_station_calendar_direction_counts" => %{"downlink" => 4},
             "source_report_station_calendar_provider_calendar_contention_direction_counts" => %{
               "downlink" => 4
             },
             "source_report_station_calendar_status_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 2,
               "unavailable" => 1
             },
             "source_report_station_calendar_affected_contact_ground_station_counts" => %{
               "canberra_deep" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "source_report_station_calendar_provider_calendar_contention_provider_counts" => %{
               "canonical_direct_provider" => 1,
               "direct_provider" => 1,
               "result_wrapped_provider" => 1,
               "source_wrapped_provider" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "station_calendar_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "affected_contact_count" => 4,
             "provider_calendar_contention_group_count" => 4,
             "affected_contact_ids" => [
               "canonical_direct_contact",
               "direct_contact",
               "result_wrapped_contact",
               "source_wrapped_contact"
             ],
             "affected_station_calendar_entry_ids" => [
               "canonical_direct_station_entry",
               "direct_station_entry",
               "result_wrapped_station_entry",
               "source_wrapped_station_entry"
             ],
             "provider_calendar_contention_group_ids" => [
               "canonical_direct_contention_group",
               "direct_contention_group",
               "result_wrapped_contention_group",
               "source_wrapped_contention_group"
             ],
             "direction_counts" => %{"downlink" => 4},
             "contact_ids_by_direction" => %{
               "downlink" => [
                 "direct_contact",
                 "canonical_direct_contact",
                 "source_wrapped_contact",
                 "result_wrapped_contact"
               ]
             },
             "provider_calendar_contention_direction_counts" => %{"downlink" => 4},
             "provider_calendar_contention_group_ids_by_direction" => %{
               "downlink" => [
                 "direct_contention_group",
                 "canonical_direct_contention_group",
                 "source_wrapped_contention_group",
                 "result_wrapped_contention_group"
               ]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_station_calendar_pressure" => true,
             "branch_local_affected_contact_pressure" => true,
             "branch_local_provider_contention_pressure" => true,
             "branch_local_station_availability_pressure" => true,
             "assumptions" => %{
               "station_calendar_mutation" => "not_performed_by_summary",
               "schedule_mutation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.station_calendar_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.result_artifact.source_station_calendar_report",
             "mission_state.source_result_artifact.station_calendar_report",
             "mission_state.source_station_calendar_report",
             "mission_state.station_calendar_report"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_direct_provider_contention_boundary",
             "canonical_direct_station_calendar_report_boundary",
             "canonical_direct_station_calendar_row_boundary",
             "direct_provider_contention_boundary",
             "direct_station_calendar_report_boundary",
             "direct_station_calendar_row_boundary",
             "result_wrapped_provider_contention_boundary",
             "result_wrapped_station_calendar_boundary",
             "result_wrapped_station_calendar_row_boundary",
             "source_wrapped_provider_contention_boundary",
             "source_wrapped_station_calendar_boundary",
             "source_wrapped_station_calendar_row_boundary"
           ]

    station_calendar_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "station_calendar_pressure" and
            &1["feedback_source"] == "candidate_source.station_calendar_replay_summary")
      )

    assert station_calendar_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "station_calendar_pressure" and
                 &1["feedback_scope"] == "station_calendar" and
                 &1["affected_contact_count"] == 4 and
                 &1["provider_calendar_contention_group_count"] == 4 and
                 &1["station_calendar_status_counts"] == %{
                   "reduced_capacity" => 1,
                   "reserved" => 2,
                   "unavailable" => 1
                 } and
                 &1["ground_station_ids"] == [
                   "canberra_deep",
                   "dss_43",
                   "equator_prime",
                   "polar_prime"
                 ] and
                 &1["affected_contact_ids"] == [
                   "canonical_direct_contact",
                   "direct_contact",
                   "result_wrapped_contact",
                   "source_wrapped_contact"
                 ] and
                 &1["affected_station_calendar_entry_ids"] == [
                   "canonical_direct_station_entry",
                   "direct_station_entry",
                   "result_wrapped_station_entry",
                   "source_wrapped_station_entry"
                 ] and
                 &1["provider_calendar_contention_group_ids"] == [
                   "canonical_direct_contention_group",
                   "direct_contention_group",
                   "result_wrapped_contention_group",
                   "source_wrapped_contention_group"
                 ])
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["station_calendar_pressure_penalty"] ==
             -station_calendar_pressure_count * risk_weight

    assert "station_calendar_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "station_calendar_pressure_penalty" and &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state station-calendar precedence summaries into branch refresh requests" do
    contacts = [
      %{
        id: :dl_precedence,
        type: :downlink,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    provider = %{
      station_calendar: [
        %{
          id: :equator_reservation,
          station_id: :equator_prime,
          availability: :reserved,
          start_s: 90.0,
          end_s: 170.0
        },
        %{
          id: :equator_outage,
          station_id: :equator_prime,
          availability: :outage,
          start_s: 90.0,
          end_s: 170.0
        }
      ]
    }

    direct_summary =
      contacts
      |> OrbitalDynamics.Communications.StationCalendar.precedence_summary(provider,
        source: "ops_calendar"
      )
      |> Map.put("provenance", %{"trust_boundary" => "direct_precedence_summary"})

    canonical_summary =
      direct_summary
      |> Map.put("provenance", %{"trust_boundary" => "canonical_precedence_summary"})

    wrapped_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "wrapped_precedence_summary"})

    assert {:ok, %{"schema_contract" => "station_calendar_precedence_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_station_calendar_precedence_summary", direct_summary)
      |> Map.put("station_calendar_precedence_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "station_calendar_precedence_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "wrapped_precedence_artifact_boundary"}
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

    assert "mission_state.source_station_calendar_precedence_summary" in source_report_input_paths

    assert "mission_state.station_calendar_precedence_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.station_calendar_precedence_summary" in source_report_input_paths

    assert "mission_state.source_station_calendar_precedence_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.station_calendar_precedence_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.station_calendar_precedence_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_station_calendar_affected_contact_count" => 4,
             "source_report_station_calendar_reserved_under_higher_precedence_contact_count" => 4,
             "source_report_station_calendar_reserved_under_higher_precedence_contact_ids" => [
               "dl_precedence"
             ],
             "source_report_station_calendar_applied_availability_counts" => %{
               "unavailable" => 4
             },
             "source_report_station_calendar_overlap_availability_counts" => %{
               "reserved" => 4,
               "unavailable" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "station_calendar_precedence_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => station_calendar_source_paths,
             "affected_contact_count" => 4,
             "affected_contact_ids" => ["dl_precedence"],
             "applied_availability_counts" => %{"unavailable" => 4},
             "overlap_availability_counts" => %{"reserved" => 4, "unavailable" => 4},
             "reserved_under_higher_precedence_contact_count" => 4,
             "reserved_under_higher_precedence_contact_ids" => ["dl_precedence"],
             "trust_boundary_status" => "declared",
             "branch_local_station_calendar_pressure" => true,
             "branch_local_affected_contact_pressure" => true,
             "branch_local_station_availability_pressure" => true
           } = CandidateRefresh.station_calendar_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_station_calendar_precedence_summary[0]",
          "mission_state.source_station_calendar_precedence_summary[1]",
          "mission_state.station_calendar_precedence_summary",
          "mission_state.source_result_artifact.station_calendar_precedence_summary"
        ] do
      assert source_path in station_calendar_source_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
