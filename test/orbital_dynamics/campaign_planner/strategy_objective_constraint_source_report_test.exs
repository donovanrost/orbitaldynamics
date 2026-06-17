Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyObjectiveConstraintSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state objective and constraint reports into branch refresh requests" do
    constraint_report = fn prefix ->
      %{
        "schema_contract" => "constraint_report.v1",
        "rows" => [
          %{
            "constraint_id" => "#{prefix}_downlink_shortfall",
            "metric" => "selected_downlink_shortfall_mb",
            "scenario_id" => "leo_1",
            "status" => "warning",
            "value" => 30.0,
            "ground_station_id" => "equator_prime",
            "trust_boundary" => "#{prefix}_constraint_row_boundary"
          }
        ],
        "provenance" => %{"trust_boundary" => "#{prefix}_constraint_report_boundary"}
      }
    end

    objective_satisfaction_report = fn prefix ->
      %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "rows" => [
          %{
            "id" => "#{prefix}_objective_downlink",
            "objective" => "downlink_completion",
            "status" => "partial",
            "required_downlink_mb" => 30.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "#{prefix}_downlink_activity",
            "trust_boundary" => "#{prefix}_objective_row_boundary"
          }
        ],
        "provenance" => %{"trust_boundary" => "#{prefix}_objective_report_boundary"}
      }
    end

    objective_tradeoff_report = fn prefix ->
      %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "tradeoffs" => [
          %{
            "tradeoff_id" => "#{prefix}_tradeoff_downlink",
            "required_downlink_mb" => 20.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "#{prefix}_tradeoff_activity",
            "trust_boundary" => "#{prefix}_tradeoff_row_boundary"
          }
        ],
        "provenance" => %{"trust_boundary" => "#{prefix}_tradeoff_report_boundary"}
      }
    end

    score_term_report = fn prefix ->
      %{
        "schema_contract" => "score_term_report.v1",
        "rows" => [
          %{
            "term_key" => "downlink_shortfall_mb",
            "value" => 20.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "#{prefix}_score_activity",
            "trust_boundary" => "#{prefix}_score_row_boundary"
          }
        ],
        "provenance" => %{"trust_boundary" => "#{prefix}_score_report_boundary"}
      }
    end

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_constraint_report", constraint_report.("source"))
      |> Map.put("constraint_report", constraint_report.("canonical"))
      |> Map.put("source_objective_satisfaction_report", objective_satisfaction_report.("source"))
      |> Map.put("objective_satisfaction_report", objective_satisfaction_report.("canonical"))
      |> Map.put("source_objective_tradeoff_report", objective_tradeoff_report.("source"))
      |> Map.put("objective_tradeoff_report", objective_tradeoff_report.("canonical"))
      |> Map.put("source_score_term_report", score_term_report.("source"))
      |> Map.put("score_term_report", score_term_report.("canonical"))
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "constraint_report" => constraint_report.("wrapped"),
        "objective_satisfaction_report" => objective_satisfaction_report.("wrapped"),
        "objective_tradeoff_report" => objective_tradeoff_report.("wrapped"),
        "score_term_report" => score_term_report.("wrapped"),
        "provenance" => %{"trust_boundary" => "wrapped_objective_constraint_boundary"}
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
          "mission_state.source_constraint_report",
          "mission_state.constraint_report",
          "mission_state.source_result_artifact.constraint_report",
          "mission_state.source_objective_satisfaction_report",
          "mission_state.objective_satisfaction_report",
          "mission_state.source_result_artifact.objective_satisfaction_report",
          "mission_state.source_objective_tradeoff_report",
          "mission_state.objective_tradeoff_report",
          "mission_state.source_result_artifact.objective_tradeoff_report",
          "mission_state.source_score_term_report",
          "mission_state.score_term_report",
          "mission_state.source_result_artifact.score_term_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    request_summary = candidate_source["candidate_refresh_request_source_report_summary"]

    assert Enum.sort(get_in(request_summary, ["source_reports", "constraint_report", "paths"])) ==
             [
               "mission_state.constraint_report",
               "mission_state.source_constraint_report",
               "mission_state.source_result_artifact.constraint_report"
             ]

    objective_summary = CandidateRefresh.objective_gap_replay_summary(candidate_source)

    assert Enum.sort(objective_summary["source_report_paths"]) == [
             "mission_state.objective_satisfaction_report",
             "mission_state.objective_tradeoff_report",
             "mission_state.score_term_report",
             "mission_state.source_objective_satisfaction_report",
             "mission_state.source_objective_tradeoff_report",
             "mission_state.source_result_artifact.objective_satisfaction_report",
             "mission_state.source_result_artifact.objective_tradeoff_report",
             "mission_state.source_result_artifact.score_term_report",
             "mission_state.source_score_term_report"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
