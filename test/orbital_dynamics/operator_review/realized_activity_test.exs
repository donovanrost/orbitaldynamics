defmodule OrbitalDynamics.OperatorReview.RealizedActivityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds standalone realized activity review package" do
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

    package = OperatorReview.from_realized_activity(activity)
    assert OrbitalDynamics.operator_review_package(activity) == package

    alias_package =
      activity
      |> Map.delete("type")
      |> Map.put("activity_type", "downlink")
      |> OperatorReview.from_realized_activity()

    assert [
             %{
               "activity_id" => "downlink_equator",
               "activity_type" => "downlink",
               "realized_activity_context" => %{"activity_type" => "downlink"}
             }
           ] = alias_package["rows"]

    assert %{
             "source_artifact_type" => "realized_activity.v1",
             "source_artifact_id" => "downlink_equator",
             "review_count" => 1,
             "realized_feedback_count" => 1,
             "rows" => [
               %{
                 "review_type" => "realized_feedback",
                 "source" => "realized_activity",
                 "activity_id" => "downlink_equator",
                 "feedback_status" => "realized_only",
                 "realized_status" => "partial",
                 "realized_source_quality" => "operator_verified",
                 "required_operator_action" => "review_unplanned_realization",
                 "approval_status" => "operator_review_required",
                 "realized_activity" => %{"schema_contract" => "realized_activity.v1"},
                 "realized_activity_context" => %{
                   "provider" => "cadence",
                   "source_quality" => "operator_verified",
                   "adapter" => "cadence_feedback_adapter",
                   "external_id" => "provider_feedback_1"
                 }
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "realized feedback review rows reject stale source feedback evidence" do
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

    package =
      activity
      |> OperatorReview.from_realized_activity()
      |> put_in(["rows", Access.at(0), "source_feedback", "realized_status"], "completed")

    assert {:error, report} = Schema.validate_artifact(package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].realized_status" and
                 &1["message"] == "must match source_feedback.realized_status")
           )
  end

  test "standalone realized activity review uses provider realized_status from match-state rows" do
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

    package = OperatorReview.from_realized_activity(activity)

    assert %{
             "review_type" => "realized_feedback",
             "activity_id" => "downlink_equator",
             "feedback_status" => "realized_only",
             "realized_status" => "failed",
             "required_operator_action" => "review_unplanned_realization",
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
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "standalone realized activity source id falls back through activity id and default" do
    assert %{"source_artifact_id" => "realized-activity-from-alias"} =
             OperatorReview.from_realized_activity(%{
               realized_activity_id: :"realized-activity-from-alias",
               status: :matched
             })

    assert %{"source_artifact_id" => "realized_activity"} =
             OperatorReview.from_realized_activity(%{status: :matched})
  end
end
