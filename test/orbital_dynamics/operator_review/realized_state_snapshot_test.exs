defmodule OrbitalDynamics.OperatorReview.RealizedStateSnapshotTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds realized state snapshot review package from activity rows" do
    snapshot = read_json!("study_results/realized_state_snapshot_v1.json")

    package = OperatorReview.from_realized_state_snapshot(snapshot)
    assert OrbitalDynamics.operator_review_package(snapshot) == package

    assert %{
             "source_artifact_type" => "realized_state_snapshot.v1",
             "source_artifact_id" => "realized-state-demo-2026-05-14T00:00:00Z",
             "review_count" => 2,
             "realized_feedback_count" => 2,
             "review_type_counts" => %{"realized_feedback" => 2}
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "realized_state_snapshot.activities",
             "realized_state_snapshot.activities"
           ]

    assert Enum.map(package["rows"], & &1["activity_id"]) == [
             "cmd_repoint",
             "downlink_equator"
           ]

    assert Enum.all?(
             package["rows"],
             &match?(
               %{
                 "review_type" => "realized_feedback",
                 "feedback_status" => "realized_only",
                 "required_operator_action" => "review_unplanned_realization"
               },
               &1
             )
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "realized state snapshot source id falls back through metadata and default" do
    assert %{"source_artifact_id" => "snapshot_from_metadata"} =
             OperatorReview.from_realized_state_snapshot(%{
               metadata: %{snapshot_id: :snapshot_from_metadata},
               activities: []
             })

    assert %{"source_artifact_id" => "realized_state_snapshot"} =
             OperatorReview.from_realized_state_snapshot(%{activities: []})
  end

  test "builds source-aware rows with exact snapshot context" do
    snapshot = read_json!("study_results/realized_state_snapshot_v1.json")

    assert [first | _rest] =
             OrbitalDynamics.OperatorReview.RealizedStateSnapshot.source_rows(
               snapshot,
               "campaign_repair.source_realized_state_snapshot"
             )

    assert %{
             "review_type" => "realized_feedback",
             "source" => "campaign_repair.source_realized_state_snapshot.activities",
             "activity_id" => "cmd_repoint",
             "required_operator_action" => "review_unplanned_realization",
             "source_realized_state_snapshot" => ^snapshot
           } = first
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
