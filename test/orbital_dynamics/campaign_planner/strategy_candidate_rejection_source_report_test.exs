Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyCandidateRejectionSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state candidate-rejection reports into branch refresh requests" do
    direct_report = %{
      "schema_contract" => "candidate_rejection_report.v1",
      "rejected_count" => 2,
      "reviewable_count" => 1,
      "invalid_candidate_input_count" => 1,
      "rows" => [
        %{
          "id" => "candidate_rejection:direct_reserved_candidate",
          "candidate_id" => "direct_reserved_candidate",
          "ground_station_id" => "equator_prime",
          "rejection_reasons" => ["station_reserved"],
          "primary_rejection_reason" => "station_reserved",
          "required_operator_action" => "review_candidate_rejection",
          "trust_boundary" => "direct_reserved_candidate_boundary"
        },
        %{
          "id" => "candidate_rejection:direct_invalid_candidate",
          "candidate_id" => "direct_invalid_candidate",
          "activity_context" => %{"ground_station_id" => "dss_43"},
          "rejection_reasons" => ["invalid_candidate_input"],
          "primary_rejection_reason" => "invalid_candidate_input",
          "required_operator_action" => "none",
          "trust_boundary" => "direct_invalid_candidate_boundary"
        }
      ],
      "provenance" => %{"trust_boundary" => "direct_candidate_rejection_report_boundary"}
    }

    canonical_report = %{
      "schema_contract" => "candidate_rejection_report.v1",
      "rejected_count" => 1,
      "reviewable_count" => 1,
      "invalid_candidate_input_count" => 0,
      "rows" => [
        %{
          "id" => "candidate_rejection:canonical_weather_candidate",
          "candidate_id" => "canonical_weather_candidate",
          "ground_station_id" => "dss_14",
          "rejection_reasons" => ["weather_outage"],
          "primary_rejection_reason" => "weather_outage",
          "required_operator_action" => "review_candidate_rejection",
          "trust_boundary" => "canonical_weather_candidate_boundary"
        }
      ],
      "provenance" => %{"trust_boundary" => "canonical_candidate_rejection_report_boundary"}
    }

    source_wrapped_report = %{
      "schema_contract" => "candidate_rejection_report.v1",
      "rejected_count" => 1,
      "reviewable_count" => 1,
      "invalid_candidate_input_count" => 1,
      "rows" => [
        %{
          "id" => "candidate_rejection:source_wrapped_maintenance_candidate",
          "candidate_id" => "source_wrapped_maintenance_candidate",
          "ground_station_id" => "dss_43",
          "rejection_reasons" => ["station_maintenance"],
          "primary_rejection_reason" => "station_maintenance",
          "required_operator_action" => "review_candidate_rejection",
          "trust_boundary" => "source_wrapped_maintenance_candidate_boundary"
        }
      ],
      "provenance" => %{"trust_boundary" => "source_wrapped_candidate_rejection_fixture"}
    }

    result_wrapped_report = %{
      "schema_contract" => "candidate_rejection_report.v1",
      "rejected_count" => 1,
      "reviewable_count" => 0,
      "invalid_candidate_input_count" => 0,
      "rows" => [
        %{
          "id" => "candidate_rejection:result_wrapped_short_candidate",
          "candidate_id" => "result_wrapped_short_candidate",
          "ground_station_id" => "polar_prime",
          "rejection_reasons" => ["contact_too_short"],
          "primary_rejection_reason" => "contact_too_short",
          "required_operator_action" => "none",
          "trust_boundary" => "result_wrapped_short_candidate_boundary"
        }
      ],
      "provenance" => %{"trust_boundary" => "result_wrapped_candidate_rejection_fixture"}
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_candidate_rejection_report", direct_report)
      |> Map.put("candidate_rejection_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "candidate_rejection_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_candidate_rejection_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_candidate_rejection_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_candidate_rejection_boundary"}
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
          "mission_state.source_candidate_rejection_report",
          "mission_state.candidate_rejection_report",
          "mission_state.source_result_artifact.candidate_rejection_report",
          "mission_state.result_artifact.source_candidate_rejection_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_candidate_rejection_rejected_count" => 5,
             "source_report_candidate_rejection_reviewable_count" => 3,
             "source_report_candidate_rejection_invalid_candidate_input_count" => 2,
             "source_report_candidate_rejection_rejection_reason_counts" => %{
               "contact_too_short" => 1,
               "invalid_candidate_input" => 1,
               "station_maintenance" => 1,
               "station_reserved" => 1,
               "weather_outage" => 1
             },
             "source_report_candidate_rejection_required_operator_action_counts" => %{
               "none" => 2,
               "review_candidate_rejection" => 3
             },
             "source_report_candidate_rejection_candidate_id_counts" => %{
               "canonical_weather_candidate" => 1,
               "direct_invalid_candidate" => 1,
               "direct_reserved_candidate" => 1,
               "result_wrapped_short_candidate" => 1,
               "source_wrapped_maintenance_candidate" => 1
             },
             "source_report_candidate_rejection_ground_station_counts" => %{
               "dss_14" => 1,
               "dss_43" => 2,
               "equator_prime" => 1,
               "polar_prime" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "candidate_rejection_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_paths" => replay_source_paths,
             "rejected_count" => 5,
             "reviewable_count" => 3,
             "invalid_candidate_input_count" => 2,
             "rejection_reason_counts" => %{
               "contact_too_short" => 1,
               "invalid_candidate_input" => 1,
               "station_maintenance" => 1,
               "station_reserved" => 1,
               "weather_outage" => 1
             },
             "required_operator_action_counts" => %{
               "none" => 2,
               "review_candidate_rejection" => 3
             },
             "candidate_rejection_candidate_id_counts" => %{
               "canonical_weather_candidate" => 1,
               "direct_invalid_candidate" => 1,
               "direct_reserved_candidate" => 1,
               "result_wrapped_short_candidate" => 1,
               "source_wrapped_maintenance_candidate" => 1
             },
             "candidate_rejection_ground_station_counts" => %{
               "dss_14" => 1,
               "dss_43" => 2,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "canonical_candidate_rejection_report_boundary",
               "canonical_weather_candidate_boundary",
               "direct_candidate_rejection_report_boundary",
               "direct_invalid_candidate_boundary",
               "direct_reserved_candidate_boundary",
               "result_wrapped_short_candidate_boundary",
               "source_wrapped_maintenance_candidate_boundary"
             ],
             "branch_local_rejection_pressure" => true,
             "branch_local_review_pressure" => true,
             "branch_local_invalid_input_pressure" => true
           } = CandidateRefresh.candidate_rejection_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.candidate_rejection_report",
             "mission_state.result_artifact.source_candidate_rejection_report",
             "mission_state.source_candidate_rejection_report",
             "mission_state.source_result_artifact.candidate_rejection_report"
           ]

    candidate_rejection_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "candidate_rejection_pressure" and
            &1["feedback_source"] == "candidate_source.candidate_rejection_replay_summary")
      )

    assert candidate_rejection_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "candidate_rejection_pressure" and
                 &1["feedback_scope"] == "candidate_rejection" and
                 &1["rejected_count"] == 5 and
                 &1["reviewable_count"] == 3 and
                 &1["invalid_candidate_input_count"] == 2 and
                 &1["rejection_reason_counts"] == %{
                   "contact_too_short" => 1,
                   "invalid_candidate_input" => 1,
                   "station_maintenance" => 1,
                   "station_reserved" => 1,
                   "weather_outage" => 1
                 } and
                 &1["required_operator_action_counts"] == %{
                   "none" => 2,
                   "review_candidate_rejection" => 3
                 } and
                 &1["candidate_ids"] == [
                   "canonical_weather_candidate",
                   "direct_invalid_candidate",
                   "direct_reserved_candidate",
                   "result_wrapped_short_candidate",
                   "source_wrapped_maintenance_candidate"
                 ] and
                 &1["ground_station_ids"] == [
                   "dss_14",
                   "dss_43",
                   "equator_prime",
                   "polar_prime"
                 ])
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["candidate_rejection_pressure_penalty"] ==
             -candidate_rejection_pressure_count * risk_weight

    assert "candidate_rejection_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "candidate_rejection_pressure_penalty" and &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
