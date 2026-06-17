Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineProtectionTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair preserves locked approved activities" do
    locked =
      "locked_dl"
      |> downlink(500.0, 560.0)
      |> Map.put("metadata", %{"approval_status" => "approved", "locked" => true})

    artifact =
      repair(%{"activities" => [locked], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 100.0
      )

    assert [%{"id" => "locked_dl", "repair" => repair}] = artifact["activities"]
    assert repair["action"] == "preserved"
    assert repair["reason"] == "activity_locked_or_approved"
    assert artifact["approval_requirements"] == []

    assert %{
             "preserved_locked_or_approved_count" => 1,
             "preserved_executed_count" => 0,
             "changed_locked_or_approved_count" => 0,
             "preserved_locked_or_approved_activity_ids" => ["locked_dl"]
           } = artifact["repair_metadata"]["timeline_protection"]

    assert %{
             "schema_contract" => "operator_review_package.v1",
             "timeline_protection_count" => 1,
             "rows" => review_rows
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "timeline_protection",
             "activity_id" => "locked_dl",
             "protection_category" => "preserved_locked_or_approved",
             "protection_decision" => "preserved",
             "required_operator_action" => "record_protected_timeline_preservation",
             "approval_status" => "not_required"
           } = Enum.find(review_rows, &(&1["review_type"] == "timeline_protection"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(artifact["operator_review_package"])
  end

  test "repair normalizes string false for locked activity policy" do
    locked =
      "locked_dl"
      |> downlink(500.0, 560.0)
      |> Map.put("metadata", %{"approval_status" => "approved", "locked" => true})

    artifact =
      repair(%{"activities" => [locked], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 100.0,
        repair_policy: %{"allow_locked_changes" => " FALSE "}
      )

    assert [%{"id" => "locked_dl", "repair" => repair}] = artifact["activities"]
    assert repair["action"] == "preserved"
    assert repair["reason"] == "activity_locked_or_approved"

    assert %{
             "allow_locked_changes" => false,
             "preserve_approved" => true,
             "preserve_executed" => true
           } = artifact["repair_policy"]

    assert %{
             "preserved_locked_or_approved_count" => 1,
             "changed_locked_or_approved_count" => 0
           } = artifact["repair_metadata"]["timeline_protection"]
  end

  test "repair metadata summarizes preserved executed activities" do
    executed = downlink("completed_dl", 500.0, 560.0)

    artifact =
      repair(%{"activities" => [executed], "candidate_activities" => []},
        realized_state: %{activities: [%{id: "completed_dl", status: "completed"}]},
        current_epoch_s: 600.0
      )

    assert [%{"id" => "completed_dl", "repair" => repair}] = artifact["activities"]
    assert repair["action"] == "preserved_executed"
    assert repair["reason"] == "activity_already_completed"

    assert [
             %{
               "activity_id" => "completed_dl",
               "repair_action" => "preserved_executed",
               "requires_approval" => false
             }
           ] = artifact["deltas"]

    assert %{
             "preserved_locked_or_approved_count" => 0,
             "preserved_executed_count" => 1,
             "changed_executed_count" => 0,
             "preserved_executed_activity_ids" => ["completed_dl"]
           } = artifact["repair_metadata"]["timeline_protection"]
  end

  test "repair preserves executed provider status as executed timeline evidence" do
    executed = downlink("executed_dl", 500.0, 560.0)

    artifact =
      repair(%{"activities" => [executed], "candidate_activities" => []},
        realized_state: %{activities: [%{id: "executed_dl", status: "executed"}]},
        current_epoch_s: 600.0
      )

    assert [%{"id" => "executed_dl", "repair" => repair}] = artifact["activities"]
    assert repair["action"] == "preserved_executed"
    assert repair["reason"] == "activity_already_executed"
    assert repair["realized_status"] == "executed"

    assert [
             %{
               "activity_id" => "executed_dl",
               "repair_action" => "preserved_executed",
               "status" => "executed",
               "requires_approval" => false
             }
           ] = artifact["deltas"]

    assert %{
             "preserved_executed_count" => 1,
             "changed_executed_count" => 0,
             "preserved_executed_activity_ids" => ["executed_dl"]
           } = artifact["repair_metadata"]["timeline_protection"]
  end

  test "repair cancels rejected terminal feedback without replacement" do
    rejected = downlink("rejected_dl", 500.0, 560.0)

    artifact =
      repair(%{"activities" => [rejected], "candidate_activities" => []},
        realized_state: %{activities: [%{id: "rejected_dl", status: " REJECTED "}]},
        current_epoch_s: 600.0
      )

    assert artifact["activities"] == []

    assert [
             %{
               "activity_id" => "rejected_dl",
               "repair_action" => "canceled",
               "status" => "rejected",
               "reason" => "realized_status_rejected_removed_from_remaining_plan",
               "requires_approval" => true
             }
           ] = artifact["deltas"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair preserves partial realization evidence on preserved executed activities" do
    partial = refreshed_downlink("partial_dl", 500.0, 560.0)

    artifact =
      repair(%{"activities" => [partial], "candidate_activities" => []},
        realized_state: %{
          activities: [
            %{
              id: "partial_dl",
              status: "partial",
              completed_fraction: 0.5,
              actual_starts_at_s: 505.0,
              actual_ends_at_s: 550.0
            }
          ]
        },
        current_epoch_s: 600.0
      )

    assert [
             %{
               "id" => "partial_dl",
               "repair" => %{
                 "action" => "preserved_executed",
                 "reason" => "activity_already_partial",
                 "realized_status" => "partial",
                 "completed_fraction" => 0.5,
                 "actual_starts_at_s" => 505.0,
                 "actual_ends_at_s" => 550.0
               }
             }
           ] = artifact["activities"]

    assert [
             %{
               "activity_id" => "partial_dl",
               "status" => "matched",
               "realized_status" => "partial",
               "completed_fraction" => 0.5
             }
           ] = artifact["source_timeline_feedback_report"]["rows"]

    assert [
             %{
               "activity_id" => "partial_dl",
               "repair_action" => "preserved_executed",
               "requires_approval" => false
             }
           ] = artifact["deltas"]

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "realized_feedback" and
                 &1["activity_id"] == "partial_dl" and
                 &1["completed_fraction"] == 0.5 and
                 &1["required_operator_action"] == "review_contact_variance")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "plan_delta_review" and
                 &1["activity_id"] == "partial_dl" and
                 &1["repair_action"] == "preserved_executed" and
                 &1["required_operator_action"] == "record_preserved_executed_item")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["source_review_type"] == "plan_delta_review" and
                 &1["activity_id"] == "partial_dl" and
                 &1["import_action"] == "record_preserved_executed_activity")
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
