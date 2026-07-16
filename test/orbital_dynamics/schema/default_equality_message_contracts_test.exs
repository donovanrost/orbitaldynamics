defmodule OrbitalDynamics.Schema.DefaultEqualityMessageContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "preserves command-window default equality messages" do
    assert_default_message(
      "study_results/command_window_report_v1.json",
      "window_count",
      99,
      "must equal 4"
    )
  end

  test "preserves station-calendar-precedence default equality messages" do
    assert_default_message(
      "study_results/station_calendar_precedence_summary_v1.json",
      "precedence_review_status",
      "clear",
      "must equal review_required"
    )
  end

  test "preserves timeline-lifecycle-summary default equality messages" do
    assert_default_message(
      "study_results/timeline_lifecycle_state_summary_v1.json",
      "row_count",
      99,
      "must equal 4"
    )
  end

  test "preserves validation-safety-case default equality messages" do
    assert_default_message(
      "study_results/validation_safety_case_summary_v1.json",
      "evidence_count",
      99,
      "must equal 4"
    )
  end

  test "preserves station-reservation-review default equality messages" do
    assert_default_message(
      "study_results/station_reservation_review_summary_v1.json",
      "reservation_count",
      99,
      "must equal 3"
    )
  end

  test "preserves station-reservation-hold default equality messages" do
    assert_default_message(
      "study_results/station_reservation_hold_summary_v1.json",
      "reservation_hold_count",
      99,
      "must equal 2"
    )
  end

  test "preserves station-reservation-import-readiness default equality messages" do
    assert_default_message(
      "study_results/station_reservation_hold_import_readiness_summary_v1.json",
      "reservation_hold_count",
      99,
      "must equal 2"
    )
  end

  test "preserves station-calendar-report default equality messages" do
    assert_default_message(
      "study_results/station_calendar_report_v1.json",
      "affected_contact_count",
      99,
      "must equal 2"
    )
  end

  defp assert_default_message(path, field, stale_value, expected_message) do
    artifact =
      path
      |> File.read!()
      |> :json.decode()
      |> Map.put(field, stale_value)

    assert {:error, report} = Schema.validate_artifact(artifact)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.#{field}" and &1["message"] == expected_message)
           )
  end
end
