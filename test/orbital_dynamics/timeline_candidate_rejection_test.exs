defmodule OrbitalDynamics.TimelineCandidateRejectionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Timeline}

  test "builds candidate rejection reports from declared and derived evidence" do
    report =
      Timeline.candidate_rejection_report(
        [
          %{
            id: :obs_clouded,
            type: :observe,
            source_window_id: :target_a_window_1,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            rejection_reasons: "No target visibility window, external planner veto",
            quality_gate_status: :failed,
            violated_constraint: :target_visibility,
            required_margin: 0.1,
            actual_margin: -0.2
          },
          %{
            id: :dl_reserved,
            type: :downlink,
            ground_station_id: :dss_14,
            station_availability: "Reservation Hold",
            capacity_pack_capacity_fraction: 0.5,
            starts_at_s: 30.0,
            ends_at_s: 35.0,
            min_duration_s: 10.0,
            payload_available: false
          },
          %{id: :cmd_ready, type: :command, reviewable: false},
          %{type: :observe}
        ],
        source: :candidate_refresh
      )

    assert %{
             "schema_contract" => "candidate_rejection_report.v1",
             "source" => "candidate_refresh",
             "candidate_count" => 4,
             "row_count" => 4,
             "rejected_count" => 3,
             "not_rejected_count" => 1,
             "invalid_candidate_input_count" => 1,
             "reviewable_count" => 3,
             "rejected_candidate_ids" => [
               "dl_reserved",
               "missing_activity_id:4",
               "obs_clouded"
             ],
             "not_rejected_candidate_ids" => ["cmd_ready"],
             "reviewable_candidate_ids" => [
               "dl_reserved",
               "missing_activity_id:4",
               "obs_clouded"
             ],
             "invalid_candidate_input_ids" => ["missing_activity_id:4"]
           } = report

    assert report["rejection_reason_counts"] == %{
             "contact_too_short" => 1,
             "declared_rejection" => 1,
             "invalid_candidate_input" => 1,
             "no_target_visibility_window" => 1,
             "payload_unavailable" => 1,
             "quality_gate_failed" => 1,
             "station_capacity_reduced" => 1,
             "station_reserved" => 1
           }

    assert report["candidate_id_sets_by_rejection_reason"] == %{
             "contact_too_short" => ["dl_reserved"],
             "declared_rejection" => ["obs_clouded"],
             "invalid_candidate_input" => ["missing_activity_id:4"],
             "no_target_visibility_window" => ["obs_clouded"],
             "payload_unavailable" => ["dl_reserved"],
             "quality_gate_failed" => ["obs_clouded"],
             "station_capacity_reduced" => ["dl_reserved"],
             "station_reserved" => ["dl_reserved"]
           }

    assert report["candidate_ids_by_required_operator_action"] == %{
             "none" => ["cmd_ready"],
             "review_candidate_rejection" => [
               "dl_reserved",
               "missing_activity_id:4",
               "obs_clouded"
             ]
           }

    assert report["required_operator_action_counts"] == %{
             "none" => 1,
             "review_candidate_rejection" => 3
           }

    obs_row = Enum.find(report["rows"], &(&1["candidate_id"] == "obs_clouded"))

    assert %{
             "rejection_status" => "rejected",
             "reviewable" => true,
             "required_operator_action" => "review_candidate_rejection",
             "violated_constraint" => "target_visibility",
             "required_margin" => 0.1,
             "actual_margin" => -0.2,
             "declared_rejection_reasons" => [
               "No target visibility window",
               "external planner veto"
             ]
           } = obs_row

    assert "declared_rejection" in obs_row["rejection_reasons"]
    assert "no_target_visibility_window" in obs_row["rejection_reasons"]
    assert "quality_gate_failed" in obs_row["rejection_reasons"]

    reserved_row = Enum.find(report["rows"], &(&1["candidate_id"] == "dl_reserved"))

    assert "station_reserved" in reserved_row["rejection_reasons"]
    assert "station_capacity_reduced" in reserved_row["rejection_reasons"]
    assert "contact_too_short" in reserved_row["rejection_reasons"]
    assert "payload_unavailable" in reserved_row["rejection_reasons"]
    assert reserved_row["activity_context"]["ground_station_id"] == "dss_14"
    assert reserved_row["activity_context"]["capacity_pack_capacity_fraction"] == 0.5

    ready_row = Enum.find(report["rows"], &(&1["candidate_id"] == "cmd_ready"))

    assert %{
             "rejection_status" => "not_rejected",
             "rejection_reasons" => [],
             "reviewable" => false,
             "required_operator_action" => "none"
           } = ready_row

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report)

    assert Timeline.candidate_rejection_report(report) == report
    assert OrbitalDynamics.candidate_rejection_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert Timeline.candidate_rejection_report(atom_keyed_report) == report
    assert OrbitalDynamics.candidate_rejection_report(atom_keyed_report) == report

    assert OrbitalDynamics.candidate_rejection_report([%{id: :dl_reserved, type: :downlink}])[
             "schema_contract"
           ] == "candidate_rejection_report.v1"
  end

  test "derives candidate rejections from nested station-calendar capacity evidence" do
    report =
      Timeline.candidate_rejection_report([
        %{
          id: :dl_source_capacity_pack,
          type: :downlink,
          source_station_calendar_entry: %{
            id: :station_calendar_capacity_pack,
            capacity_pack_capacity_fraction: 0.4
          }
        },
        %{
          id: :dl_overlap_capacity_pack,
          type: :downlink,
          source_station_calendar_overlaps: [
            %{
              id: :station_calendar_overlap_capacity_pack,
              capacity_pack_capacity_fraction: 0.3
            }
          ]
        },
        %{
          id: :dl_source_reduced_status,
          type: :downlink,
          source_station_calendar_entry: %{
            id: :station_calendar_reduced,
            status: :reduced_capacity
          }
        },
        %{
          id: :dl_overlap_degraded_availability,
          type: :downlink,
          source_station_calendar_overlaps: [
            %{
              id: :station_calendar_degraded,
              availability: :degraded_capacity
            }
          ]
        }
      ])

    assert %{
             "candidate_count" => 4,
             "rejected_count" => 4,
             "rejection_reason_counts" => %{"station_capacity_reduced" => 4},
             "candidate_id_sets_by_rejection_reason" => %{
               "station_capacity_reduced" => [
                 "dl_overlap_capacity_pack",
                 "dl_overlap_degraded_availability",
                 "dl_source_capacity_pack",
                 "dl_source_reduced_status"
               ]
             }
           } = report

    assert Enum.all?(report["rows"], &("station_capacity_reduced" in &1["rejection_reasons"]))

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "derives candidate rejections from nested station-calendar availability evidence" do
    report =
      Timeline.candidate_rejection_report([
        %{
          id: :dl_source_unavailable,
          type: :downlink,
          source_station_calendar_entry: %{
            id: :station_calendar_outage,
            availability: :unavailable
          }
        },
        %{
          id: :dl_overlap_reserved,
          type: :downlink,
          source_station_calendar_overlaps: [
            %{
              id: :station_calendar_reserved,
              status: :reserved
            }
          ]
        }
      ])

    assert %{
             "candidate_count" => 2,
             "rejected_count" => 2,
             "rejection_reason_counts" => %{
               "station_reserved" => 1,
               "station_unavailable" => 1
             },
             "candidate_id_sets_by_rejection_reason" => %{
               "station_reserved" => ["dl_overlap_reserved"],
               "station_unavailable" => ["dl_source_unavailable"]
             }
           } = report

    unavailable_row = Enum.find(report["rows"], &(&1["candidate_id"] == "dl_source_unavailable"))
    reserved_row = Enum.find(report["rows"], &(&1["candidate_id"] == "dl_overlap_reserved"))

    assert "station_unavailable" in unavailable_row["rejection_reasons"]
    assert "station_reserved" in reserved_row["rejection_reasons"]

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report)
  end
end
