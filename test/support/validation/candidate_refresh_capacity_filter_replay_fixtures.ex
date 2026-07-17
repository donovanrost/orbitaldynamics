defmodule OrbitalDynamics.Validation.CandidateRefreshCapacityFilterReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [result_set: 1]

  def candidate_refresh_link_capacity_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_link_capacity_fixture())
  end

  def candidate_refresh_link_capacity_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_link_capacity_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_link_capacity_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-link-capacity-replay-challenge",
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
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => [
          %{
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "capacity_adjusted_throughput_mb" => 65.0,
            "selected_capacity_adjusted_throughput_mb" => 25.0,
            "unused_capacity_adjusted_throughput_mb" => 40.0,
            "selected_downlink_shortfall_mb" => 12.0,
            "actual_throughput_mb" => 21.0,
            "source_window_id" => "window_alpha",
            "station_calendar_entry_ids" => ["station_entry_alpha", "station_entry_beta"],
            "station_calendar_provider_entry_ids" => [
              "provider_entry_alpha",
              "provider_entry_beta"
            ],
            "selected_contacts" => [
              %{
                "id" => "contact_alpha",
                "direction" => "Down Link",
                "source_window_id" => "window_alpha",
                "station_calendar_entry_id" => "station_entry_alpha",
                "station_calendar_provider_entry_id" => "provider_entry_alpha"
              },
              %{
                "id" => "contact_beta",
                "direction" => "tracking_pass",
                "source_window_id" => "window_beta",
                "station_calendar_entry_id" => "station_entry_beta",
                "station_calendar_provider_entry_id" => "provider_entry_beta"
              }
            ],
            "actual_throughput_contact" => %{
              "id" => "contact_alpha",
              "source_window_id" => "window_alpha",
              "station_calendar_entry_id" => "station_entry_alpha",
              "station_calendar_provider_entry_id" => "provider_entry_alpha"
            },
            "downlink_requirement_status" => "selected_shortfall",
            "actual_downlink_requirement_status" => "actual_met"
          },
          %{
            "spacecraft_id" => "leo_2",
            "ground_station_id" => "dss_43",
            "direction" => "s-band command",
            "capacity_adjusted_throughput_mb" => 20.0,
            "selected_capacity_adjusted_throughput_mb" => 15.0,
            "unused_capacity_adjusted_throughput_mb" => 5.0,
            "actual_throughput_mb" => 18.0,
            "actual_downlink_shortfall_mb" => 7.0,
            "source_window_ids" => ["window_gamma"],
            "station_calendar_entry_id" => "station_entry_gamma",
            "station_calendar_provider_entry_id" => "provider_entry_gamma",
            "selected_contact" => %{
              "id" => "contact_gamma",
              "source_window_id" => "window_gamma",
              "station_calendar_entry_id" => "station_entry_gamma",
              "station_calendar_provider_entry_id" => "provider_entry_gamma"
            },
            "actual_throughput_contact" => %{
              "id" => "contact_gamma",
              "source_window_id" => "window_gamma",
              "station_calendar_entry_id" => "station_entry_gamma",
              "station_calendar_provider_entry_id" => "provider_entry_gamma"
            },
            "downlink_requirement_status" => "selected_met",
            "actual_downlink_requirement_status" => "actual_shortfall"
          }
        ],
        "capacity_adjusted_throughput_mb_total" => 999.0,
        "selected_capacity_adjusted_throughput_mb_total" => 999.0,
        "unused_capacity_adjusted_throughput_mb_total" => 999.0,
        "contact_ids_by_requirement_status" => %{"stale_status" => ["stale_contact"]},
        "selected_contact_ids" => ["stale_selected_contact"],
        "actual_throughput_contact_ids" => ["stale_actual_contact"],
        "provenance" => %{"trust_boundary" => "link_capacity_replay_report"}
      }
    }
  end

  def candidate_refresh_resource_filter_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_resource_filter_fixture())
  end

  def candidate_refresh_resource_filter_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_resource_filter_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_resource_filter_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-resource-filter-replay-challenge",
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
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "obs_payload_block",
            "spacecraft_id" => "leo_1",
            "resource_id" => "payload_1",
            "suppressed_reason" => "payload_unavailable",
            "resource_blocking_dimension" => "payload"
          },
          %{
            "id" => "downlink_margin_block",
            "direction" => "Down Link",
            "spacecraft_id" => "leo_1",
            "resource_summary_id" => "downlink_budget",
            "suppressed_reason" => "downlink_margin_low",
            "resource_blocking_dimension" => "communications"
          },
          %{
            "id" => "power_block",
            "activity_context" => %{"direction" => "s-band command"},
            "spacecraft_id" => "leo_2",
            "battery_id" => "battery_main",
            "suppressed_reason" => "power_margin_low",
            "resource_blocking_dimension" => "power"
          }
        ],
        "invalid_resource_summary_inputs" => [%{"resource_summary_id" => "bad_summary"}],
        "suppressed_reason_counts" => %{"stale_reason" => 99},
        "resource_filter_spacecraft_counts" => %{"stale_spacecraft" => 99},
        "candidate_ids_by_spacecraft" => %{"stale_spacecraft" => ["stale_candidate"]},
        "resource_filter_resource_counts" => %{"stale_resource" => 99},
        "candidate_ids_by_resource" => %{"stale_resource" => ["stale_candidate"]},
        "resource_filter_blocking_dimension_counts" => %{"stale_dimension" => 99},
        "candidate_ids_by_blocking_dimension" => %{"stale_dimension" => ["stale_candidate"]},
        "direction_counts" => %{"stale_direction" => 99},
        "candidate_ids_by_direction" => %{"stale_direction" => ["stale_candidate"]},
        "candidate_ids_by_suppressed_reason" => %{"stale_reason" => ["stale_candidate"]},
        "provenance" => %{"trust_boundary" => "resource_filter_replay_report"}
      }
    }
  end
end
