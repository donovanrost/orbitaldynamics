Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactFilterSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state contact-filter reports into branch refresh requests" do
    direct_report = %{
      "schema_contract" => "contact_filter_report.v1",
      "model" => "artifact_only_contact_filter_report",
      "suppressed_candidates" => [
        %{
          "id" => "direct_reserved",
          "direction" => "downlink",
          "ground_station_id" => "equator_prime",
          "station_calendar_entry_id" => "direct_entry",
          "station_calendar_provider_entry_id" => "direct_provider_entry",
          "station_reservation_id" => "direct_reservation",
          "suppressed_reason" => "ground_station_reserved"
        },
        %{
          "id" => "direct_invalid",
          "direction" => "health-check",
          "suppressed_reason" => "invalid_contact_input"
        }
      ],
      "provenance" => %{"trust_boundary" => "direct_contact_filter_boundary"}
    }

    canonical_report = %{
      "schema_contract" => "contact_filter_report.v1",
      "model" => "artifact_only_contact_filter_report",
      "suppressed_candidates" => [
        %{
          "id" => "canonical_capacity",
          "direction" => "imaging",
          "ground_station_id" => "dss_14",
          "station_calendar_entry_id" => "canonical_entry",
          "station_calendar_provider_entry_id" => "canonical_provider_entry",
          "suppressed_reason" => "ground_station_capacity_zero"
        }
      ],
      "provenance" => %{"trust_boundary" => "canonical_contact_filter_boundary"}
    }

    source_wrapped_report = %{
      "schema_contract" => "contact_filter_report.v1",
      "model" => "artifact_only_contact_filter_report",
      "suppressed_candidates" => [
        %{
          "id" => "source_wrapped_unavailable",
          "direction" => "command",
          "ground_station_id" => "dss_43",
          "station_calendar_entry_id" => "source_wrapped_entry",
          "station_calendar_provider_entry_id" => "source_wrapped_provider_entry",
          "suppressed_reason" => "ground_station_unavailable"
        }
      ],
      "provenance" => %{"trust_boundary" => "source_wrapped_contact_filter_boundary"}
    }

    result_wrapped_report = %{
      "schema_contract" => "contact_filter_report.v1",
      "model" => "artifact_only_contact_filter_report",
      "suppressed_candidates" => [
        %{
          "id" => "result_wrapped_capacity",
          "direction" => "tracking",
          "ground_station_id" => "polar_prime",
          "station_calendar_entry_id" => "result_wrapped_entry",
          "station_calendar_provider_entry_id" => "result_wrapped_provider_entry",
          "suppressed_reason" => "ground_station_capacity_zero"
        }
      ],
      "provenance" => %{"trust_boundary" => "result_wrapped_contact_filter_boundary"}
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_filter_report", direct_report)
      |> Map.put("contact_filter_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "contact_filter_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_contact_filter_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_filter_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_contact_filter_boundary"}
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
          "mission_state.source_contact_filter_report",
          "mission_state.contact_filter_report",
          "mission_state.source_result_artifact.contact_filter_report",
          "mission_state.result_artifact.source_contact_filter_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_contact_filter_suppressed_candidate_count" => 5,
             "source_report_contact_filter_invalid_contact_input_count" => 1,
             "source_report_contact_filter_invalid_contact_input_ids" => ["direct_invalid"],
             "source_report_contact_filter_suppressed_reason_counts" => %{
               "ground_station_capacity_zero" => 2,
               "ground_station_reserved" => 1,
               "ground_station_unavailable" => 1,
               "invalid_contact_input" => 1
             },
             "source_report_contact_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "health_check" => 1,
               "imaging" => 1,
               "tracking" => 1
             },
             "source_report_contact_filter_station_suppression_count" => 4,
             "source_report_contact_filter_station_suppression_ground_station_counts" => %{
               "dss_14" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "source_report_contact_filter_station_suppression_availability_counts" => %{
               "reduced_capacity" => 2,
               "reserved" => 1,
               "unavailable" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "contact_filter_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_paths" => replay_source_paths,
             "suppressed_candidate_count" => 5,
             "invalid_contact_input_count" => 1,
             "invalid_contact_input_ids" => ["direct_invalid"],
             "suppressed_reason_counts" => %{
               "ground_station_capacity_zero" => 2,
               "ground_station_reserved" => 1,
               "ground_station_unavailable" => 1,
               "invalid_contact_input" => 1
             },
             "direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "health_check" => 1,
               "imaging" => 1,
               "tracking" => 1
             },
             "directions" => ["command", "downlink", "health_check", "imaging", "tracking"],
             "station_suppression_count" => 4,
             "station_suppression_ground_station_counts" => %{
               "dss_14" => 1,
               "dss_43" => 1,
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "station_suppression_availability_counts" => %{
               "reduced_capacity" => 2,
               "reserved" => 1,
               "unavailable" => 1
             },
             "trust_boundary_status" => "declared",
             "branch_local_contact_filter_pressure" => true,
             "branch_local_candidate_suppression_pressure" => true,
             "branch_local_invalid_contact_input_pressure" => true,
             "branch_local_station_suppression_pressure" => true
           } = CandidateRefresh.contact_filter_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.contact_filter_report",
             "mission_state.result_artifact.source_contact_filter_report",
             "mission_state.source_contact_filter_report",
             "mission_state.source_result_artifact.contact_filter_report"
           ]

    contact_filter_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and
            &1["feedback_source"] == "candidate_source.contact_filter_replay_summary")
      )

    assert contact_filter_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_filter" and
                 &1["suppressed_candidate_count"] == 5 and
                 &1["invalid_contact_input_count"] == 1 and
                 &1["invalid_contact_input_ids"] == ["direct_invalid"] and
                 &1["station_suppression_count"] == 4 and
                 &1["suppressed_reason_counts"] == %{
                   "ground_station_capacity_zero" => 2,
                   "ground_station_reserved" => 1,
                   "ground_station_unavailable" => 1,
                   "invalid_contact_input" => 1
                 } and
                 &1["directions"] == [
                   "command",
                   "downlink",
                   "health_check",
                   "imaging",
                   "tracking"
                 ] and
                 &1["ground_station_ids"] == [
                   "dss_14",
                   "dss_43",
                   "equator_prime",
                   "polar_prime"
                 ] and
                 &1["station_availabilities"] == [
                   "reduced_capacity",
                   "reserved",
                   "unavailable"
                 ])
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["contact_filter_pressure_penalty"] ==
             -contact_filter_pressure_count * risk_weight

    assert "contact_filter_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "contact_filter_pressure_penalty" and &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
