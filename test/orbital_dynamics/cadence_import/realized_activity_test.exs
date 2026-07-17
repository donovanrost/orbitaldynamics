defmodule OrbitalDynamics.CadenceImport.RealizedActivityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.Schema

  test "builds import manifest from standalone realized activity" do
    activity = %{
      "schema_contract" => "realized_activity.v1",
      "id" => "downlink_equator",
      "planned_activity_id" => "downlink_equator",
      "timeline_id" => "timeline:downlink:equator_prime:access:leo_1:equator_prime:1",
      "status" => "partial",
      "actual_starts_at_s" => 102.0,
      "actual_ends_at_s" => 150.0,
      "completed_fraction" => 0.6,
      "reason" => "provider reported reduced throughput",
      "type" => "downlink",
      "direction" => "downlink",
      "ground_station_id" => "equator_prime",
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
      "actual_throughput_mb" => 72.0,
      "contact_success" => false,
      "provider" => "cadence",
      "source_quality" => "operator_verified",
      "adapter" => "cadence_feedback_adapter",
      "external_id" => "provider_feedback_1",
      "provenance" => %{"trust_boundary" => "operator_supplied"}
    }

    manifest = CadenceImport.from_realized_activity(activity)
    assert OrbitalDynamics.cadence_import_manifest(activity) == manifest

    alias_manifest =
      activity
      |> Map.delete("type")
      |> Map.put("activity_type", "downlink")
      |> CadenceImport.from_realized_activity()

    assert [
             %{
               "activity_id" => "downlink_equator",
               "activity_type" => "downlink",
               "realized_activity_context" => %{"activity_type" => "downlink"}
             }
           ] = alias_manifest["rows"]

    assert %{
             "source_artifact_type" => "realized_activity.v1",
             "source_artifact_id" => "downlink_equator",
             "row_count" => 1,
             "import_action_counts" => %{"review_realized_feedback" => 1},
             "rows" => [
               %{
                 "import_action" => "review_realized_feedback",
                 "source_review_type" => "realized_feedback",
                 "source_review_action" => "review_unplanned_realization",
                 "activity_id" => "downlink_equator",
                 "feedback_status" => "realized_only",
                 "realized_status" => "partial",
                 "realized_source_quality" => "operator_verified",
                 "realized_activity" => %{"schema_contract" => "realized_activity.v1"},
                 "realized_activity_context" => %{
                   "provider" => "cadence",
                   "source_quality" => "operator_verified",
                   "adapter" => "cadence_feedback_adapter",
                   "external_id" => "provider_feedback_1"
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "realized feedback imports reject stale nested source review evidence" do
    activity = %{
      "schema_contract" => "realized_activity.v1",
      "id" => "downlink_equator",
      "status" => "matched",
      "realized_status" => "failed",
      "type" => "downlink",
      "direction" => "downlink",
      "ground_station_id" => "equator_prime",
      "provider" => "cadence",
      "source_quality" => "operator_verified",
      "adapter" => "cadence_feedback_adapter",
      "external_id" => "provider_feedback_1",
      "provenance" => %{"trust_boundary" => "operator_supplied"}
    }

    manifest =
      activity
      |> CadenceImport.from_realized_activity()
      |> put_in(["rows", Access.at(0), "realized_status"], "completed")
      |> put_in(["rows", Access.at(0), "source_feedback", "realized_status"], "completed")

    assert {:error, report} = Schema.validate_artifact(manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.realized_status" and
                 &1["message"] == "must match realized_status on Cadence import row")
           )
  end

  test "realized activity import uses provider realized_status from match-state rows" do
    activity = %{
      "schema_contract" => "realized_activity.v1",
      "id" => "downlink_equator",
      "status" => "matched",
      "realized_status" => "failed",
      "type" => "downlink",
      "direction" => "downlink",
      "ground_station_id" => "equator_prime",
      "provider" => "cadence",
      "adapter" => "cadence_feedback_adapter",
      "external_id" => "provider_feedback_2",
      "provenance" => %{"trust_boundary" => "operator_supplied"}
    }

    manifest = CadenceImport.from_realized_activity(activity)

    assert %{
             "import_action" => "review_realized_feedback",
             "source_review_action" => "review_unplanned_realization",
             "activity_id" => "downlink_equator",
             "feedback_status" => "realized_only",
             "realized_status" => "failed",
             "contact_success" => false,
             "status_transition" => %{
               "to" => "failed",
               "transition_type" => "added"
             },
             "realized_activity_context" => %{
               "status" => "failed",
               "feedback_status" => "matched"
             },
             "realized_activity" => %{
               "status" => "matched",
               "realized_status" => "failed"
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import manifest from realized state snapshot activities" do
    snapshot = read_json!("study_results/realized_state_snapshot_v1.json")

    manifest = CadenceImport.from_realized_state_snapshot(snapshot)
    assert OrbitalDynamics.cadence_import_manifest(snapshot) == manifest

    assert %{
             "source_artifact_type" => "realized_state_snapshot.v1",
             "source_artifact_id" => "realized-state-demo-2026-05-14T00:00:00Z",
             "row_count" => 2,
             "import_action_counts" => %{"review_realized_feedback" => 2},
             "rows" => rows
           } = manifest

    assert Enum.map(rows, & &1["source"]) == [
             "realized_state_snapshot.activities",
             "realized_state_snapshot.activities"
           ]

    assert Enum.map(rows, & &1["activity_id"]) == [
             "cmd_repoint",
             "downlink_equator"
           ]

    assert Enum.all?(
             rows,
             &match?(
               %{
                 "import_action" => "review_realized_feedback",
                 "source_review_type" => "realized_feedback",
                 "source_review_action" => "review_unplanned_realization",
                 "feedback_status" => "realized_only"
               },
               &1
             )
           )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
