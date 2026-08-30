defmodule OrbitalDynamics.Validation.CandidateRefreshStationAllocationReplayFixtures do
  alias OrbitalDynamics.Communications.ContactAllocation
  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [result_set: 1]

  def candidate_refresh_station_calendar_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_station_calendar_fixture())
  end

  def candidate_refresh_station_calendar_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_station_calendar_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_station_calendar_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-station-calendar-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [
          %{
            "id" => "station_calendar:dl_unavailable",
            "contact_id" => "dl_unavailable",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "station_calendar_entry_id" => "station_entry_unavailable",
            "station_calendar_status" => "unavailable"
          },
          %{
            "id" => "station_calendar:dl_reserved",
            "contact_id" => "dl_reserved",
            "ground_station_id" => "dss_43",
            "direction" => "uplink",
            "station_calendar_entry_id" => "station_entry_reserved",
            "station_reservation_id" => "reservation_dss_43",
            "station_reserved_by" => "ops_team_b",
            "station_reservation_expires_at_s" => 1800.0,
            "station_availability" => "reserved",
            "station_calendar_status" => "reserved"
          },
          %{
            "id" => "station_calendar:dl_reduced",
            "contact_id" => "dl_reduced",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "station_calendar_entry_id" => "station_entry_reduced",
            "capacity_fraction" => 0.4,
            "station_availability" => "reduced_capacity",
            "station_calendar_status" => "reduced_capacity"
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "station_calendar_provider_contention:equator_prime:1",
            "provider_ids" => ["ops_calendar", "partner_calendar"],
            "provider_entry_ids" => ["provider_entry_ops", "provider_entry_partner"],
            "ground_station_id" => "equator_prime",
            "capacity_fraction" => 0.25,
            "directions" => ["Down Link", "Track-ing"],
            "source_station_calendar_entries" => [
              %{"id" => "provider_a", "ground_station_id" => "equator_prime"},
              %{"id" => "provider_b", "ground_station_id" => "dss_43"}
            ]
          }
        ],
        "station_calendar_status_counts" => %{"stale_status" => 99},
        "affected_contact_ground_station_counts" => %{"stale_station" => 99},
        "affected_contact_availability_counts" => %{"stale_availability" => 99},
        "provider_calendar_contention_provider_counts" => %{"stale_provider" => 99},
        "provider_calendar_contention_ground_station_counts" => %{"stale_station" => 99},
        "provider_calendar_contention_provider_entry_ids_by_provider" => %{
          "stale_provider" => ["stale_provider_entry"]
        },
        "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_provider_entry"]
        },
        "provider_calendar_contention_provider_entry_ids_by_direction" => %{
          "stale_direction" => ["stale_provider_entry"]
        },
        "provenance" => %{"trust_boundary" => "ops_station_calendar"}
      }
    }
  end

  def candidate_refresh_contact_allocation_contradiction_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_contact_allocation_contradiction_fixture()
    )
  end

  def candidate_refresh_contact_allocation_resource_selection_challenge_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_contact_allocation_resource_selection_challenge_fixture()
    )
  end

  def candidate_refresh_contact_allocation_resource_selection_challenge_fixture do
    contact_allocation_resource_selection_result_set()
    |> CandidateRefresh.build(
      candidate_refresh:
        candidate_refresh_contact_allocation_resource_selection_challenge_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_contact_allocation_resource_selection_challenge_request do
    blocked_contact_id = "leo_1_downlink_equator_prime_1"
    cross_spacecraft_contact_id = "leo_2_downlink_dss_43_1"

    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-contact-allocation-resource-selection-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [
          %{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"},
          %{"spacecraft_id" => "sat_2", "scenario_id" => "leo_2"}
        ],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{"min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_contact_allocation_report" =>
        candidate_refresh_contact_allocation_resource_selection_challenge_report(
          blocked_contact_id,
          cross_spacecraft_contact_id
        ),
      "prior_candidate_activities" => [
        %{
          "id" => blocked_contact_id,
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
        }
      ]
    }
  end

  def candidate_refresh_contact_allocation_resource_selection_challenge_report(
        blocked_contact_id,
        cross_spacecraft_contact_id
      ) do
    contacts = [
      %{
        id: blocked_contact_id,
        type: :downlink,
        direction: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        station_id: :equator_prime,
        starts_at_s: 300.0,
        ends_at_s: 420.0
      },
      %{
        id: cross_spacecraft_contact_id,
        type: :downlink,
        direction: :downlink,
        scenario_id: :leo_2,
        spacecraft_id: :sat_1,
        station_id: :dss_43,
        starts_at_s: 320.0,
        ends_at_s: 440.0
      }
    ]

    resource_summaries = [
      %{
        spacecraft_id: :sat_1,
        antenna_available: false,
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :allocation_resource_challenge}
      }
    ]

    {_allocated_contacts, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "validation.contact_allocation_resource_selection",
        resource_summaries: resource_summaries
      )

    report
    |> Map.put("source_artifact_id", "allocation-resource-selection-challenge")
    |> Map.put(
      "report_id",
      "contact_allocation:resource_selection:stale_aggregate_challenge"
    )
    |> Map.put("resource_blocked_contact_ids_by_spacecraft_id", %{
      "sat_2" => [cross_spacecraft_contact_id],
      "stale_spacecraft" => [blocked_contact_id]
    })
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_contact_allocation_resource_selection_challenge"
    })
    |> normalize_resource_selection_report()
  end

  def candidate_refresh_contact_allocation_contradiction_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_contact_allocation_contradiction_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_contact_allocation_contradiction_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-provider-calendar-reservation-allocation-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_station_calendar_report" =>
        "study_results/station_calendar_report_v1.json"
        |> read_json!()
        |> normalize_station_calendar_report(),
      "source_contact_allocation_reservation_conflict_summary" =>
        "study_results/contact_allocation_reservation_conflict_summary_v1.json"
        |> read_json!()
        |> normalize_reservation_conflict_summary(),
      "source_contact_allocation_provider_reservation_request_summary" =>
        "study_results/contact_allocation_provider_reservation_request_summary_v1.json"
        |> read_json!()
        |> normalize_provider_reservation_request_summary()
    }
  end

  defp normalize_resource_selection_report(report) do
    report
    |> Map.take([
      "schema_contract",
      "model",
      "source",
      "input_contact_count",
      "allocated_contact_count",
      "deferred_contact_count",
      "blocked_contact_count",
      "rows",
      "station_calendar_report",
      "contact_filter_report",
      "contact_contention_report",
      "contact_contention_resolution_report",
      "assumptions",
      "source_artifact_id",
      "report_id",
      "resource_blocked_contact_ids_by_spacecraft_id",
      "provenance"
    ])
    |> Map.merge(minimal_resource_selection_nested_reports())
    |> update_in(["rows"], fn rows -> Enum.map(rows, &normalize_resource_selection_row/1) end)
  end

  defp minimal_resource_selection_nested_reports do
    %{
      "station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "model" => "campaign_ground_network_interval_overlay",
        "input_contact_count" => 0,
        "calendar_entry_count" => 0,
        "affected_contact_count" => 0,
        "affected_contacts" => [],
        "assumptions" => %{}
      },
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "thin_ground_network_availability_filter",
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "suppressed_candidates" => []
      },
      "contact_contention_report" => %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "single_station_interval_overlap",
        "input_contact_count" => 0,
        "conflicted_contact_count" => 0,
        "conflict_group_count" => 0,
        "conflict_groups" => []
      },
      "contact_contention_resolution_report" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "model" => "deterministic_contact_contention_recommendation",
        "policy" => %{},
        "conflict_group_count" => 0,
        "recommendation_count" => 0,
        "recommendations" => []
      }
    }
  end

  defp normalize_resource_selection_row(row) do
    row
    |> Map.take([
      "id",
      "contact_id",
      "allocation_status",
      "effective_allocation_status",
      "spacecraft_id",
      "resource_blocking_dimension",
      "source_resource_suppression"
    ])
    |> update_in(["source_resource_suppression"], fn suppression ->
      Map.take(suppression, ["resource_blocking_dimension", "resource_provenance"])
    end)
  end

  defp normalize_station_calendar_report(report) do
    report
    |> Map.take([
      "schema_contract",
      "model",
      "affected_contacts",
      "provider_calendar_contention_groups"
    ])
    |> update_in(["affected_contacts"], fn rows ->
      Enum.map(rows, fn row ->
        Map.take(row, [
          "id",
          "contact_id",
          "direction",
          "ground_station_id",
          "station_calendar_entry_id",
          "station_calendar_status",
          "station_availability",
          "status",
          "capacity_fraction"
        ])
      end)
    end)
    |> update_in(["provider_calendar_contention_groups"], fn groups ->
      Enum.map(groups, &normalize_provider_contention_group/1)
    end)
  end

  defp normalize_provider_contention_group(group) do
    group
    |> Map.take([
      "id",
      "provider_ids",
      "provider_entry_ids",
      "ground_station_id",
      "source_station_calendar_entries"
    ])
    |> update_in(["source_station_calendar_entries"], fn entries ->
      Enum.map(entries, &Map.take(&1, ["id", "capacity_fraction"]))
    end)
  end

  defp normalize_reservation_conflict_summary(summary) do
    summary
    |> Map.take([
      "schema_contract",
      "model",
      "source",
      "source_artifact_type",
      "rows",
      "reservation_conflict_contact_count",
      "reservation_conflict_contact_ids",
      "reservation_conflict_match_status_counts",
      "reservation_conflict_contact_ids_by_match_status",
      "reservation_conflict_reservation_ids_by_match_status",
      "reservation_conflict_contact_ids_by_direction",
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
      "station_reservation_expiration_now_s",
      "station_reservation_expiration_status_counts"
    ])
    |> update_in(["rows"], &Enum.map(&1, fn row -> normalize_reservation_row(row) end))
  end

  defp normalize_provider_reservation_request_summary(summary) do
    summary
    |> Map.take([
      "schema_contract",
      "model",
      "source",
      "source_artifact_type",
      "rows",
      "provider_reservation_candidate_contact_count",
      "provider_reservation_request_contact_count",
      "provider_reservation_review_contact_count",
      "provider_reservation_no_request_contact_count",
      "provider_reservation_request_status",
      "provider_reservation_request_status_counts",
      "provider_reservation_request_contact_ids",
      "provider_reservation_review_contact_ids",
      "provider_reservation_no_request_contact_ids",
      "provider_reservation_request_contact_ids_by_direction",
      "provider_reservation_review_contact_ids_by_direction",
      "provider_reservation_no_request_contact_ids_by_direction",
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
    ])
    |> update_in(["rows"], &Enum.map(&1, fn row -> normalize_reservation_row(row) end))
  end

  defp normalize_reservation_row(row) do
    Map.take(row, [
      "id",
      "contact_id",
      "direction",
      "ground_station_id",
      "allocation_status",
      "effective_allocation_status",
      "review_status",
      "station_reservation_match_status",
      "station_reservation_expires_at_s",
      "station_reservation_id"
    ])
  end

  defp contact_allocation_resource_selection_result_set do
    ResultSet.new!(%{
      study_id: :validation,
      trajectory_results: [],
      event_results: [
        access_event_result(:leo_1, :equator_prime, 300.0, 420.0),
        access_event_result(:leo_2, :dss_43, 320.0, 440.0)
      ],
      errors: [],
      assumptions: %{
        propagator: OrbitalDynamics.Propagators.TwoBody,
        outputs: [:access_windows]
      },
      metadata: %{}
    })
  end

  defp access_event_result(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: [
        %{
          type: :ground_station_access,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            max_elevation_deg: 70.0,
            minimum_elevation_deg: 5.0,
            sample_count: 4
          }
        }
      ],
      source: %{ground_station_id: ground_station_id}
    }
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
