defmodule OrbitalDynamics.OperatorReview.TimelineFeedbackTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds review package from realized timeline feedback rows" do
    report = %{
      schema_contract: "timeline_feedback_report.v1",
      rows: [
        %{
          activity_id: "obs_1",
          status: "matched",
          planned_type: "observe",
          planned_status: "approved",
          realized_status: "completed",
          planned_starts_at_s: 10.0,
          planned_ends_at_s: 20.0,
          actual_starts_at_s: 11.0,
          actual_ends_at_s: 22.0,
          start_delta_s: 1.0,
          end_delta_s: 2.0,
          completed_fraction: 1.0,
          thermal_zone_id: "payload_deck",
          temperature_c: 21.5,
          planned_temperature_c: 18.0,
          actual_temperature_c: 21.5,
          temperature_delta_c: 3.5,
          min_operating_temperature_c: -5.0,
          max_operating_temperature_c: 45.0,
          thermal_margin_c: 23.5,
          thermal_status: "warm",
          thermal_model: "thermal_model:v1",
          thermal_source: "realized_activity",
          thermal_confidence: 0.8
        },
        %{
          activity_id: "obs_2",
          status: "matched",
          planned_type: "observe",
          planned_status: "approved",
          realized_status: "failed",
          contact_result: ["accepted", "dropped"],
          observation_result: [:started, :timeout],
          reason: "payload timeout"
        },
        %{
          activity_id: "dl_1",
          status: "planned_only",
          planned_type: "downlink",
          planned_status: "approved"
        },
        %{activity_id: "unplanned_1", status: "realized_only", realized_status: "partial"}
      ],
      provenance: %{"source" => "timeline_feedback_test"}
    }

    string_key_report =
      report
      |> Enum.map(fn {key, value} -> {to_string(key), value} end)
      |> Map.new()

    package = OperatorReview.from_timeline_feedback_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package
    assert OrbitalDynamics.operator_review_package(string_key_report) == package

    assert %{
             "source_artifact_type" => "timeline_feedback_report.v1",
             "source_artifact_id" => "timeline_feedback_report",
             "review_count" => 4,
             "realized_feedback_count" => 4
           } = package

    assert %{
             "review_type" => "realized_feedback",
             "activity_id" => "obs_1",
             "activity_type" => "observe",
             "approval_status" => "not_required",
             "required_operator_action" => "record_realized_completion",
             "start_delta_s" => 1.0,
             "completed_fraction" => 1.0,
             "thermal_zone_id" => "payload_deck",
             "temperature_c" => 21.5,
             "planned_temperature_c" => 18.0,
             "actual_temperature_c" => 21.5,
             "temperature_delta_c" => 3.5,
             "min_operating_temperature_c" => -5.0,
             "max_operating_temperature_c" => 45.0,
             "thermal_margin_c" => 23.5,
             "thermal_status" => "warm",
             "thermal_model" => "thermal_model:v1",
             "thermal_source" => "realized_activity",
             "thermal_confidence" => 0.8,
             "source_feedback" => %{"activity_id" => "obs_1"}
           } = Enum.find(package["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "obs_2",
             "required_operator_action" => "review_realized_exception",
             "contact_result" => "accepted,dropped",
             "observation_result" => "started,timeout",
             "reason" => "payload timeout"
           } = Enum.find(package["rows"], &(&1["activity_id"] == "obs_2"))

    assert %{
             "activity_id" => "dl_1",
             "required_operator_action" => "review_missing_realization"
           } = Enum.find(package["rows"], &(&1["activity_id"] == "dl_1"))

    assert %{
             "activity_id" => "unplanned_1",
             "required_operator_action" => "review_unplanned_realization"
           } = Enum.find(package["rows"], &(&1["activity_id"] == "unplanned_1"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "timeline feedback report source id uses report id when present" do
    assert %{"source_artifact_id" => "timeline_feedback:001"} =
             OperatorReview.from_timeline_feedback_report(%{
               id: :"timeline_feedback:001",
               rows: []
             })
  end
end
