Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceProjectionSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state resource-projection reports into branch refresh requests" do
    resource_projection_report = fn prefix,
                                    spacecraft_id,
                                    ground_station_id,
                                    status,
                                    pressure_types ->
      %{
        "schema_contract" => "resource_projection_report.v1",
        "source" => "campaign_planner_test.#{prefix}.resource_projection_report",
        "projected_resources" => [
          %{
            "spacecraft_id" => spacecraft_id,
            "resource_pressure_status" => status,
            "resource_pressure_types" => pressure_types,
            "source_activity_ids" => ["#{prefix}_activity"],
            "direction" => "downlink",
            "ground_station_id" => ground_station_id,
            "source_window_id" => "#{prefix}_source_window",
            "station_calendar_entry_id" => "#{prefix}_station_entry",
            "station_calendar_provider_entry_id" => "#{prefix}_provider_entry",
            "trust_boundary" => "#{prefix}_resource_projection_row_boundary"
          }
        ],
        "invalid_activity_inputs" => [%{"activity_id" => "#{prefix}_bad_activity"}],
        "invalid_resource_summary_inputs" => [
          %{"spacecraft_id" => "#{prefix}_bad_resource_summary"}
        ],
        "provenance" => %{
          "trust_boundary" => "#{prefix}_resource_projection_report_boundary"
        }
      }
    end

    direct_report =
      resource_projection_report.(
        "direct",
        "leo_1",
        "equator_prime",
        "downlink_shortfall",
        ["downlink_shortfall", "storage_pressure"]
      )

    canonical_report =
      resource_projection_report.(
        "canonical",
        "leo_4",
        "dss_14",
        "power_margin_low",
        ["power_margin_low"]
      )

    source_wrapped_report =
      resource_projection_report.(
        "source_wrapped",
        "leo_2",
        "dss_43",
        "storage_shortfall",
        ["storage_shortfall"]
      )

    result_wrapped_report =
      resource_projection_report.(
        "result_wrapped",
        "leo_3",
        "polar_prime",
        "thermal_margin_low",
        ["thermal_margin_low"]
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_resource_projection_report", direct_report)
      |> Map.put("resource_projection_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "resource_projection_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_resource_projection_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_resource_projection_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_resource_projection_boundary"}
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
          "mission_state.source_resource_projection_report",
          "mission_state.resource_projection_report",
          "mission_state.source_result_artifact.resource_projection_report",
          "mission_state.result_artifact.source_resource_projection_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 12,
             "source_report_resource_projection_projected_resource_count" => 4,
             "source_report_resource_projection_invalid_activity_input_count" => 4,
             "source_report_resource_projection_invalid_resource_summary_input_count" => 4,
             "source_report_resource_projection_resource_pressure_status_counts" => %{
               "downlink_shortfall" => 1,
               "power_margin_low" => 1,
               "storage_shortfall" => 1,
               "thermal_margin_low" => 1
             },
             "source_report_resource_projection_ground_station_counts" => %{
               "dss_14" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "source_report_resource_projection_spacecraft_counts" => %{
               "leo_1" => 1,
               "leo_2" => 1,
               "leo_3" => 1,
               "leo_4" => 1
             },
             "source_report_resource_projection_resource_pressure_activity_id_counts" => %{
               "canonical_activity" => 1,
               "direct_activity" => 1,
               "result_wrapped_activity" => 1,
               "source_wrapped_activity" => 1
             },
             "source_report_resource_projection_resource_pressure_direction_counts" => %{
               "downlink" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "resource_projection_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 12,
             "source_report_paths" => replay_source_paths,
             "projected_resource_count" => 4,
             "invalid_activity_input_count" => 4,
             "invalid_resource_summary_input_count" => 4,
             "resource_pressure_status_counts" => %{
               "downlink_shortfall" => 1,
               "power_margin_low" => 1,
               "storage_shortfall" => 1,
               "thermal_margin_low" => 1
             },
             "ground_station_counts" => %{
               "dss_14" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "resource_projection_spacecraft_counts" => %{
               "leo_1" => 1,
               "leo_2" => 1,
               "leo_3" => 1,
               "leo_4" => 1
             },
             "resource_pressure_activity_id_counts" => %{
               "canonical_activity" => 1,
               "direct_activity" => 1,
               "result_wrapped_activity" => 1,
               "source_wrapped_activity" => 1
             },
             "resource_pressure_activity_ids_by_direction" => %{
               "downlink" => [
                 "direct_activity",
                 "canonical_activity",
                 "source_wrapped_activity",
                 "result_wrapped_activity"
               ]
             },
             "invalid_activity_input_ids" => [
               "canonical_bad_activity",
               "direct_bad_activity",
               "result_wrapped_bad_activity",
               "source_wrapped_bad_activity"
             ],
             "invalid_resource_summary_input_ids" => [
               "canonical_bad_resource_summary",
               "direct_bad_resource_summary",
               "result_wrapped_bad_resource_summary",
               "source_wrapped_bad_resource_summary"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_resource_projection_pressure" => true,
             "branch_local_projected_resource_pressure" => true,
             "branch_local_invalid_resource_projection_pressure" => true,
             "branch_local_activity_pressure" => true,
             "assumptions" => %{
               "resource_projection" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.resource_projection_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.resource_projection_report",
             "mission_state.result_artifact.source_resource_projection_report",
             "mission_state.source_resource_projection_report",
             "mission_state.source_result_artifact.resource_projection_report"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_resource_projection_report_boundary",
             "canonical_resource_projection_row_boundary",
             "direct_resource_projection_report_boundary",
             "direct_resource_projection_row_boundary",
             "result_wrapped_resource_projection_boundary",
             "result_wrapped_resource_projection_row_boundary",
             "source_wrapped_resource_projection_boundary",
             "source_wrapped_resource_projection_row_boundary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
