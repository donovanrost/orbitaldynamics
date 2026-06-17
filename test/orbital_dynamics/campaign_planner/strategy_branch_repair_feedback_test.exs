Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchRepairFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy surfaces branch repair timeline feedback for operator review" do
    artifact =
      strategy(
        base_plan(%{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
        }),
        branches: [
          %{id: "baseline"},
          %{
            id: "missed_contact",
            realized_state_overrides: %{
              activities: [
                %{
                  id: "dl_1",
                  type: "downlink",
                  status: "missed",
                  reason: "provider outage"
                }
              ]
            }
          }
        ],
        current_epoch_s: 0.0
      )

    missed_contact = branch(artifact, "missed_contact")

    assert %{
             "schema_contract" => "timeline_feedback_report.v1",
             "status_counts" => %{"matched" => 1},
             "rows" => [
               %{
                 "activity_id" => "dl_1",
                 "feedback_kind" => "contact",
                 "realized_status" => "missed",
                 "reason" => "provider outage"
               }
             ]
           } = missed_contact["repair_result"]["source_timeline_feedback_report"]

    assert %{
             "branch_id" => "missed_contact",
             "review_type" => "realized_feedback",
             "source" =>
               "campaign_strategy.branches.repair_result.source_timeline_feedback_report.rows",
             "activity_id" => "dl_1",
             "required_operator_action" => "review_contact_exception",
             "approval_status" => "operator_review_required",
             "reason" => "provider outage"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "realized_feedback")
             )

    assert %{
             "import_action" => "review_realized_feedback",
             "import_status" => "blocked_missing_cadence_import",
             "activity_id" => "dl_1",
             "branch_id" => "missed_contact",
             "source_feedback" => %{"reason" => "provider outage"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "realized_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
