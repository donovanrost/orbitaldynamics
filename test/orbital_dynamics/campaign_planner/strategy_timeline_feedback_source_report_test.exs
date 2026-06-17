Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineFeedbackSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state timeline feedback and operational timeline reports into branch refresh requests" do
    timeline_feedback_report = fn prefix, status, feedback_kind ->
      %{
        "schema_contract" => "timeline_feedback_report.v1",
        "source" => "campaign_planner_test.#{prefix}.timeline_feedback_report",
        "operational_feedback" => %{
          "station_throughput_factor" => %{"equator_prime" => 0.5},
          "downlink_demand_mb" => %{"equator_prime" => 120.0}
        },
        "rows" => [
          %{
            "activity_id" => "#{prefix}_feedback_activity",
            "status" => status,
            "feedback_kind" => feedback_kind,
            "match_strategy" => "activity_id",
            "cadence_import_status" => "present"
          }
        ],
        "provenance" => %{
          "trust_boundary" => "#{prefix}_timeline_feedback_boundary"
        }
      }
    end

    operational_timeline_report = fn prefix, operational_kind, status ->
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "source" => "campaign_planner_test.#{prefix}.operational_timeline_report",
        "rows" => [
          %{
            "id" => "timeline_row:#{prefix}_timeline_activity",
            "activity_id" => "#{prefix}_timeline_activity",
            "activity_type" => if(operational_kind == "command", do: "command", else: "downlink"),
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0,
            "timeline_id" => "timeline:leo_1:#{prefix}_timeline_activity",
            "ground_station_id" => "equator_prime",
            "direction" => if(operational_kind == "command", do: "uplink", else: "downlink"),
            "operational_kind" => operational_kind,
            "status" => status,
            "approval_status" => "review_required",
            "required_operator_action" => "review_#{prefix}_timeline",
            "cadence_import_status" => "review",
            "command_success_factor" => if(operational_kind == "command", do: 0.4, else: nil),
            "contact_success_factor" => if(operational_kind == "contact", do: 0.6, else: nil),
            "actual_throughput_mb" => if(operational_kind == "contact", do: 30.0, else: nil),
            "estimated_throughput_mb" => if(operational_kind == "contact", do: 100.0, else: nil)
          }
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> Map.new()
        ],
        "provenance" => %{
          "trust_boundary" => "#{prefix}_operational_timeline_boundary"
        }
      }
    end

    direct_feedback = timeline_feedback_report.("direct", "matched", "contact")
    canonical_feedback = timeline_feedback_report.("canonical", "applied", "command")
    wrapped_feedback = timeline_feedback_report.("wrapped", "review_required", "command")
    direct_timeline = operational_timeline_report.("direct", "command", "planned")
    canonical_timeline = operational_timeline_report.("canonical", "command", "approved")
    wrapped_timeline = operational_timeline_report.("wrapped", "contact", "partial")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_feedback_report", direct_feedback)
      |> Map.put("timeline_feedback_report", canonical_feedback)
      |> Map.put("source_operational_timeline_report", direct_timeline)
      |> Map.put("operational_timeline_report", canonical_timeline)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_feedback_report" => Map.delete(wrapped_feedback, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_timeline_feedback_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "operational_timeline_report" => Map.delete(wrapped_timeline, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_operational_timeline_boundary"}
      })

    artifact =
      strategy(base_plan(%{"activities" => [downlink("dl_1", 100.0, 160.0)]}),
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

    for source_path <- [
          "source_timeline_feedback_report",
          "timeline_feedback_report",
          "mission_state.source_result_artifact.timeline_feedback_report",
          "source_operational_timeline_report",
          "operational_timeline_report",
          "mission_state.result_artifact.operational_timeline_report"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 6,
             "source_report_row_count" => 6,
             "source_reports" => %{
               "timeline_feedback_report" => %{
                 "count" => 3,
                 "row_count" => 3,
                 "status_counts" => %{
                   "applied" => 1,
                   "matched" => 1,
                   "review_required" => 1
                 },
                 "feedback_kind_counts" => %{"command" => 2, "contact" => 1},
                 "match_strategy_counts" => %{"activity_id" => 3},
                 "cadence_import_status_counts" => %{"present" => 3}
               },
               "operational_timeline_report" => %{
                 "count" => 3,
                 "row_count" => 3,
                 "contact_feedback_count" => 1,
                 "command_feedback_count" => 2,
                 "station_throughput_feedback_count" => 1,
                 "operational_kind_counts" => %{"command" => 2, "contact" => 1},
                 "activity_status_counts" => %{
                   "approved" => 1,
                   "partial" => 1,
                   "planned" => 1
                 },
                 "approval_status_counts" => %{"review_required" => 3},
                 "cadence_import_status_counts" => %{"review" => 3}
               }
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_feedback_report",
             "contract" => "timeline_feedback_report.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => timeline_feedback_source_paths,
             "status_counts" => %{
               "applied" => 1,
               "matched" => 1,
               "review_required" => 1
             },
             "feedback_kind_counts" => %{"command" => 2, "contact" => 1},
             "match_strategy_counts" => %{"activity_id" => 3},
             "cadence_import_status_counts" => %{"present" => 3},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => timeline_feedback_trust_boundaries,
             "branch_local_timeline_feedback_pressure" => true,
             "branch_local_activity_routing_pressure" => true,
             "branch_local_match_review_pressure" => true,
             "branch_local_import_review_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "timeline_feedback_candidate_source_report_summary_only",
               "operational_feedback_application" => "not_performed_by_summary",
               "timeline_mutation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.timeline_feedback_replay_summary(candidate_source)

    assert Enum.sort(timeline_feedback_source_paths) == [
             "mission_state.source_result_artifact.timeline_feedback_report",
             "source_timeline_feedback_report",
             "timeline_feedback_report"
           ]

    assert Enum.sort(timeline_feedback_trust_boundaries) == [
             "canonical_timeline_feedback_boundary",
             "direct_timeline_feedback_boundary",
             "wrapped_timeline_feedback_boundary"
           ]

    timeline_feedback_pressure_risks =
      Enum.filter(
        urgent["risk_indicators"],
        &(&1["type"] == "timeline_feedback_pressure" and
            &1["feedback_source"] == "candidate_source.timeline_feedback_replay_summary")
      )

    assert length(timeline_feedback_pressure_risks) == 1

    timeline_feedback_pressure_risk = List.first(timeline_feedback_pressure_risks)

    assert timeline_feedback_pressure_risk["contract"] == "timeline_feedback_report.v1"
    assert timeline_feedback_pressure_risk["source_report_count"] == 3
    assert timeline_feedback_pressure_risk["source_report_row_count"] == 3

    assert Enum.sort(timeline_feedback_pressure_risk["source_report_paths"]) == [
             "mission_state.source_result_artifact.timeline_feedback_report",
             "source_timeline_feedback_report",
             "timeline_feedback_report"
           ]

    assert timeline_feedback_pressure_risk["status_counts"] == %{
             "applied" => 1,
             "matched" => 1,
             "review_required" => 1
           }

    assert timeline_feedback_pressure_risk["feedback_kind_counts"] == %{
             "command" => 2,
             "contact" => 1
           }

    assert timeline_feedback_pressure_risk["match_strategy_counts"] == %{
             "activity_id" => 3
           }

    assert timeline_feedback_pressure_risk["cadence_import_status_counts"] == %{
             "present" => 3
           }

    assert Enum.sort(timeline_feedback_pressure_risk["trust_boundaries"]) == [
             "canonical_timeline_feedback_boundary",
             "direct_timeline_feedback_boundary",
             "wrapped_timeline_feedback_boundary"
           ]

    assert timeline_feedback_pressure_risk["assumptions"]["timeline_mutation"] ==
             "not_performed_by_summary"

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["timeline_feedback_pressure_penalty"] ==
             -length(timeline_feedback_pressure_risks) * risk_weight

    assert "timeline_feedback_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "urgent" and
                 &1["term_key"] == "timeline_feedback_pressure_penalty" and &1["value"] < 0.0)
           )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "timeline_feedback_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_timeline_feedback_source_report_paths"] == [
             "mission_state.source_result_artifact.timeline_feedback_report",
             "source_timeline_feedback_report",
             "timeline_feedback_report"
           ]

    assert urgent_row["branch_timeline_feedback_statuses"] == [
             "applied",
             "matched",
             "review_required"
           ]

    assert urgent_row["branch_timeline_feedback_kinds"] == ["command", "contact"]
    assert urgent_row["branch_timeline_feedback_match_strategies"] == ["activity_id"]
    assert urgent_row["branch_timeline_feedback_import_statuses"] == ["present"]

    assert urgent_row["branch_timeline_feedback_trust_boundaries"] == [
             "canonical_timeline_feedback_boundary",
             "direct_timeline_feedback_boundary",
             "wrapped_timeline_feedback_boundary"
           ]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_timeline_report",
             "contract" => "operational_timeline_report.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => operational_timeline_source_paths,
             "contact_feedback_count" => 1,
             "command_feedback_count" => 2,
             "station_throughput_feedback_count" => 1,
             "operational_kind_counts" => %{"command" => 2, "contact" => 1},
             "activity_status_counts" => %{
               "approved" => 1,
               "partial" => 1,
               "planned" => 1
             },
             "approval_status_counts" => %{"review_required" => 3},
             "cadence_import_status_counts" => %{"review" => 3},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => operational_timeline_trust_boundaries,
             "branch_local_operational_timeline_pressure" => true,
             "branch_local_feedback_pressure" => true,
             "branch_local_activity_routing_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "operational_timeline_candidate_source_report_summary_only",
               "operational_feedback_application" => "not_performed_by_summary",
               "timeline_mutation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.operational_timeline_replay_summary(candidate_source)

    assert Enum.sort(operational_timeline_source_paths) == [
             "mission_state.result_artifact.operational_timeline_report",
             "operational_timeline_report",
             "source_operational_timeline_report"
           ]

    assert Enum.sort(operational_timeline_trust_boundaries) == [
             "canonical_operational_timeline_boundary",
             "direct_operational_timeline_boundary",
             "wrapped_operational_timeline_boundary"
           ]

    operational_timeline_pressure_risks =
      Enum.filter(
        urgent["risk_indicators"],
        &(&1["type"] == "operational_timeline_pressure" and
            &1["feedback_source"] == "candidate_source.operational_timeline_replay_summary")
      )

    assert length(operational_timeline_pressure_risks) == 1

    operational_timeline_pressure_risk = List.first(operational_timeline_pressure_risks)

    assert operational_timeline_pressure_risk["contract"] == "operational_timeline_report.v1"
    assert operational_timeline_pressure_risk["source_report_count"] == 3
    assert operational_timeline_pressure_risk["source_report_row_count"] == 3
    assert operational_timeline_pressure_risk["contact_feedback_count"] == 1
    assert operational_timeline_pressure_risk["command_feedback_count"] == 2
    assert operational_timeline_pressure_risk["station_throughput_feedback_count"] == 1

    assert Enum.sort(operational_timeline_pressure_risk["source_report_paths"]) == [
             "mission_state.result_artifact.operational_timeline_report",
             "operational_timeline_report",
             "source_operational_timeline_report"
           ]

    assert Enum.sort(operational_timeline_pressure_risk["input_keys"]) == [
             "command_success_rate",
             "contact_success_rate",
             "station_throughput_factor"
           ]

    assert operational_timeline_pressure_risk["operational_kind_counts"] == %{
             "command" => 2,
             "contact" => 1
           }

    assert operational_timeline_pressure_risk["activity_status_counts"] == %{
             "approved" => 1,
             "partial" => 1,
             "planned" => 1
           }

    assert operational_timeline_pressure_risk["required_operator_action_counts"] == %{
             "review_canonical_timeline" => 1,
             "review_direct_timeline" => 1,
             "review_wrapped_timeline" => 1
           }

    assert operational_timeline_pressure_risk["cadence_import_status_counts"] == %{
             "review" => 3
           }

    assert Enum.sort(operational_timeline_pressure_risk["trust_boundaries"]) == [
             "canonical_operational_timeline_boundary",
             "direct_operational_timeline_boundary",
             "wrapped_operational_timeline_boundary"
           ]

    assert operational_timeline_pressure_risk["assumptions"]["timeline_mutation"] ==
             "not_performed_by_summary"

    assert urgent["score_terms"]["operational_timeline_pressure_penalty"] ==
             -length(operational_timeline_pressure_risks) * risk_weight

    assert "operational_timeline_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "urgent" and
                 &1["term_key"] == "operational_timeline_pressure_penalty" and
                 &1["value"] < 0.0)
           )

    assert "operational_timeline_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_operational_timeline_source_report_paths"] == [
             "mission_state.result_artifact.operational_timeline_report",
             "operational_timeline_report",
             "source_operational_timeline_report"
           ]

    assert urgent_row["branch_operational_timeline_input_keys"] == [
             "command_success_rate",
             "contact_success_rate",
             "station_throughput_factor"
           ]

    assert urgent_row["branch_operational_timeline_kinds"] == ["command", "contact"]

    assert urgent_row["branch_operational_timeline_activity_ids"] == [
             "canonical_timeline_activity",
             "direct_timeline_activity",
             "wrapped_timeline_activity"
           ]

    assert urgent_row["branch_operational_timeline_activity_statuses"] == [
             "approved",
             "partial",
             "planned"
           ]

    assert urgent_row["branch_operational_timeline_approval_statuses"] == ["review_required"]

    assert urgent_row["branch_operational_timeline_required_operator_actions"] == [
             "review_canonical_timeline",
             "review_direct_timeline",
             "review_wrapped_timeline"
           ]

    assert urgent_row["branch_operational_timeline_import_statuses"] == ["review"]

    assert urgent_row["branch_operational_timeline_trust_boundaries"] == [
             "canonical_operational_timeline_boundary",
             "direct_operational_timeline_boundary",
             "wrapped_operational_timeline_boundary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
