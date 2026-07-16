defmodule OrbitalDynamics.OperatorReview.PlannedActivityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds standalone planned activity review package" do
    activity = %{
      "schema_contract" => "planned_activity.v1",
      "id" => "cmd_repoint",
      "type" => "command",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "command",
      "starts_at_s" => 180.0,
      "ends_at_s" => 200.0,
      "source_window_id" => "window:leo_1:command:equator_prime:1",
      "cadence_import" => %{
        "external_id" => "cadence_cmd_repoint",
        "activity_type" => "command",
        "schema_contract" => "planned_activity.v1"
      }
    }

    package = OperatorReview.from_planned_activity(activity)
    assert OrbitalDynamics.operator_review_package(activity) == package

    alias_package =
      activity
      |> Map.delete("type")
      |> Map.put("activity_type", "command")
      |> OperatorReview.from_planned_activity()

    assert [
             %{
               "activity_id" => "cmd_repoint",
               "activity_type" => "command",
               "required_operator_action" => "review_command_contact"
             }
           ] = alias_package["rows"]

    assert %{
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "cmd_repoint",
             "review_count" => 1,
             "operational_timeline_count" => 1,
             "rows" => [
               %{
                 "review_type" => "operational_timeline_review",
                 "source" => "planned_activity",
                 "activity_id" => "cmd_repoint",
                 "required_operator_action" => "review_command_contact",
                 "cadence_import_status" => "present",
                 "cadence_import_type" => "command",
                 "cadence_import_id" => "cadence_cmd_repoint",
                 "cadence_import_contract" => "planned_activity.v1",
                 "source_operational_timeline" => %{"activity_id" => "cmd_repoint"}
               }
             ]
           } = package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_planned_activity(%{
               "schema_contract" => "planned_activity.v1",
               "id" => "observe_target",
               "type" => "observe",
               "scenario_id" => "leo_1",
               "target_id" => "target_a",
               "starts_at_s" => 210.0,
               "ends_at_s" => 240.0,
               "approval_status" => "approved"
             })

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(row, ["source_operational_timeline", "activity_id"], "activity id with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_timeline.activity_id")
           )
  end
end
