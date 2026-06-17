Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceFilterSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state resource-filter reports into branch refresh requests" do
    resource_filter_report = fn prefix,
                                trust_boundary,
                                direction,
                                reason,
                                resource_id,
                                dimension ->
      %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "#{prefix}_obs_resource_block",
            "type" => direction,
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "resource_id" => resource_id,
            "suppressed_reason" => reason,
            "resource_blocking_dimension" => dimension,
            "resource_trust_boundary_status" => "declared"
          }
        ],
        "provenance" => %{"trust_boundary" => trust_boundary}
      }
    end

    direct_report =
      resource_filter_report.(
        "direct",
        "direct_resource_filter_report_boundary",
        "downlink",
        "payload_unavailable",
        "payload_1",
        "payload"
      )
      |> Map.put("invalid_resource_summary_inputs", [
        %{"resource_summary_id" => "direct_bad_resource_summary"}
      ])

    canonical_report =
      resource_filter_report.(
        "canonical",
        "canonical_resource_filter_report_boundary",
        "slew",
        "thermal_margin_below_policy",
        "thermal_bus",
        "thermal"
      )

    source_wrapped_report =
      resource_filter_report.(
        "source_wrapped",
        "source_wrapped_resource_filter_report_fixture",
        "command",
        "antenna_unavailable",
        "antenna_1",
        "antenna"
      )

    result_wrapped_report =
      resource_filter_report.(
        "result_wrapped",
        "result_wrapped_resource_filter_report_fixture",
        "tracking",
        "battery_margin_below_policy",
        "battery_1",
        "power"
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_resource_filter_report", direct_report)
      |> Map.put("resource_filter_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "resource_filter_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_resource_filter_report_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_resource_filter_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_resource_filter_report_boundary"}
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
          "mission_state.source_resource_filter_report",
          "mission_state.resource_filter_report",
          "mission_state.source_result_artifact.resource_filter_report",
          "mission_state.result_artifact.source_resource_filter_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_resource_filter_suppressed_candidate_count" => 4,
             "source_report_resource_filter_invalid_resource_summary_input_count" => 1,
             "source_report_resource_filter_invalid_resource_summary_input_ids" => [
               "direct_bad_resource_summary"
             ],
             "source_report_resource_filter_suppressed_reason_counts" => %{
               "antenna_unavailable" => 1,
               "battery_margin_below_policy" => 1,
               "payload_unavailable" => 1,
               "thermal_margin_below_policy" => 1
             },
             "source_report_resource_filter_candidate_ids_by_suppressed_reason" => %{
               "antenna_unavailable" => ["source_wrapped_obs_resource_block"],
               "battery_margin_below_policy" => ["result_wrapped_obs_resource_block"],
               "payload_unavailable" => ["direct_obs_resource_block"],
               "thermal_margin_below_policy" => ["canonical_obs_resource_block"]
             },
             "source_report_resource_filter_spacecraft_counts" => %{"leo_1" => 4},
             "source_report_resource_filter_resource_counts" => %{
               "antenna_1" => 1,
               "battery_1" => 1,
               "payload_1" => 1,
               "thermal_bus" => 1
             },
             "source_report_resource_filter_blocking_dimension_counts" => %{
               "antenna" => 1,
               "payload" => 1,
               "power" => 1,
               "thermal" => 1
             },
             "source_report_resource_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "slew" => 1,
               "tracking" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "resource_filter_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_paths" => replay_source_paths,
             "suppressed_candidate_count" => 4,
             "invalid_resource_summary_input_count" => 1,
             "invalid_resource_summary_input_ids" => ["direct_bad_resource_summary"],
             "suppressed_reason_counts" => %{
               "antenna_unavailable" => 1,
               "battery_margin_below_policy" => 1,
               "payload_unavailable" => 1,
               "thermal_margin_below_policy" => 1
             },
             "candidate_ids_by_suppressed_reason" => %{
               "antenna_unavailable" => ["source_wrapped_obs_resource_block"],
               "battery_margin_below_policy" => ["result_wrapped_obs_resource_block"],
               "payload_unavailable" => ["direct_obs_resource_block"],
               "thermal_margin_below_policy" => ["canonical_obs_resource_block"]
             },
             "resource_filter_spacecraft_counts" => %{"leo_1" => 4},
             "candidate_ids_by_spacecraft" => %{
               "leo_1" => [
                 "direct_obs_resource_block",
                 "canonical_obs_resource_block",
                 "source_wrapped_obs_resource_block",
                 "result_wrapped_obs_resource_block"
               ]
             },
             "resource_filter_resource_counts" => %{
               "antenna_1" => 1,
               "battery_1" => 1,
               "payload_1" => 1,
               "thermal_bus" => 1
             },
             "resource_filter_blocking_dimension_counts" => %{
               "antenna" => 1,
               "payload" => 1,
               "power" => 1,
               "thermal" => 1
             },
             "direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "slew" => 1,
               "tracking" => 1
             },
             "directions" => ["command", "downlink", "slew", "tracking"],
             "candidate_ids_by_direction" => %{
               "command" => ["source_wrapped_obs_resource_block"],
               "downlink" => ["direct_obs_resource_block"],
               "slew" => ["canonical_obs_resource_block"],
               "tracking" => ["result_wrapped_obs_resource_block"]
             },
             "direction_routing" => %{
               "command" => %{
                 "candidate_count" => 1,
                 "candidate_ids" => ["source_wrapped_obs_resource_block"]
               },
               "downlink" => %{
                 "candidate_count" => 1,
                 "candidate_ids" => ["direct_obs_resource_block"]
               },
               "slew" => %{
                 "candidate_count" => 1,
                 "candidate_ids" => ["canonical_obs_resource_block"]
               },
               "tracking" => %{
                 "candidate_count" => 1,
                 "candidate_ids" => ["result_wrapped_obs_resource_block"]
               }
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "canonical_resource_filter_report_boundary",
               "direct_resource_filter_report_boundary",
               "result_wrapped_resource_filter_report_boundary",
               "source_wrapped_resource_filter_report_boundary"
             ],
             "branch_local_resource_filter_pressure" => true,
             "branch_local_candidate_suppression_pressure" => true,
             "branch_local_invalid_resource_summary_pressure" => true,
             "branch_local_resource_blocking_pressure" => true
           } = CandidateRefresh.resource_filter_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.resource_filter_report",
             "mission_state.result_artifact.source_resource_filter_report",
             "mission_state.source_resource_filter_report",
             "mission_state.source_result_artifact.resource_filter_report"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
