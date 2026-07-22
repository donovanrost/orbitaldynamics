Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyProviderReservationRequestSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh

  test "strategy carries mission-state provider-reservation request summaries into branch refresh requests" do
    direct_summary = contact_allocation_provider_reservation_request_summary_fixture("direct")

    canonical_summary =
      contact_allocation_provider_reservation_request_summary_fixture("canonical")

    wrapped_summary = contact_allocation_provider_reservation_request_summary_fixture("wrapped")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_allocation_provider_reservation_request_summary", direct_summary)
      |> Map.put("contact_allocation_provider_reservation_request_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_allocation_provider_reservation_request_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_provider_reservation_request_boundary"}
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

    assert "mission_state.source_contact_allocation_provider_reservation_request_summary" in source_report_input_paths

    assert "mission_state.contact_allocation_provider_reservation_request_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.source_contact_allocation_provider_reservation_request_summary" in source_report_input_paths

    assert "mission_state.source_contact_allocation_provider_reservation_request_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.contact_allocation_provider_reservation_request_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.source_contact_allocation_provider_reservation_request_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    request_source_report_summary =
      candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_contact_allocation_provider_reservation_candidate_contact_count" => 8,
             "source_report_contact_allocation_provider_reservation_request_contact_count" => 4,
             "source_report_contact_allocation_provider_reservation_review_contact_count" => 4,
             "source_report_contact_allocation_provider_reservation_no_request_contact_count" =>
               4,
             "source_report_contact_allocation_provider_reservation_request_status_counts" => %{
               "review_required" => 4
             },
             "source_report_contact_allocation_provider_reservation_request_contact_ids" => [
               "canonical_dl_reserved_owner",
               "direct_dl_reserved_owner",
               "wrapped_dl_reserved_owner"
             ],
             "source_report_contact_allocation_provider_reservation_review_contact_ids" => [
               "canonical_dl_review_overlap",
               "direct_dl_review_overlap",
               "wrapped_dl_review_overlap"
             ],
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids" => [
               "canonical_dl_unreserved",
               "direct_dl_unreserved",
               "wrapped_dl_unreserved"
             ],
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_ground_station" =>
               %{
                 "equator_prime" => [
                   "direct_dl_reserved_owner",
                   "wrapped_dl_reserved_owner",
                   "canonical_dl_reserved_owner"
                 ]
               },
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_match_status" =>
               %{
                 "matched" => [
                   "direct_dl_reserved_owner",
                   "wrapped_dl_reserved_owner",
                   "canonical_dl_reserved_owner"
                 ]
               }
           } = request_source_report_summary

    assert Enum.sort(
             get_in(request_source_report_summary, [
               "source_report_contact_allocation_provider_reservation_request_ids_by_match_status",
               "matched"
             ])
           ) == [
             "canonical_reservation_1",
             "direct_reservation_1",
             "wrapped_reservation_1"
           ]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "provider_reservation_candidate_contact_count" => 8,
             "provider_reservation_request_contact_count" => 4,
             "provider_reservation_review_contact_count" => 4,
             "provider_reservation_no_request_contact_count" => 4,
             "provider_reservation_request_status_counts" => %{"review_required" => 4},
             "provider_reservation_request_summary_schema_contract" =>
               "contact_allocation_provider_reservation_request_summary.v1",
             "provider_reservation_request_contact_ids" => [
               "canonical_dl_reserved_owner",
               "direct_dl_reserved_owner",
               "wrapped_dl_reserved_owner"
             ],
             "provider_reservation_review_contact_ids" => [
               "canonical_dl_review_overlap",
               "direct_dl_review_overlap",
               "wrapped_dl_review_overlap"
             ],
             "provider_reservation_no_request_contact_ids" => [
               "canonical_dl_unreserved",
               "direct_dl_unreserved",
               "wrapped_dl_unreserved"
             ],
             "provider_reservation_request_contact_ids_by_ground_station" => %{
               "equator_prime" => [
                 "direct_dl_reserved_owner",
                 "wrapped_dl_reserved_owner",
                 "canonical_dl_reserved_owner"
               ]
             },
             "provider_reservation_request_contact_ids_by_match_status" => %{
               "matched" => [
                 "direct_dl_reserved_owner",
                 "wrapped_dl_reserved_owner",
                 "canonical_dl_reserved_owner"
               ]
             },
             "branch_local_provider_reservation_request_pressure" => true,
             "branch_local_contact_allocation_pressure" => true,
             "assumptions" => %{
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } =
             contact_allocation_replay_summary =
             CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    assert Enum.sort(
             get_in(contact_allocation_replay_summary, [
               "provider_reservation_request_ids_by_match_status",
               "matched"
             ])
           ) == [
             "canonical_reservation_1",
             "direct_reservation_1",
             "wrapped_reservation_1"
           ]

    for source_path <- [
          "mission_state.source_contact_allocation_provider_reservation_request_summary[0]",
          "mission_state.source_contact_allocation_provider_reservation_request_summary[1]",
          "mission_state.contact_allocation_provider_reservation_request_summary",
          "mission_state.source_result_artifact.source_contact_allocation_provider_reservation_request_summary"
        ] do
      assert source_path in replay_source_paths
    end
  end

  test "strategy ignores generic review rows on provider-reservation summaries" do
    summary = %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "rows" => [],
      "provider_reservation_request_rows" => [],
      "provider_reservation_review_rows" => [],
      "review_rows" => [
        %{
          "contact_id" => "shadow_provider_review_contact",
          "allocation_status" => "deferred",
          "effective_allocation_status" => "deferred",
          "allocation_reason" => "same_station_contention",
          "ground_station_id" => "shadow_station",
          "direction" => "downlink"
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(
            "source_contact_allocation_provider_reservation_request_summary",
            summary
          ),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(
             artifact,
             "derived_contact_allocation_pressure_deferred_shadow_provider_review_contact"
           )
  end

  test "strategy rejects provider-review subset rows absent from canonical rows" do
    summary = %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "provider_reservation_request_status" => "review_required",
      "rows" => [],
      "provider_reservation_request_rows" => [],
      "provider_reservation_review_rows" => [
        %{
          "contact_id" => "stale_provider_subset_contact",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "allocation_reason" => "selected_by_contention_resolution",
          "ground_station_id" => "stale_station",
          "direction" => "downlink",
          "station_reservation_id" => "stale_reservation",
          "station_reservation_match_status" => "overlap"
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(
            "source_contact_allocation_provider_reservation_request_summary",
            summary
          ),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(
             artifact,
             "derived_contact_allocation_pressure_provider_reservation_review_required_stale_provider_subset_contact"
           )
  end

  defp contact_allocation_provider_reservation_request_summary_fixture(prefix) do
    request_row = %{
      "contact_id" => "#{prefix}_dl_reserved_owner",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_1",
      "station_reservation_match_status" => "matched",
      "station_reservation_status" => "confirmed"
    }

    review_row = %{
      "contact_id" => "#{prefix}_dl_review_overlap",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_review",
      "station_reservation_match_status" => "overlap",
      "station_reservation_status" => "confirmed"
    }

    %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" =>
        "campaign_planner_test.#{prefix}.contact_allocation_provider_reservation_request_summary",
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["#{prefix}_dl_reserved_owner"],
      "provider_reservation_review_contact_ids" => ["#{prefix}_dl_review_overlap"],
      "provider_reservation_no_request_contact_ids" => ["#{prefix}_dl_unreserved"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_review_overlap"]
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["#{prefix}_dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_dl_review_overlap"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["#{prefix}_reservation_1"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_reservation_review"]
      },
      "provider_reservation_request_rows" => [request_row],
      "provider_reservation_review_rows" => [review_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_provider_reservation_request_fixture"}
    }
  end
end
