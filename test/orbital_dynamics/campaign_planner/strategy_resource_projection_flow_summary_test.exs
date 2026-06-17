Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceProjectionFlowSummaryTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh

  test "strategy carries mission-state resource-projection flow summaries into branch refresh requests" do
    direct_summary = resource_projection_flow_summary_fixture("direct")
    canonical_summary = resource_projection_flow_summary_fixture("canonical")
    wrapped_summary = resource_projection_flow_summary_fixture("wrapped")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_resource_projection_flow_summary", direct_summary)
      |> Map.put("resource_projection_flow_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_resource_projection_flow_summary" => Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_resource_projection_flow_boundary"}
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

    assert "mission_state.source_resource_projection_flow_summary" in source_report_input_paths

    assert "mission_state.resource_projection_flow_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.source_resource_projection_flow_summary" in source_report_input_paths

    assert "mission_state.source_resource_projection_flow_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.resource_projection_flow_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source_report_resource_projection_projected_resource_count" => 6,
             "source_report_resource_projection_invalid_activity_input_count" => 3,
             "source_report_resource_projection_invalid_resource_summary_input_count" => 3,
             "source_report_resource_projection_invalid_activity_input_ids" => [
               "canonical_bad_activity",
               "direct_bad_activity",
               "wrapped_bad_activity"
             ],
             "source_report_resource_projection_invalid_resource_summary_input_ids" => [
               "canonical_bad_resource_summary",
               "direct_bad_resource_summary",
               "wrapped_bad_resource_summary"
             ],
             "source_report_resource_projection_resource_pressure_status_counts" => %{
               "downlink_shortfall" => 3,
               "storage_shortfall" => 3
             },
             "source_report_resource_projection_ground_station_counts" => %{
               "dss_43" => 3,
               "equator_prime" => 3
             },
             "source_report_resource_projection_spacecraft_counts" => %{
               "leo_1" => 3,
               "leo_2" => 3
             },
             "source_report_resource_projection_resource_pressure_type_counts" => %{
               "downlink_shortfall" => 3,
               "storage_pressure" => 3,
               "storage_shortfall" => 3
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 12,
             "source_report_paths" => replay_source_paths,
             "projected_resource_count" => 6,
             "invalid_activity_input_count" => 3,
             "invalid_resource_summary_input_count" => 3,
             "resource_pressure_status_counts" => %{
               "downlink_shortfall" => 3,
               "storage_shortfall" => 3
             },
             "ground_station_counts" => %{"dss_43" => 3, "equator_prime" => 3},
             "resource_projection_spacecraft_counts" => %{"leo_1" => 3, "leo_2" => 3},
             "resource_pressure_type_counts" => %{
               "downlink_shortfall" => 3,
               "storage_pressure" => 3,
               "storage_shortfall" => 3
             },
             "resource_pressure_activity_ids_by_direction" => %{
               "downlink" => [
                 "direct_dl_pressure",
                 "canonical_dl_pressure",
                 "wrapped_dl_pressure"
               ],
               "tracking" => [
                 "direct_imaging_1",
                 "direct_imaging_2",
                 "canonical_imaging_1",
                 "canonical_imaging_2",
                 "wrapped_imaging_1",
                 "wrapped_imaging_2"
               ]
             },
             "resource_pressure_ground_station_ids_by_type" => %{
               "downlink_shortfall" => ["equator_prime"],
               "storage_pressure" => ["equator_prime"],
               "storage_shortfall" => ["dss_43"]
             },
             "invalid_activity_input_ids" => [
               "canonical_bad_activity",
               "direct_bad_activity",
               "wrapped_bad_activity"
             ],
             "invalid_resource_summary_input_ids" => [
               "canonical_bad_resource_summary",
               "direct_bad_resource_summary",
               "wrapped_bad_resource_summary"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "canonical_resource_projection_flow_fixture",
               "direct_resource_projection_flow_fixture",
               "wrapped_resource_projection_flow_boundary"
             ],
             "branch_local_resource_projection_pressure" => true,
             "branch_local_projected_resource_pressure" => true,
             "branch_local_invalid_resource_projection_pressure" => true,
             "branch_local_activity_pressure" => true
           } = CandidateRefresh.resource_projection_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.resource_projection_flow_summary",
          "mission_state.source_resource_projection_flow_summary",
          "mission_state.source_result_artifact.source_resource_projection_flow_summary"
        ] do
      assert source_path in replay_source_paths
    end
  end

  defp resource_projection_flow_summary_fixture(prefix) do
    %{
      "schema_contract" => "resource_projection_flow_summary.v1",
      "model" => "artifact_only_resource_projection_flow_summary",
      "source" => "campaign_planner_test.#{prefix}.resource_projection_flow_summary",
      "projected_resource_count" => 2,
      "invalid_activity_input_count" => 1,
      "invalid_resource_summary_input_count" => 1,
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall", "storage_pressure"],
          "first_resource_pressure_activity_id" => "#{prefix}_dl_pressure",
          "first_resource_pressure_direction" => "Down Link",
          "first_resource_pressure_ground_station_id" => "equator_prime",
          "source_window_id" => "#{prefix}_flow_access_window",
          "station_calendar_entry_id" => "#{prefix}_station_flow_window",
          "station_calendar_provider_entry_id" => "#{prefix}_provider_flow_window"
        },
        %{
          "spacecraft_id" => "leo_2",
          "resource_pressure_status" => "storage_shortfall",
          "resource_pressure_types" => ["storage_shortfall"],
          "source_activity_ids" => ["#{prefix}_imaging_1", "#{prefix}_imaging_2"],
          "direction" => "tracking_pass",
          "ground_station_id" => "dss_43",
          "source_window" => %{"id" => "#{prefix}_tracking_window"},
          "source_station_calendar_entry" => %{
            "station_calendar_entry_id" => "#{prefix}_station_tracking_window",
            "station_calendar_provider_entry_id" => "#{prefix}_provider_tracking_window"
          }
        }
      ],
      "invalid_activity_inputs" => [%{"activity_id" => "#{prefix}_bad_activity"}],
      "invalid_resource_summary_inputs" => [
        %{"spacecraft_id" => "#{prefix}_bad_resource_summary"}
      ],
      "provenance" => %{"trust_boundary" => "#{prefix}_resource_projection_flow_fixture"}
    }
  end
end
