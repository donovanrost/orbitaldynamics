Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyCapacityPackSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh

  test "strategy carries mission-state capacity-pack summaries into branch refresh requests" do
    direct_summary = contact_allocation_capacity_pack_summary_fixture("direct")
    canonical_summary = contact_allocation_capacity_pack_summary_fixture("canonical")
    wrapped_summary = contact_allocation_capacity_pack_summary_fixture("wrapped")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_allocation_capacity_pack_summary", direct_summary)
      |> Map.put("contact_allocation_capacity_pack_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_allocation_capacity_pack_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_capacity_pack_boundary"}
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

    assert "mission_state.source_contact_allocation_capacity_pack_summary" in source_report_input_paths
    assert "mission_state.contact_allocation_capacity_pack_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.source_contact_allocation_capacity_pack_summary" in source_report_input_paths

    assert "mission_state.source_contact_allocation_capacity_pack_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.contact_allocation_capacity_pack_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.source_contact_allocation_capacity_pack_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    request_source_report_summary =
      candidate_source["candidate_refresh_request_source_report_summary"]

    assert Map.take(request_source_report_summary, [
             "source_report_count",
             "source_report_row_count",
             "source_report_contact_allocation_capacity_pack_contact_count",
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction",
             "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction",
             "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction",
             "source_report_contact_allocation_reduced_capacity_pack_group_count"
           ]) == %{
             "source_report_count" => 4,
             "source_report_row_count" => 12,
             "source_report_contact_allocation_capacity_pack_contact_count" => 9,
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction" => 3.0,
             "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction" =>
               2.0,
             "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction" =>
               1.0,
             "source_report_contact_allocation_reduced_capacity_pack_group_count" => 4
           }

    capacity_pack_replay_summary =
      CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    replay_source_paths = capacity_pack_replay_summary["source_report_paths"]

    assert Map.take(capacity_pack_replay_summary, [
             "source_report_count",
             "source_report_row_count",
             "source_report_paths",
             "capacity_pack_contact_count",
             "capacity_pack_required_capacity_fraction",
             "capacity_pack_selected_required_capacity_fraction",
             "capacity_pack_deferred_required_capacity_fraction",
             "reduced_capacity_pack_group_count",
             "capacity_pack_group_ids",
             "capacity_pack_summary_schema_contract",
             "branch_local_contact_allocation_pressure",
             "branch_local_capacity_pack_pressure"
           ]) == %{
             "source_report_count" => 4,
             "source_report_row_count" => 12,
             "source_report_paths" => replay_source_paths,
             "capacity_pack_contact_count" => 9,
             "capacity_pack_required_capacity_fraction" => 3.0,
             "capacity_pack_selected_required_capacity_fraction" => 2.0,
             "capacity_pack_deferred_required_capacity_fraction" => 1.0,
             "reduced_capacity_pack_group_count" => 4,
             "capacity_pack_group_ids" => [
               "canonical_pack_equator_prime",
               "direct_pack_equator_prime",
               "wrapped_pack_equator_prime"
             ],
             "capacity_pack_summary_schema_contract" =>
               "contact_allocation_capacity_pack_summary.v1",
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_capacity_pack_pressure" => true
           }

    assert %{
             "contact_allocation" => "not_performed_by_summary",
             "candidate_selection" => "not_performed_by_summary"
           } = capacity_pack_replay_summary["assumptions"]

    for source_path <- [
          "mission_state.source_contact_allocation_capacity_pack_summary[0]",
          "mission_state.source_contact_allocation_capacity_pack_summary[1]",
          "mission_state.contact_allocation_capacity_pack_summary",
          "mission_state.source_result_artifact.source_contact_allocation_capacity_pack_summary"
        ] do
      assert source_path in replay_source_paths
    end
  end

  defp contact_allocation_capacity_pack_summary_fixture(prefix) do
    primary_row = %{
      "contact_id" => "#{prefix}_dl_capacity_primary",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "selected_by_contention_resolution",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    secondary_row = %{
      "contact_id" => "#{prefix}_dl_capacity_secondary",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_reduced_station_capacity_pack",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    overflow_row = %{
      "contact_id" => "#{prefix}_dl_capacity_overflow",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "deferred_by_reduced_station_capacity_pack",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    pack_group = %{
      "contention_group_id" => "#{prefix}_pack_equator_prime",
      "pack_status" => "capacity_limited",
      "ground_station_id" => "equator_prime",
      "capacity_fraction" => 0.5
    }

    %{
      "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
      "model" => "artifact_only_contact_allocation_capacity_pack_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "campaign_planner_test.#{prefix}.contact_allocation_capacity_pack_summary",
      "input_contact_count" => 3,
      "capacity_pack_contact_count" => 3,
      "capacity_pack_review_status" => "review_required",
      "reduced_capacity_pack_group_count" => 1,
      "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
      "capacity_pack_status_counts" => %{
        "deferred_by_reduced_station_capacity_pack" => 1,
        "selected_by_contention_resolution" => 1,
        "selected_by_reduced_station_capacity_pack" => 1
      },
      "capacity_pack_contact_ids_by_status" => %{
        "deferred_by_reduced_station_capacity_pack" => ["#{prefix}_dl_capacity_overflow"],
        "selected_by_contention_resolution" => ["#{prefix}_dl_capacity_primary"],
        "selected_by_reduced_station_capacity_pack" => ["#{prefix}_dl_capacity_secondary"]
      },
      "capacity_pack_contact_ids_by_ground_station_id" => %{
        "equator_prime" => [
          "#{prefix}_dl_capacity_overflow",
          "#{prefix}_dl_capacity_primary",
          "#{prefix}_dl_capacity_secondary"
        ]
      },
      "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
        "equator_prime" => [
          "#{prefix}_dl_capacity_primary",
          "#{prefix}_dl_capacity_secondary"
        ]
      },
      "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_capacity_overflow"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => [
          "#{prefix}_dl_capacity_overflow",
          "#{prefix}_dl_capacity_primary",
          "#{prefix}_dl_capacity_secondary"
        ]
      },
      "capacity_pack_selected_contact_ids_by_direction" => %{
        "downlink" => [
          "#{prefix}_dl_capacity_primary",
          "#{prefix}_dl_capacity_secondary"
        ]
      },
      "capacity_pack_deferred_contact_ids_by_direction" => %{
        "downlink" => ["#{prefix}_dl_capacity_overflow"]
      },
      "capacity_pack_required_capacity_fraction" => 0.75,
      "capacity_pack_selected_required_capacity_fraction" => 0.5,
      "capacity_pack_deferred_required_capacity_fraction" => 0.25,
      "capacity_pack_required_capacity_fraction_by_status" => %{
        "deferred_by_reduced_station_capacity_pack" => 0.25,
        "selected_by_contention_resolution" => 0.25,
        "selected_by_reduced_station_capacity_pack" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.75
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.5
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.75},
      "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.5
      },
      "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.25
      },
      "required_capacity_fraction_source_counts" => %{
        "contact_required_capacity_fraction" => 3
      },
      "required_capacity_fraction_contact_ids_by_source" => %{
        "contact_required_capacity_fraction" => [
          "#{prefix}_dl_capacity_overflow",
          "#{prefix}_dl_capacity_primary",
          "#{prefix}_dl_capacity_secondary"
        ]
      },
      "reduced_capacity_packed_contact_ids" => ["#{prefix}_dl_capacity_secondary"],
      "reduced_capacity_deferred_contact_ids" => ["#{prefix}_dl_capacity_overflow"],
      "capacity_pack_group_ids" => ["#{prefix}_pack_equator_prime"],
      "capacity_pack_group_ids_by_status" => %{
        "capacity_limited" => ["#{prefix}_pack_equator_prime"]
      },
      "rows" => [primary_row, secondary_row, overflow_row],
      "reduced_capacity_pack_groups" => [pack_group],
      "review_rows" => [primary_row, secondary_row, overflow_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_capacity_pack_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_capacity_pack_fixture"}
    }
  end
end
