Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategySourceSummaryPathsTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy preserves wrapped expanded candidate-refresh source summary input paths" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.merge(%{
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "source_station_reservation_review_summary" => %{
            "schema_contract" => "station_reservation_review_summary.v1",
            "source" => "station_reservation.fixture"
          },
          "provider_counteroffer_review_summary" => %{
            "schema_contract" => "provider_counteroffer_review_summary.v1",
            "source" => "counteroffer.fixture"
          },
          "timeline_publication_summary" => %{
            "schema_contract" => "timeline_publication_summary.v1",
            "source" => "timeline_publication.fixture"
          }
        }
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [%{id: "baseline"}, %{id: "expanded_summary_review"}],
        current_epoch_s: 0.0
      )

    candidate_source =
      artifact
      |> branch("expanded_summary_review")
      |> get_in(["assumptions", "candidate_source"])

    source_report_input_paths = candidate_source["source_report_input_paths"]

    assert "mission_state.source_result_artifact.source_station_reservation_review_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.provider_counteroffer_review_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.timeline_publication_summary" in source_report_input_paths

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy records summary feedback source paths on explicit branch events" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{id: "baseline"},
          %{
            id: "summary_review",
            events: [
              %{
                type: "validation_safety_case_pressure",
                report_id: "validation_safety_case:manual_review",
                validation_safety_case_status: "review_required",
                evidence_status: "review_required",
                evidence_ref: "quality_gate_report.v1:operator_review",
                feedback_source: "mission_state.source_validation_safety_case_summary.evidence",
                feedback_scope: "validation_safety_case",
                required_operator_action: "review_validation_safety_case"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    summary_branch = branch(artifact, "summary_review")
    candidate_source = get_in(summary_branch, ["assumptions", "candidate_source"])

    assert "mission_state.source_validation_safety_case_summary" in candidate_source[
             "source_report_input_paths"
           ]

    refute "mission_state.source_validation_safety_case_summary.evidence" in candidate_source[
             "source_report_input_paths"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
