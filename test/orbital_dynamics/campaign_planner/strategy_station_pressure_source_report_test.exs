Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationPressureSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh

  test "strategy carries mission-state station-pressure summaries into branch refresh requests" do
    direct_summary = contact_allocation_station_pressure_summary_fixture("direct")
    canonical_summary = contact_allocation_station_pressure_summary_fixture("canonical")
    wrapped_summary = contact_allocation_station_pressure_summary_fixture("wrapped")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_allocation_station_pressure_summary", direct_summary)
      |> Map.put("contact_allocation_station_pressure_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_allocation_station_pressure_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_station_pressure_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    assert "mission_state.source_contact_allocation_station_pressure_summary" in source_report_input_paths

    assert "mission_state.contact_allocation_station_pressure_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.source_contact_allocation_station_pressure_summary" in source_report_input_paths

    assert "mission_state.source_contact_allocation_station_pressure_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.contact_allocation_station_pressure_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.source_contact_allocation_station_pressure_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    request_source_report_summary =
      candidate_source["candidate_refresh_request_source_report_summary"]

    assert Map.take(request_source_report_summary, [
             "source_report_count",
             "source_report_row_count",
             "source_report_contact_allocation_station_pressure_contact_count",
             "source_report_contact_allocation_station_pressure_review_contact_count",
             "source_report_contact_allocation_station_pressure_ground_station_counts"
           ]) == %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_contact_allocation_station_pressure_contact_count" => 3,
             "source_report_contact_allocation_station_pressure_review_contact_count" => 3,
             "source_report_contact_allocation_station_pressure_ground_station_counts" => %{
               "equator_prime" => 4
             }
           }

    station_pressure_replay_summary =
      CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    replay_source_paths = station_pressure_replay_summary["source_report_paths"]

    assert Map.take(station_pressure_replay_summary, [
             "source_report_count",
             "source_report_row_count",
             "source_report_paths",
             "station_pressure_contact_count",
             "station_pressure_review_contact_count",
             "station_pressure_contact_ids_by_ground_station",
             "station_pressure_availability_counts",
             "station_pressure_summary_schema_contract",
             "branch_local_contact_allocation_pressure",
             "branch_local_station_pressure"
           ]) == %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "station_pressure_contact_count" => 3,
             "station_pressure_review_contact_count" => 3,
             "station_pressure_contact_ids_by_ground_station" => %{
               "equator_prime" => [
                 "canonical_dl_station_pressure",
                 "direct_dl_station_pressure",
                 "wrapped_dl_station_pressure"
               ]
             },
             "station_pressure_availability_counts" => %{"reserved" => 4},
             "station_pressure_summary_schema_contract" =>
               "contact_allocation_station_pressure_summary.v1",
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_station_pressure" => true
           }

    assert %{
             "contact_allocation" => "not_performed_by_summary",
             "candidate_selection" => "not_performed_by_summary"
           } = station_pressure_replay_summary["assumptions"]

    for source_path <- [
          "mission_state.source_contact_allocation_station_pressure_summary[0]",
          "mission_state.source_contact_allocation_station_pressure_summary[1]",
          "mission_state.contact_allocation_station_pressure_summary",
          "mission_state.source_result_artifact.source_contact_allocation_station_pressure_summary"
        ] do
      assert source_path in replay_source_paths
    end
  end

  defp contact_allocation_station_pressure_summary_fixture(prefix) do
    nominal_row = %{
      "contact_id" => "#{prefix}_dl_nominal",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    station_pressure_row = %{
      "contact_id" => "#{prefix}_dl_station_pressure",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_calendar_entry_id" => "#{prefix}_station_reserved_1",
      "station_calendar_overlap_availabilities" => ["reserved"],
      "station_calendar_precedence_availability" => "reserved",
      "station_calendar_precedence_rank" => 2
    }

    %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "campaign_planner_test.#{prefix}.contact_allocation_station_pressure_summary",
      "input_contact_count" => 2,
      "station_pressure_contact_count" => 1,
      "station_pressure_review_contact_count" => 1,
      "station_pressure_contact_ids" => ["#{prefix}_dl_station_pressure"],
      "station_pressure_review_contact_ids" => ["#{prefix}_dl_station_pressure"],
      "station_pressure_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_ground_station_id" => %{"equator_prime" => 1},
      "station_pressure_contact_ids_by_availability" => %{
        "reserved" => ["#{prefix}_dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_availability" => %{
        "reserved" => ["#{prefix}_dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_rank" => %{
        "2" => ["#{prefix}_dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_precedence_rank" => %{"2" => 1},
      "rows" => [nominal_row, station_pressure_row],
      "review_rows" => [station_pressure_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_station_pressure_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_station_pressure_fixture"}
    }
  end
end
