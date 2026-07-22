Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactContentionSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state contact-contention reports into branch refresh requests" do
    contention_report = fn prefix, trust_boundary, direction, station_id, action ->
      %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "single_station_interval_overlap",
        "input_contact_count" => 2,
        "conflicted_contact_count" => 2,
        "conflict_group_count" => 1,
        "conflict_groups" => [
          %{
            "id" => "#{prefix}_contention_group",
            "resource_scope" => "ground_station",
            "ground_station_id" => station_id,
            "direction" => direction,
            "directions" => [direction],
            "contact_ids" => ["#{prefix}_primary", "#{prefix}_backup"],
            "source_contact_candidates" => [
              %{"id" => "#{prefix}_primary", "direction" => direction},
              %{"id" => "#{prefix}_backup", "direction" => direction}
            ],
            "required_operator_action" => action,
            "trust_boundary" => "#{prefix}_contention_group_boundary"
          }
        ],
        "provenance" => %{"trust_boundary" => trust_boundary}
      }
    end

    direct_report =
      contention_report.(
        "direct",
        "direct_contact_contention_report_boundary",
        "downlink",
        "equator_prime",
        "review_contact_contention"
      )
      |> Map.put("invalid_contact_inputs", [
        %{
          "contact_id" => "direct_missing_station",
          "required_operator_action" => "review_invalid_contact_contention_input"
        }
      ])

    canonical_report =
      contention_report.(
        "canonical",
        "canonical_contact_contention_report_boundary",
        "uplink",
        "canberra_deep",
        "review_contact_contention"
      )

    source_wrapped_report =
      contention_report.(
        "source_wrapped",
        "source_wrapped_contact_contention_fixture",
        "s-band command",
        "dss_43",
        "review_contact_contention"
      )

    result_wrapped_report =
      contention_report.(
        "result_wrapped",
        "result_wrapped_contact_contention_fixture",
        "tracking",
        "polar_prime",
        "review_partner_contact_contention"
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_contention_report", direct_report)
      |> Map.put("contact_contention_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "contact_contention_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_contact_contention_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_contention_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_contact_contention_boundary"}
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
          "mission_state.source_contact_contention_report",
          "mission_state.contact_contention_report",
          "mission_state.source_result_artifact.contact_contention_report",
          "mission_state.result_artifact.source_contact_contention_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_contact_contention_conflict_group_count" => 4,
             "source_report_contact_contention_invalid_contact_input_count" => 1,
             "source_report_contact_contention_invalid_contact_input_ids" => [
               "direct_missing_station"
             ],
             "source_report_contact_contention_resource_scope_counts" => %{
               "ground_station" => 4
             },
             "source_report_contact_contention_ground_station_counts" => %{
               "canberra_deep" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "source_report_contact_contention_direction_counts" => %{
               "command" => 2,
               "downlink" => 2,
               "tracking" => 2,
               "uplink" => 2
             },
             "source_report_contact_contention_required_operator_action_counts" => %{
               "review_contact_contention" => 3,
               "review_invalid_contact_contention_input" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "contact_contention_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_paths" => replay_source_paths,
             "conflict_group_count" => 4,
             "invalid_contact_input_count" => 1,
             "invalid_contact_input_ids" => ["direct_missing_station"],
             "resource_scope_counts" => %{"ground_station" => 4},
             "contact_contention_ground_station_counts" => %{
               "canberra_deep" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "contact_contention_contact_id_counts" => %{
               "canonical_backup" => 1,
               "canonical_primary" => 1,
               "direct_backup" => 1,
               "direct_primary" => 1,
               "result_wrapped_backup" => 1,
               "result_wrapped_primary" => 1,
               "source_wrapped_backup" => 1,
               "source_wrapped_primary" => 1
             },
             "direction_counts" => %{
               "command" => 2,
               "downlink" => 2,
               "tracking" => 2,
               "uplink" => 2
             },
             "contact_ids_by_direction" => %{
               "command" => ["source_wrapped_backup", "source_wrapped_primary"],
               "downlink" => ["direct_backup", "direct_primary"],
               "tracking" => ["result_wrapped_backup", "result_wrapped_primary"],
               "uplink" => ["canonical_backup", "canonical_primary"]
             },
             "direction_routing" => %{
               "command" => %{
                 "contact_count" => 2,
                 "contact_ids" => ["source_wrapped_backup", "source_wrapped_primary"]
               },
               "downlink" => %{
                 "contact_count" => 2,
                 "contact_ids" => ["direct_backup", "direct_primary"]
               },
               "tracking" => %{
                 "contact_count" => 2,
                 "contact_ids" => ["result_wrapped_backup", "result_wrapped_primary"]
               },
               "uplink" => %{
                 "contact_count" => 2,
                 "contact_ids" => ["canonical_backup", "canonical_primary"]
               }
             },
             "required_operator_action_counts" => %{
               "review_contact_contention" => 3,
               "review_invalid_contact_contention_input" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "canonical_contact_contention_report_boundary",
               "canonical_contention_group_boundary",
               "direct_contact_contention_report_boundary",
               "direct_contention_group_boundary",
               "result_wrapped_contact_contention_boundary",
               "result_wrapped_contention_group_boundary",
               "source_wrapped_contact_contention_boundary",
               "source_wrapped_contention_group_boundary"
             ],
             "branch_local_contact_contention_pressure" => true,
             "branch_local_contact_contention_conflict_pressure" => true,
             "branch_local_invalid_contact_input_pressure" => true,
             "branch_local_contact_contention_review_pressure" => true
           } = CandidateRefresh.contact_contention_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.contact_contention_report",
             "mission_state.result_artifact.source_contact_contention_report",
             "mission_state.source_contact_contention_report",
             "mission_state.source_result_artifact.contact_contention_report"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
