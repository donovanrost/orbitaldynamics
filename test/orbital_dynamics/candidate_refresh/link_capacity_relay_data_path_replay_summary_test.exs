defmodule OrbitalDynamics.CandidateRefresh.LinkCapacityRelayDataPathReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays relay data path summaries" do
    summary = relay_data_path_summary_fixture()

    refresh = %{
      "accepted_planning_state" => %{"relay_data_path_summary" => summary},
      "mission_state" => %{"source_relay_data_path_summary" => summary},
      "source_relay_data_path_summary" => summary,
      "source_result_artifact" => %{"relay_data_path_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{"relay_data_path_summary.v1" => 4},
             "source_report_row_counts_by_contract" => %{"relay_data_path_summary.v1" => 8},
             "source_report_link_capacity_contract" => "relay_data_path_summary.v1",
             "source_report_link_capacity_count" => 4,
             "source_report_link_capacity_row_count" => 8,
             "source_report_link_capacity_paths" => [
               "accepted_planning_state.relay_data_path_summary",
               "mission_state.source_relay_data_path_summary",
               "source_relay_data_path_summary",
               "source_result_artifact.relay_data_path_summary"
             ],
             "source_report_link_capacity_ground_station_counts" => %{
               "dss_14" => 4,
               "dss_35" => 4
             },
             "source_reports" => %{
               "link_capacity_report" => %{
                 "paths" => [
                   "accepted_planning_state.relay_data_path_summary",
                   "mission_state.source_relay_data_path_summary",
                   "source_relay_data_path_summary",
                   "source_result_artifact.relay_data_path_summary"
                 ],
                 "contract" => "relay_data_path_summary.v1",
                 "count" => 4,
                 "row_count" => 8,
                 "source_summary_model_counts" => %{
                   "artifact_only_relay_data_path_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "relay_data_path_summary.v1" => 4
                 },
                 "relay_route_count" => 4,
                 "direct_downlink_route_count" => 4,
                 "relay_route_ids" => ["route_direct", "route_relay_alpha"],
                 "source_spacecraft_ids" => ["sat_a", "sat_b"],
                 "relay_spacecraft_ids" => ["relay_1", "relay_2"],
                 "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
                 "relay_custody_status_counts" => %{"confirmed" => 4, "missing_ack" => 4},
                 "relay_latency_status_counts" => %{"exceeds_limit" => 4, "within_limit" => 4},
                 "relay_risk_status_counts" => %{"high" => 4, "nominal" => 4},
                 "relay_route_ids_by_custody_status" => %{
                   "confirmed" => ["route_relay_alpha"],
                   "missing_ack" => ["route_direct"]
                 },
                 "relay_route_ids_by_latency_status" => %{
                   "exceeds_limit" => ["route_direct"],
                   "within_limit" => ["route_relay_alpha"]
                 },
                 "relay_route_ids_by_risk_status" => %{
                   "high" => ["route_direct"],
                   "nominal" => ["route_relay_alpha"]
                 },
                 "relay_route_ids_by_ground_station" => %{
                   "dss_14" => ["route_relay_alpha"],
                   "dss_35" => ["route_direct"]
                 },
                 "ground_station_counts" => %{"dss_14" => 4, "dss_35" => 4},
                 "spacecraft_counts" => %{"sat_a" => 4, "sat_b" => 4},
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["relay_ops"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.link_capacity_replay_summary(refresh)

    assert replay_summary["contract"] == "relay_data_path_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 8
    assert replay_summary["relay_route_count"] == 4
    assert replay_summary["direct_downlink_route_count"] == 4
    assert replay_summary["relay_route_ids"] == ["route_direct", "route_relay_alpha"]
    assert replay_summary["source_spacecraft_ids"] == ["sat_a", "sat_b"]
    assert replay_summary["relay_spacecraft_ids"] == ["relay_1", "relay_2"]
    assert replay_summary["ground_downlink_contact_ids"] == ["downlink_1", "downlink_2"]

    assert replay_summary["relay_custody_status_counts"] == %{
             "confirmed" => 4,
             "missing_ack" => 4
           }

    assert replay_summary["relay_latency_status_counts"] == %{
             "exceeds_limit" => 4,
             "within_limit" => 4
           }

    assert replay_summary["relay_risk_status_counts"] == %{"high" => 4, "nominal" => 4}

    assert replay_summary["relay_route_ids_by_ground_station"] == %{
             "dss_14" => ["route_relay_alpha"],
             "dss_35" => ["route_direct"]
           }

    assert replay_summary["ground_station_counts"] == %{"dss_14" => 4, "dss_35" => 4}
    assert replay_summary["spacecraft_counts"] == %{"sat_a" => 4, "sat_b" => 4}
    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["relay_ops"]
    assert replay_summary["branch_local_link_capacity_pressure"]
    refute replay_summary["branch_local_capacity_adjusted_throughput_pressure"]
    refute replay_summary["branch_local_downlink_shortfall_pressure"]
    refute replay_summary["branch_local_actual_throughput_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.link_capacity_replay_summary(artifact) == replay_summary
  end

  test "relay data path source summaries derive stale aggregate pressure from rows" do
    stale_summary =
      relay_data_path_summary_fixture()
      |> Map.merge(%{
        "route_count" => 99,
        "relay_route_count" => 99,
        "direct_downlink_route_count" => 99,
        "custody_status_counts" => %{"stale_custody" => 99},
        "latency_status_counts" => %{"stale_latency" => 99},
        "risk_status_counts" => %{"stale_risk" => 99},
        "route_ids" => ["stale_route"],
        "source_spacecraft_ids" => ["stale_source_spacecraft"],
        "relay_spacecraft_ids" => ["stale_relay"],
        "ground_station_ids" => ["stale_station"],
        "ground_downlink_contact_ids" => ["stale_downlink"],
        "route_ids_by_custody_status" => %{"stale_custody" => ["stale_route"]},
        "route_ids_by_latency_status" => %{"stale_latency" => ["stale_route"]},
        "route_ids_by_risk_status" => %{"stale_risk" => ["stale_route"]},
        "route_ids_by_ground_station_id" => %{"stale_station" => ["stale_route"]}
      })

    refresh = %{"source_relay_data_path_summary" => stale_summary}

    assert %{
             "source_report_link_capacity_contract" => "relay_data_path_summary.v1",
             "source_report_link_capacity_count" => 1,
             "source_report_link_capacity_row_count" => 2,
             "source_report_link_capacity_ground_station_counts" => %{
               "dss_14" => 1,
               "dss_35" => 1
             },
             "source_report_link_capacity_spacecraft_counts" => %{"sat_a" => 1, "sat_b" => 1},
             "source_report_link_capacity_branch_local_link_capacity_pressure" => true,
             "source_reports" => %{
               "link_capacity_report" => %{
                 "relay_route_count" => 1,
                 "direct_downlink_route_count" => 1,
                 "relay_route_ids" => ["route_direct", "route_relay_alpha"],
                 "source_spacecraft_ids" => ["sat_a", "sat_b"],
                 "relay_spacecraft_ids" => ["relay_1", "relay_2"],
                 "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
                 "relay_custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
                 "relay_latency_status_counts" => %{
                   "exceeds_limit" => 1,
                   "within_limit" => 1
                 },
                 "relay_risk_status_counts" => %{"high" => 1, "nominal" => 1},
                 "relay_route_ids_by_ground_station" => %{
                   "dss_14" => ["route_relay_alpha"],
                   "dss_35" => ["route_direct"]
                 }
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    refute "stale_route" in get_in(source_summary, [
             "source_reports",
             "link_capacity_report",
             "relay_route_ids"
           ])

    assert %{
             "source_report_row_count" => 2,
             "relay_route_count" => 1,
             "direct_downlink_route_count" => 1,
             "relay_route_ids" => ["route_direct", "route_relay_alpha"],
             "source_spacecraft_ids" => ["sat_a", "sat_b"],
             "relay_spacecraft_ids" => ["relay_1", "relay_2"],
             "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
             "relay_custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
             "relay_latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
             "relay_risk_status_counts" => %{"high" => 1, "nominal" => 1},
             "relay_route_ids_by_ground_station" => %{
               "dss_14" => ["route_relay_alpha"],
               "dss_35" => ["route_direct"]
             },
             "ground_station_counts" => %{"dss_14" => 1, "dss_35" => 1},
             "spacecraft_counts" => %{"sat_a" => 1, "sat_b" => 1},
             "branch_local_link_capacity_pressure" => true
           } = CandidateRefresh.link_capacity_replay_summary(refresh)
  end

  test "source report summary replays wrapped relay data path summaries" do
    direct_summary =
      relay_data_path_summary_fixture()
      |> Map.put("source", "relay_ops.direct")

    nested_summary =
      relay_data_path_summary_fixture()
      |> Map.put("source", "relay_ops.nested")

    refresh = %{
      "source_result_artifact" => [
        direct_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "relay_data_path_summary" => nested_summary
        }
      ]
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, ["source_reports", "link_capacity_report", "paths"]) == [
             "source_result_artifact[0]",
             "source_result_artifact[1].relay_data_path_summary"
           ]

    assert get_in(source_summary, ["source_reports", "link_capacity_report", "contract"]) ==
             "relay_data_path_summary.v1"

    assert get_in(source_summary, ["source_reports", "link_capacity_report", "count"]) == 2
    assert get_in(source_summary, ["source_reports", "link_capacity_report", "row_count"]) == 4

    assert get_in(source_summary, ["source_reports", "link_capacity_report", "relay_route_count"]) ==
             2

    replay_summary = CandidateRefresh.link_capacity_replay_summary(refresh)

    assert replay_summary["source_report_paths"] == [
             "source_result_artifact[0]",
             "source_result_artifact[1].relay_data_path_summary"
           ]

    assert replay_summary["relay_route_count"] == 2
    assert replay_summary["direct_downlink_route_count"] == 2
    assert replay_summary["branch_local_link_capacity_pressure"]
  end

  defp relay_data_path_summary_fixture do
    %{
      "schema_contract" => "relay_data_path_summary.v1",
      "schema_version" => 1,
      "model" => "artifact_only_relay_data_path_summary",
      "source" => "relay_ops",
      "route_count" => 2,
      "relay_route_count" => 1,
      "direct_downlink_route_count" => 1,
      "custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
      "latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
      "risk_status_counts" => %{"high" => 1, "nominal" => 1},
      "route_ids" => ["route_relay_alpha", "route_direct"],
      "source_spacecraft_ids" => ["sat_a", "sat_b"],
      "relay_spacecraft_ids" => ["relay_1", "relay_2"],
      "ground_station_ids" => ["dss_14", "dss_35"],
      "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
      "route_ids_by_custody_status" => %{
        "confirmed" => ["route_relay_alpha"],
        "missing_ack" => ["route_direct"]
      },
      "route_ids_by_latency_status" => %{
        "exceeds_limit" => ["route_direct"],
        "within_limit" => ["route_relay_alpha"]
      },
      "route_ids_by_risk_status" => %{
        "high" => ["route_direct"],
        "nominal" => ["route_relay_alpha"]
      },
      "route_ids_by_ground_station_id" => %{
        "dss_14" => ["route_relay_alpha"],
        "dss_35" => ["route_direct"]
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
        "crosslink_visibility_model" => "not_evaluated",
        "custody_acknowledgement_delivery" => "not_performed",
        "provider_reservation" => "not_performed",
        "operator_authority" => "not_granted_by_summary"
      },
      "provenance" => %{"trust_boundary" => "relay_ops"},
      "rows" => [
        %{
          "route_id" => "route_relay_alpha",
          "source_spacecraft_id" => "sat_a",
          "relay_chain_spacecraft_ids" => ["relay_2", "relay_1"],
          "relay_hop_count" => 2,
          "ground_station_id" => "dss_14",
          "ground_downlink_contact_id" => "downlink_1",
          "custody_status" => "confirmed",
          "latency_s" => 180.0,
          "latency_limit_s" => 240.0,
          "latency_status" => "within_limit",
          "risk_status" => "nominal",
          "product_ids" => ["image_alpha"],
          "collection_ids" => ["collection_alpha"]
        },
        %{
          "route_id" => "route_direct",
          "source_spacecraft_id" => "sat_b",
          "relay_chain_spacecraft_ids" => [],
          "relay_hop_count" => 0,
          "ground_station_id" => "dss_35",
          "ground_downlink_contact_id" => "downlink_2",
          "custody_status" => "missing_ack",
          "latency_s" => 500.0,
          "latency_limit_s" => 300.0,
          "latency_status" => "exceeds_limit",
          "risk_status" => "high",
          "risk_reasons" => [
            "custody_missing_ack",
            "latency_exceeds_limit",
            "operator review queued"
          ],
          "product_ids" => ["image_beta"],
          "collection_ids" => []
        }
      ]
    }
  end
end
