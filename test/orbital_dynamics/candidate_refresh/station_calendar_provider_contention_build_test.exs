defmodule OrbitalDynamics.CandidateRefresh.StationCalendarProviderContentionBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CandidateRefresh,
    Epoch,
    ResultSet,
    Schema
  }

  test "replays station calendar provider contention groups into ground network state" do
    report = station_calendar_provider_contention_report()

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_station_calendar_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert [suppressed] = artifact["contact_filter_report"]["suppressed_candidates"]

    assert Map.take(suppressed, [
             "id",
             "suppressed_reason",
             "station_calendar_entry_id",
             "station_calendar_reservation_ids",
             "station_calendar_reserved_by",
             "station_calendar_reservation_statuses",
             "station_calendar_reservation_expires_at_s",
             "station_contention_status"
           ]) == %{
             "id" => "leo_1_downlink_equator_prime_1",
             "suppressed_reason" => "ground_station_reserved",
             "station_calendar_entry_id" =>
               "station_calendar_provider_contention:equator_prime:1",
             "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
             "station_calendar_reserved_by" => ["network_a", "network_b"],
             "station_calendar_reservation_statuses" => ["confirmed", "planned"],
             "station_calendar_reservation_expires_at_s" => [360.0, 480.0],
             "station_contention_status" => "provider_calendar_overlap"
           }

    assert get_in(suppressed, [
             "source_station_calendar_overlaps",
             Access.at(0),
             "source_station_calendar_entry",
             "source_station_calendar_provider_contention",
             "id"
           ]) == "station_calendar_provider_contention:equator_prime:1"

    assert get_in(suppressed, [
             "source_station_calendar_overlaps",
             Access.at(0),
             "source_station_calendar_entry",
             "source_station_calendar_provider_contention",
             "provider_calendar_contention_status"
           ]) == "provider_calendar_overlap"

    assert get_in(suppressed, [
             "source_station_calendar_overlaps",
             Access.at(0),
             "source_station_calendar_entry",
             "source_station_calendar_provider_contention",
             "reservation_ids"
           ]) == ["reservation_a", "reservation_b"]

    assert get_in(suppressed, [
             "source_station_calendar_entry",
             "station_calendar_reservation_expires_at_s"
           ]) == [360.0, 480.0]

    assert [
             %{"id" => "equator_reserved_a", "reservation_expires_at_s" => 360.0},
             %{"id" => "equator_reserved_b", "reservation_expires_at_s" => 480.0}
           ] =
             get_in(suppressed, [
               "source_station_calendar_overlaps",
               Access.at(0),
               "source_station_calendar_entry",
               "source_station_calendar_entries"
             ])

    assert %{
             "provider_calendar_contention_group_count" => 1,
             "provider_calendar_contention_provider_counts" => %{
               "ops_calendar" => 1
             },
             "provider_calendar_contention_ground_station_counts" => %{
               "equator_prime" => 1
             }
           } = get_in(artifact, ["provenance", "source_reports", "station_calendar_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays provider contention capacity-pack fractions as station capacity" do
    report =
      station_calendar_provider_contention_report()
      |> update_in(["provider_calendar_contention_groups", Access.at(0)], fn group ->
        group
        |> Map.put("availabilities", [])
        |> Map.put("reservation_ids", [])
        |> Map.put("reserved_by", [])
        |> Map.put("reservation_statuses", [])
        |> Map.put("reservation_expires_at_s", [])
        |> Map.put("capacity_pack_capacity_fraction", 0.0)
        |> Map.update!("source_station_calendar_entries", fn entries ->
          Enum.map(entries, fn entry ->
            entry
            |> Map.put("availability", "available")
            |> Map.delete("reservation_id")
            |> Map.delete("reserved_by")
            |> Map.delete("reservation_status")
            |> Map.delete("reservation_expires_at_s")
          end)
        end)
      end)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_station_calendar_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "suppressed_reason" => "ground_station_capacity_zero",
               "station_calendar_entry_id" =>
                 "station_calendar_provider_contention:equator_prime:1",
               "source_station_calendar_entry" => %{
                 "source_station_calendar_provider_contention" => %{
                   "capacity_pack_capacity_fraction" => capacity_pack_capacity_fraction
                 }
               }
             }
           ] = artifact["contact_filter_report"]["suppressed_candidates"]

    assert capacity_pack_capacity_fraction == 0.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "infers provider contention direction scope from source station-calendar entries" do
    report =
      station_calendar_provider_contention_report()
      |> update_in(["provider_calendar_contention_groups", Access.at(0)], fn group ->
        source_entries =
          group["source_station_calendar_entries"]
          |> Enum.map(&Map.put(&1, "directions", ["uplink"]))

        group
        |> Map.delete("directions")
        |> Map.delete("provider_calendar_contention_directions")
        |> Map.put("source_station_calendar_entries", source_entries)
      end)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_station_calendar_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1"
           ]

    assert artifact["contact_filter_report"]["suppressed_candidates"] == []

    report =
      update_in(report, ["provider_calendar_contention_groups", Access.at(0)], fn group ->
        source_entries =
          group["source_station_calendar_entries"]
          |> Enum.map(fn entry ->
            entry
            |> Map.delete("direction")
            |> Map.put("directions", ["DL"])
          end)

        Map.put(group, "source_station_calendar_entries", source_entries)
      end)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_station_calendar_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "suppressed_reason" => "ground_station_reserved",
               "station_calendar_directions" => ["downlink"],
               "source_station_calendar_entry" => %{
                 "directions" => ["downlink"]
               }
             }
           ] = artifact["contact_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end

  defp station_calendar_provider_contention_report do
    %{
      "schema_contract" => "station_calendar_report.v1",
      "affected_contacts" => [],
      "provider_calendar_contention_groups" => [
        %{
          "id" => "station_calendar_provider_contention:equator_prime:1",
          "provider_calendar_contention_status" => "provider_calendar_overlap",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "entry_count" => 2,
          "entry_ids" => ["equator_reserved_a", "equator_reserved_b"],
          "provider_ids" => ["ops_calendar"],
          "provider_entry_ids" => ["equator_reserved_a", "equator_reserved_b"],
          "availabilities" => ["reserved"],
          "directions" => ["downlink"],
          "reservation_ids" => ["reservation_a", "reservation_b"],
          "reserved_by" => ["network_a", "network_b"],
          "reservation_statuses" => ["confirmed", "planned"],
          "reservation_expires_at_s" => [360.0, 480.0],
          "trust_boundary_statuses" => ["declared"],
          "source_station_calendar_entries" => [
            %{
              "id" => "equator_reserved_a",
              "ground_station_id" => "equator_prime",
              "availability" => "reserved",
              "directions" => ["downlink"],
              "starts_at_s" => 250.0,
              "ends_at_s" => 410.0,
              "reservation_id" => "reservation_a",
              "reserved_by" => "network_a",
              "reservation_status" => "confirmed",
              "reservation_expires_at_s" => 360.0,
              "provenance" => %{"trust_boundary" => "ground_partner_api"}
            },
            %{
              "id" => "equator_reserved_b",
              "ground_station_id" => "equator_prime",
              "availability" => "reserved",
              "directions" => ["downlink"],
              "starts_at_s" => 300.0,
              "ends_at_s" => 450.0,
              "reservation_id" => "reservation_b",
              "reserved_by" => "network_b",
              "reservation_status" => "planned",
              "reservation_expires_at_s" => 480.0,
              "provenance" => %{"trust_boundary" => "ground_partner_api"}
            }
          ]
        }
      ],
      "provider_calendar_contention_group_count" => 1,
      "provenance" => %{"trust_boundary" => "ground_partner_api"}
    }
  end
end
