Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairCommandWindowReviewImportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair embeds command-window review and import context" do
    artifact =
      repair(
        %{
          "activities" => [command("cmd_1", "leo_1", 100.0, 130.0)],
          "candidate_activities" => []
        },
        realized_state: %{activities: []},
        current_epoch_s: 0.0
      )

    assert %{
             "schema_contract" => "command_window_report.v1",
             "source" => "campaign_repair.activities",
             "window_count" => 1,
             "command_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "activity_id" => "cmd_1",
                 "window_type" => "command_window",
                 "required_operator_action" => "review_command_contact",
                 "operator_action_reason" => "command_boundary_requires_review"
               }
             ]
           } = artifact["command_window_report"]

    assert %{
             "command_window_count" => 1,
             "rows" => review_rows
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "command_window_review",
             "activity_id" => "cmd_1",
             "window_type" => "command_window",
             "source_command_window" => %{"activity_id" => "cmd_1"}
           } = Enum.find(review_rows, &(&1["review_type"] == "command_window_review"))

    assert %{
             "rows" => import_rows
           } = artifact["cadence_import_manifest"]

    assert %{
             "import_action" => "review_command_window",
             "source_review_type" => "command_window_review",
             "activity_id" => "cmd_1",
             "cadence_import_type" => "command_window"
           } = Enum.find(import_rows, &(&1["source_review_type"] == "command_window_review"))

    assert {:ok, %{"schema_contract" => "command_window_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact["command_window_report"])

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp command(id, scenario_id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "command",
      "scenario_id" => scenario_id,
      "direction" => "uplink",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 1.0
    }
  end
end
