Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairDuplicateRealizedFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair sends duplicate realized activity feedback to operator review" do
    missed_downlink = refreshed_downlink("dl_1", 100.0, 160.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{
          activities: [
            %{id: "dl_1", status: "missed", reason: "station outage"},
            %{id: "dl_1", status: "completed", completed_fraction: 1.0}
          ]
        },
        current_epoch_s: 165.0
      )

    assert [
             %{
               "id" => "dl_1",
               "repair" => %{
                 "action" => "review_realized_feedback",
                 "reason" => "ambiguous_realized_activity_feedback",
                 "realized_status" => "ambiguous",
                 "realized_feedback_count" => 2,
                 "realized_feedback_statuses" => ["completed", "missed"],
                 "requires_approval" => true
               }
             }
           ] = artifact["activities"]

    assert [
             %{
               "activity_id" => "dl_1",
               "status" => "ambiguous_realized_feedback",
               "repair_action" => "review_realized_feedback",
               "reason" => "ambiguous_realized_activity_feedback",
               "realized_feedback_count" => 2,
               "realized_feedback_rows" => [
                 %{"id" => "dl_1", "status" => "missed"},
                 %{"id" => "dl_1", "status" => "completed"}
               ],
               "requires_approval" => true
             }
           ] = artifact["deltas"]

    assert [
             %{
               "activity_id" => "dl_1",
               "action" => "review_realized_feedback",
               "requirement_type" => "realized_feedback_review",
               "reason" => "ambiguous_realized_activity_feedback"
             }
           ] = artifact["approval_requirements"]

    assert "ambiguous realized feedback for dl_1 requires operator review" in artifact["warnings"]

    assert %{
             "review_type" => "plan_delta_review",
             "activity_id" => "dl_1",
             "repair_action" => "review_realized_feedback",
             "required_operator_action" => "review_realized_feedback",
             "approval_status" => "operator_review_required"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["activity_id"] == "dl_1" and
                   &1["repair_action"] == "review_realized_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
