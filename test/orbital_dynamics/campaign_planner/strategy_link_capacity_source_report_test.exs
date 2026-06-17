Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyLinkCapacitySourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema}

  test "strategy carries mission-state link-capacity reports into branch refresh requests" do
    link_capacity_report = fn prefix,
                              ground_station_id,
                              status,
                              actual_status,
                              capacity_mb,
                              selected_mb,
                              unused_mb ->
      %{
        "schema_contract" => "link_capacity_report.v1",
        "source" => "campaign_planner_test.#{prefix}.link_capacity_report",
        "rows" => [
          %{
            "ground_station_id" => ground_station_id,
            "spacecraft_id" => "leo_1",
            "direction" => "downlink",
            "capacity_adjusted_throughput_mb" => capacity_mb,
            "selected_capacity_adjusted_throughput_mb" => selected_mb,
            "unused_capacity_adjusted_throughput_mb" => unused_mb,
            "selected_downlink_shortfall_mb" => 5.0,
            "actual_downlink_shortfall_mb" => 2.0,
            "actual_throughput_mb" => selected_mb,
            "downlink_requirement_status" => status,
            "actual_downlink_requirement_status" => actual_status,
            "contact_ids" => ["#{prefix}_contact"],
            "selected_contact_ids" => ["#{prefix}_selected_contact"],
            "actual_throughput_contact_ids" => ["#{prefix}_actual_contact"],
            "source_window_ids" => ["#{prefix}_source_window"],
            "station_calendar_entry_ids" => ["#{prefix}_station_entry"],
            "station_calendar_provider_entry_ids" => ["#{prefix}_provider_entry"],
            "trust_boundary" => "#{prefix}_link_capacity_row_boundary"
          }
        ],
        "provenance" => %{"trust_boundary" => "#{prefix}_link_capacity_report_boundary"}
      }
    end

    direct_report =
      link_capacity_report.(
        "direct",
        "equator_prime",
        "selected_shortfall",
        "actual_met",
        80.0,
        60.0,
        20.0
      )

    canonical_direct_report =
      link_capacity_report.(
        "canonical_direct",
        "canberra_deep",
        "selected_met",
        "actual_met",
        70.0,
        55.0,
        15.0
      )

    source_wrapped_report =
      link_capacity_report.(
        "source_wrapped",
        "dss_43",
        "selected_shortfall",
        "actual_shortfall",
        60.0,
        45.0,
        15.0
      )

    result_wrapped_report =
      link_capacity_report.(
        "result_wrapped",
        "polar_prime",
        "selected_met",
        "actual_shortfall",
        40.0,
        25.0,
        15.0
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_link_capacity_report", direct_report)
      |> Map.put("link_capacity_report", canonical_direct_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "link_capacity_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_link_capacity_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_link_capacity_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_link_capacity_boundary"}
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
          "mission_state.link_capacity_report",
          "mission_state.source_link_capacity_report",
          "mission_state.source_result_artifact.link_capacity_report",
          "mission_state.result_artifact.source_link_capacity_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_link_capacity_selected_shortfall_row_count" => 4,
             "source_report_link_capacity_actual_shortfall_row_count" => 4,
             "source_report_link_capacity_actual_throughput_row_count" => 4,
             "source_report_link_capacity_capacity_adjusted_throughput_row_count" => 4,
             "source_report_link_capacity_capacity_adjusted_throughput_mb_total" => 250.0,
             "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_total" =>
               185.0,
             "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 65.0,
             "source_report_link_capacity_ground_station_counts" => %{
               "canberra_deep" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "source_report_link_capacity_selected_contact_id_counts" => %{
               "canonical_direct_selected_contact" => 1,
               "direct_selected_contact" => 1,
               "result_wrapped_selected_contact" => 1,
               "source_wrapped_selected_contact" => 1
             },
             "source_report_link_capacity_actual_throughput_contact_id_counts" => %{
               "canonical_direct_actual_contact" => 1,
               "direct_actual_contact" => 1,
               "result_wrapped_actual_contact" => 1,
               "source_wrapped_actual_contact" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "link_capacity_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "selected_shortfall_row_count" => 4,
             "actual_shortfall_row_count" => 4,
             "actual_throughput_row_count" => 4,
             "capacity_adjusted_throughput_row_count" => 4,
             "capacity_adjusted_throughput_mb_total" => 250.0,
             "selected_capacity_adjusted_throughput_mb_total" => 185.0,
             "unused_capacity_adjusted_throughput_mb_total" => 65.0,
             "ground_station_counts" => %{
               "canberra_deep" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "selected_contact_id_counts" => %{
               "canonical_direct_selected_contact" => 1,
               "direct_selected_contact" => 1,
               "result_wrapped_selected_contact" => 1,
               "source_wrapped_selected_contact" => 1
             },
             "actual_throughput_contact_id_counts" => %{
               "canonical_direct_actual_contact" => 1,
               "direct_actual_contact" => 1,
               "result_wrapped_actual_contact" => 1,
               "source_wrapped_actual_contact" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_link_capacity_pressure" => true,
             "branch_local_capacity_adjusted_throughput_pressure" => true,
             "branch_local_downlink_shortfall_pressure" => true,
             "branch_local_actual_throughput_pressure" => true,
             "assumptions" => %{
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.link_capacity_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.link_capacity_report",
             "mission_state.result_artifact.source_link_capacity_report",
             "mission_state.source_link_capacity_report",
             "mission_state.source_result_artifact.link_capacity_report"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_direct_link_capacity_report_boundary",
             "canonical_direct_link_capacity_row_boundary",
             "direct_link_capacity_report_boundary",
             "direct_link_capacity_row_boundary",
             "result_wrapped_link_capacity_row_boundary",
             "source_wrapped_link_capacity_row_boundary"
           ]

    link_capacity_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and
            &1["feedback_source"] == "candidate_source.link_capacity_replay_summary")
      )

    assert link_capacity_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "link_capacity" and
                 &1["selected_shortfall_row_count"] == 4 and
                 &1["actual_shortfall_row_count"] == 4 and
                 &1["actual_throughput_row_count"] == 4 and
                 &1["capacity_adjusted_throughput_row_count"] == 4 and
                 &1["capacity_adjusted_throughput_mb_total"] == 250.0 and
                 &1["selected_capacity_adjusted_throughput_mb_total"] == 185.0 and
                 &1["unused_capacity_adjusted_throughput_mb_total"] == 65.0 and
                 &1["ground_station_ids"] == [
                   "canberra_deep",
                   "dss_43",
                   "equator_prime",
                   "polar_prime"
                 ] and
                 &1["selected_contact_ids"] == [
                   "canonical_direct_selected_contact",
                   "direct_selected_contact",
                   "result_wrapped_selected_contact",
                   "source_wrapped_selected_contact"
                 ] and
                 &1["actual_throughput_contact_ids"] == [
                   "canonical_direct_actual_contact",
                   "direct_actual_contact",
                   "result_wrapped_actual_contact",
                   "source_wrapped_actual_contact"
                 ])
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["link_capacity_pressure_penalty"] ==
             -link_capacity_pressure_count * risk_weight

    assert "link_capacity_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "link_capacity_pressure_penalty" and &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state link-capacity summaries into branch refresh requests" do
    link_capacity_report = %{
      "schema_contract" => "link_capacity_report.v1",
      "source" => "campaign_planner_test.link_capacity_summary",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "contact_count" => 1,
          "effective_contact_count" => 1,
          "selected_contact_count" => 1,
          "selected_downlink_shortfall_mb" => 20.0,
          "actual_downlink_shortfall_mb" => 5.0,
          "capacity_adjusted_throughput_mb" => 80.0,
          "selected_capacity_adjusted_throughput_mb" => 60.0,
          "unused_capacity_adjusted_throughput_mb" => 20.0,
          "downlink_requirement_status" => "shortfall",
          "actual_downlink_requirement_status" => "shortfall",
          "contact_ids" => ["science_downlink"],
          "selected_contact_ids" => ["science_downlink"],
          "actual_throughput_contact_ids" => ["science_downlink"],
          "station_calendar_entry_ids" => ["station_entry_equator"],
          "station_calendar_provider_entry_ids" => ["provider_entry_equator"]
        }
      ]
    }

    direct_summary =
      link_capacity_report
      |> OrbitalDynamics.Communications.LinkCapacity.summary()
      |> Map.put("provenance", %{"trust_boundary" => "direct_link_capacity_summary"})

    canonical_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("source", "campaign_planner_test.canonical_link_capacity_summary")
      |> Map.put("provenance", %{"trust_boundary" => "canonical_link_capacity_summary"})

    wrapped_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "wrapped_link_capacity_summary"})

    result_wrapped_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "result_wrapped_link_capacity_summary"})

    assert {:ok, %{"schema_contract" => "link_capacity_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_link_capacity_summary", direct_summary)
      |> Map.put("link_capacity_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "link_capacity_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "wrapped_link_capacity_artifact_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "link_capacity_summary" => result_wrapped_summary,
        "provenance" => %{"trust_boundary" => "result_wrapped_link_capacity_artifact_boundary"}
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

    assert "mission_state.source_link_capacity_summary" in source_report_input_paths

    assert "mission_state.link_capacity_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.link_capacity_summary" in source_report_input_paths

    assert "mission_state.result_artifact.link_capacity_summary" in source_report_input_paths

    assert "mission_state.source_link_capacity_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.link_capacity_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.link_capacity_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.result_artifact.link_capacity_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_link_capacity_selected_shortfall_row_count" => 4,
             "source_report_link_capacity_actual_shortfall_row_count" => 4,
             "source_report_link_capacity_actual_throughput_row_count" => 4,
             "source_report_link_capacity_capacity_adjusted_throughput_row_count" => 4,
             "source_report_link_capacity_capacity_adjusted_throughput_mb_total" => 320.0,
             "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_total" =>
               240.0,
             "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 80.0,
             "source_report_link_capacity_ground_station_counts" => %{"equator_prime" => 4},
             "source_report_link_capacity_selected_contact_id_counts" => %{
               "science_downlink" => 4
             },
             "source_report_link_capacity_actual_throughput_contact_id_counts" => %{
               "science_downlink" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "link_capacity_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => link_capacity_source_paths,
             "capacity_adjusted_throughput_mb_total" => 320.0,
             "selected_capacity_adjusted_throughput_mb_total" => 240.0,
             "unused_capacity_adjusted_throughput_mb_total" => 80.0,
             "ground_station_counts" => %{"equator_prime" => 4},
             "selected_contact_ids" => ["science_downlink"],
             "actual_throughput_contact_ids" => ["science_downlink"],
             "trust_boundary_status" => "declared",
             "branch_local_link_capacity_pressure" => true,
             "branch_local_capacity_adjusted_throughput_pressure" => true,
             "branch_local_downlink_shortfall_pressure" => true,
             "branch_local_actual_throughput_pressure" => true
           } = CandidateRefresh.link_capacity_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.link_capacity_summary",
          "mission_state.source_link_capacity_summary",
          "mission_state.source_result_artifact.link_capacity_summary",
          "mission_state.result_artifact.link_capacity_summary"
        ] do
      assert source_path in link_capacity_source_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy challenge scores link-capacity replay from rows when top-level fields are stale" do
    rows = [
      %{
        "ground_station_id" => "equator_prime",
        "spacecraft_id" => "leo_1",
        "direction" => "Down Link",
        "contact_count" => 1,
        "effective_contact_count" => 1,
        "selected_contact_count" => 1,
        "selected_downlink_shortfall_mb" => 12.0,
        "actual_downlink_shortfall_mb" => 3.0,
        "capacity_adjusted_throughput_mb" => 70.0,
        "selected_capacity_adjusted_throughput_mb" => 45.0,
        "unused_capacity_adjusted_throughput_mb" => 25.0,
        "downlink_requirement_status" => "shortfall",
        "actual_downlink_requirement_status" => "shortfall",
        "contact_ids" => ["row_capacity_contact"],
        "selected_contact_ids" => ["row_capacity_contact"],
        "actual_throughput_contact_ids" => ["row_capacity_contact"],
        "source_window_ids" => ["row_window"],
        "station_calendar_entry_ids" => ["row_station_entry"],
        "station_calendar_provider_entry_ids" => ["row_provider_entry"]
      }
    ]

    stale_summary =
      %{"schema_contract" => "link_capacity_report.v1", "rows" => rows}
      |> OrbitalDynamics.Communications.LinkCapacity.summary()
      |> Map.put("rows", rows)
      |> Map.put("provenance", %{"trust_boundary" => "stale_strategy_link_capacity_summary"})
      |> Map.merge(%{
        "station_count" => 99,
        "selected_downlink_shortfall_mb" => 999.0,
        "actual_downlink_shortfall_mb" => 999.0,
        "capacity_adjusted_throughput_mb" => 999.0,
        "selected_capacity_adjusted_throughput_mb" => 999.0,
        "unused_capacity_adjusted_throughput_mb" => 999.0,
        "ground_station_ids" => ["stale_station"],
        "capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "stale_station" => 999.0
        },
        "selected_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "stale_station" => 999.0
        },
        "unused_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "stale_station" => 999.0
        },
        "selected_contact_ids" => ["stale_selected_contact"],
        "actual_throughput_contact_ids" => ["stale_actual_contact"],
        "selected_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_selected_contact"]
        },
        "actual_throughput_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_actual_contact"]
        },
        "contact_ids_by_direction" => %{"uplink" => ["stale_contact"]},
        "source_window_ids_by_direction" => %{"uplink" => ["stale_window"]},
        "direction_routing" => %{
          "uplink" => %{
            "contact_count" => 99,
            "contact_ids" => ["stale_contact"]
          }
        }
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_link_capacity_summary, stale_summary),
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

    expected_direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["row_capacity_contact"],
        "source_window_ids" => ["row_window"],
        "station_calendar_entry_ids" => ["row_station_entry"],
        "station_calendar_provider_entry_ids" => ["row_provider_entry"],
        "capacity_adjusted_throughput_mb" => 70.0,
        "selected_capacity_adjusted_throughput_mb" => 45.0,
        "unused_capacity_adjusted_throughput_mb" => 25.0
      }
    }

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["mission_state.source_link_capacity_summary"],
             "selected_shortfall_row_count" => 1,
             "actual_shortfall_row_count" => 1,
             "actual_throughput_row_count" => 1,
             "capacity_adjusted_throughput_row_count" => 1,
             "capacity_adjusted_throughput_mb_total" => 70.0,
             "selected_capacity_adjusted_throughput_mb_total" => 45.0,
             "unused_capacity_adjusted_throughput_mb_total" => 25.0,
             "ground_station_counts" => %{"equator_prime" => 1},
             "contact_ids_by_direction" => %{"downlink" => ["row_capacity_contact"]},
             "source_window_ids_by_direction" => %{"downlink" => ["row_window"]},
             "direction_routing" => ^expected_direction_routing,
             "selected_contact_ids" => ["row_capacity_contact"],
             "actual_throughput_contact_ids" => ["row_capacity_contact"],
             "branch_local_link_capacity_pressure" => true,
             "branch_local_capacity_adjusted_throughput_pressure" => true,
             "branch_local_downlink_shortfall_pressure" => true,
             "branch_local_actual_throughput_pressure" => true
           } = CandidateRefresh.link_capacity_replay_summary(candidate_source)

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_source"] == "candidate_source.link_capacity_replay_summary" and
                 &1["feedback_scope"] == "link_capacity" and
                 &1["source_report_count"] == 1 and
                 &1["source_report_row_count"] == 1 and
                 &1["source_report_paths"] == ["mission_state.source_link_capacity_summary"] and
                 &1["selected_shortfall_row_count"] == 1 and
                 &1["actual_shortfall_row_count"] == 1 and
                 &1["actual_throughput_row_count"] == 1 and
                 &1["capacity_adjusted_throughput_row_count"] == 1 and
                 &1["capacity_adjusted_throughput_mb_total"] == 70.0 and
                 &1["selected_capacity_adjusted_throughput_mb_total"] == 45.0 and
                 &1["unused_capacity_adjusted_throughput_mb_total"] == 25.0 and
                 &1["ground_station_ids"] == ["equator_prime"] and
                 &1["directions"] == ["downlink"] and
                 &1["selected_contact_ids"] == ["row_capacity_contact"] and
                 &1["actual_throughput_contact_ids"] == ["row_capacity_contact"] and
                 &1["direction_routing"] == expected_direction_routing)
           )

    assert_link_capacity_pressure_score_terms(urgent, artifact)

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "downlink_completion_gap" in urgent_row["risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives relay data-path summaries as branch-local link-capacity pressure" do
    relay_summary = fn prefix, station_id, route_id, contact_id ->
      %{
        "schema_contract" => "relay_data_path_summary.v1",
        "schema_version" => 1,
        "model" => "artifact_only_relay_data_path_summary",
        "source" => "campaign_planner_test.#{prefix}.relay_data_path_summary",
        "route_count" => 1,
        "relay_route_count" => 0,
        "direct_downlink_route_count" => 1,
        "custody_status_counts" => %{"missing_ack" => 1},
        "latency_status_counts" => %{"exceeds_limit" => 1},
        "risk_status_counts" => %{"high" => 1},
        "route_ids" => [route_id],
        "source_spacecraft_ids" => ["sat_#{prefix}"],
        "relay_spacecraft_ids" => ["relay_#{prefix}"],
        "ground_station_ids" => [station_id],
        "ground_downlink_contact_ids" => [contact_id],
        "route_ids_by_custody_status" => %{"missing_ack" => [route_id]},
        "route_ids_by_latency_status" => %{"exceeds_limit" => [route_id]},
        "route_ids_by_risk_status" => %{"high" => [route_id]},
        "route_ids_by_ground_station_id" => %{station_id => [route_id]},
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
          "provider_reservation" => "not_performed",
          "operator_authority" => "not_granted_by_summary"
        },
        "provenance" => %{"trust_boundary" => "#{prefix}_relay_boundary"},
        "rows" => [
          %{
            "route_id" => route_id,
            "source_spacecraft_id" => "sat_#{prefix}",
            "relay_chain_spacecraft_ids" => ["relay_#{prefix}"],
            "relay_hop_count" => 1,
            "ground_station_id" => station_id,
            "ground_downlink_contact_id" => contact_id,
            "custody_status" => "missing_ack",
            "latency_s" => 500.0,
            "latency_limit_s" => 300.0,
            "latency_status" => "exceeds_limit",
            "risk_status" => "high",
            "risk_reasons" => ["custody_missing_ack", "latency_exceeds_limit"],
            "product_ids" => ["product_#{prefix}"],
            "collection_ids" => ["collection_#{prefix}"]
          }
        ]
      }
    end

    direct_summary = relay_summary.("direct", "dss_14", "route_direct", "downlink_direct")

    canonical_summary =
      relay_summary.("canonical", "dss_35", "route_canonical", "downlink_canonical")

    wrapped_summary = relay_summary.("wrapped", "dss_54", "route_wrapped", "downlink_wrapped")

    result_wrapped_summary =
      relay_summary.(
        "result_wrapped",
        "dss_63",
        "route_result_wrapped",
        "downlink_result_wrapped"
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_relay_data_path_summary", direct_summary)
      |> Map.put("relay_data_path_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "relay_data_path_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "wrapped_result_artifact_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "source_relay_data_path_summary" => result_wrapped_summary,
        "provenance" => %{"trust_boundary" => "result_wrapped_artifact_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch = branch(artifact, "derived_link_capacity_pressure_dss_14")
    canonical_branch = branch(artifact, "derived_link_capacity_pressure_dss_35")
    wrapped_branch = branch(artifact, "derived_link_capacity_pressure_dss_54")
    result_wrapped_branch = branch(artifact, "derived_link_capacity_pressure_dss_63")

    assert %{
             "type" => "relay_data_path_pressure",
             "ground_station_id" => "dss_14",
             "route_id" => "route_direct",
             "ground_downlink_contact_id" => "downlink_direct",
             "custody_status" => "missing_ack",
             "latency_status" => "exceeds_limit",
             "risk_status" => "high",
             "route_count" => 1,
             "custody_status_counts" => %{"missing_ack" => 1},
             "latency_status_counts" => %{"exceeds_limit" => 1},
             "risk_status_counts" => %{"high" => 1},
             "feedback_source" => "mission_state.source_relay_data_path_summary",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "direct_relay_boundary",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
               "provider_reservation" => "not_performed",
               "operator_authority" => "not_granted_by_summary"
             }
           } = List.first(direct_branch["events"])

    assert "relay_data_path_custody_missing_ack" in List.first(direct_branch["events"])[
             "derivation_reasons"
           ]

    assert "relay_data_path_latency_exceeds_limit" in List.first(direct_branch["events"])[
             "derivation_reasons"
           ]

    assert "relay_data_path_risk_high" in List.first(direct_branch["events"])[
             "derivation_reasons"
           ]

    assert %{
             "type" => "relay_data_path_pressure",
             "severity" => "high",
             "route_id" => "route_direct",
             "feedback_source" => "mission_state.source_relay_data_path_summary",
             "trust_boundary" => "direct_relay_boundary"
           } =
             Enum.find(
               direct_branch["risk_indicators"],
               &(&1["type"] == "relay_data_path_pressure")
             )

    assert_relay_data_path_pressure_score_terms(direct_branch, artifact)

    assert List.first(canonical_branch["events"])["feedback_source"] ==
             "mission_state.relay_data_path_summary"

    assert List.first(wrapped_branch["events"])["feedback_source"] ==
             "mission_state.source_result_artifact.relay_data_path_summary"

    assert List.first(result_wrapped_branch["events"])["feedback_source"] ==
             "mission_state.result_artifact.source_relay_data_path_summary"

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = direct_branch["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_relay_data_path_summary",
          "mission_state.relay_data_path_summary",
          "mission_state.source_result_artifact.relay_data_path_summary",
          "mission_state.result_artifact.source_relay_data_path_summary"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]
    end

    for source_path <- [
          "mission_state.source_relay_data_path_summary",
          "mission_state.relay_data_path_summary"
        ] do
      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "contract" => "relay_data_path_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "relay_route_count" => 4,
             "ground_downlink_contact_ids" => [
               "downlink_canonical",
               "downlink_direct",
               "downlink_result_wrapped",
               "downlink_wrapped"
             ],
             "trust_boundary_status" => "declared",
             "branch_local_link_capacity_pressure" => true
           } = replay_summary = CandidateRefresh.link_capacity_replay_summary(candidate_source)

    refute Map.has_key?(replay_summary, "direct_downlink_route_count")

    for source_path <- [
          "mission_state.source_relay_data_path_summary",
          "mission_state.relay_data_path_summary",
          "mission_state.source_result_artifact.relay_data_path_summary",
          "mission_state.result_artifact.source_relay_data_path_summary"
        ] do
      assert source_path in replay_source_paths
    end

    relay_pressure_rows =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.filter(
        &(Map.get(&1, "branch_id") in [
            "derived_link_capacity_pressure_dss_14",
            "derived_link_capacity_pressure_dss_35",
            "derived_link_capacity_pressure_dss_54",
            "derived_link_capacity_pressure_dss_63"
          ])
      )

    assert Enum.all?(relay_pressure_rows, &("relay_data_path_pressure" in &1["risk_types"]))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_relay_data_path_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    relay_data_path_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "relay_data_path_pressure")
      )

    assert relay_data_path_pressure_count > 0

    assert branch["score_terms"]["relay_data_path_pressure_penalty"] ==
             -relay_data_path_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - relay_data_path_pressure_count) *
               risk_weight

    assert "relay_data_path_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "relay_data_path_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp assert_link_capacity_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    link_capacity_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and &1["feedback_scope"] == "link_capacity")
      )

    assert link_capacity_pressure_count > 0

    assert branch["score_terms"]["link_capacity_pressure_penalty"] ==
             -link_capacity_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - link_capacity_pressure_count) * risk_weight

    assert "link_capacity_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "link_capacity_pressure_penalty" and &1["value"] < 0.0)
           )
  end
end
