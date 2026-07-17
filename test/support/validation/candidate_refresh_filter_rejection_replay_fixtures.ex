defmodule OrbitalDynamics.Validation.CandidateRefreshFilterRejectionReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [result_set: 1]

  def candidate_refresh_contact_filter_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_contact_filter_fixture())
  end

  def candidate_refresh_contact_filter_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_contact_filter_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_contact_filter_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-contact-filter-replay-challenge",
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
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "dl_station_unavailable",
            "direction" => "Down Link",
            "ground_station_id" => "equator_prime",
            "station_calendar_entry_id" => "entry_unavailable",
            "station_calendar_provider_entry_id" => "provider_entry_unavailable",
            "suppressed_reason" => "ground_station_unavailable"
          },
          %{
            "id" => "dl_station_reserved",
            "direction" => "s-band command",
            "ground_station_id" => "dss_43",
            "station_calendar_entry_id" => "entry_reserved",
            "station_calendar_provider_entry_id" => "provider_entry_reserved",
            "station_reservation_id" => "reservation_dss_43",
            "suppressed_reason" => "ground_station_reserved"
          },
          %{
            "id" => "dl_station_capacity_zero",
            "direction" => "tracking_pass",
            "ground_station_id" => "dss_43",
            "station_calendar_entry_id" => "entry_capacity_zero",
            "station_calendar_provider_entry_id" => "provider_entry_capacity_zero",
            "suppressed_reason" => "ground_station_capacity_zero"
          },
          %{
            "id" => "invalid_contact",
            "direction" => "health-check",
            "suppressed_reason" => "invalid_contact_input",
            "required_operator_action" => "review_invalid_contact_filter_input"
          }
        ],
        "suppressed_reason_counts" => %{"stale_reason" => 99},
        "direction_counts" => %{"stale_direction" => 99},
        "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact"]},
        "station_suppression_ground_station_counts" => %{"stale_station" => 99},
        "station_suppression_availability_counts" => %{"stale_availability" => 99},
        "station_suppression_status_counts" => %{"stale_status" => 99},
        "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_provider_entry"]
        },
        "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
          "stale_availability" => ["stale_provider_entry"]
        },
        "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
          "stale_status" => ["stale_provider_entry"]
        },
        "provenance" => %{"trust_boundary" => "contact_filter_replay_report"}
      }
    }
  end

  def candidate_refresh_candidate_rejection_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_candidate_rejection_fixture())
  end

  def candidate_refresh_candidate_rejection_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_candidate_rejection_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_candidate_rejection_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-candidate-rejection-replay-challenge",
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
      "source_candidate_rejection_report" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "row_count" => 2,
        "rejected_count" => 2,
        "reviewable_count" => 1,
        "invalid_candidate_input_count" => 1,
        "rejection_reason_counts" => %{
          "stale_rejection_reason" => 99
        },
        "required_operator_action_counts" => %{
          "stale_required_action" => 99
        },
        "rows" => [
          %{
            "id" => "candidate_rejection:dl_reserved",
            "candidate_id" => "dl_reserved",
            "ground_station_id" => "equator_prime",
            "rejection_reasons" => ["station_reserved"],
            "primary_rejection_reason" => "station_reserved",
            "required_operator_action" => "review_candidate_rejection"
          },
          %{
            "id" => "candidate_rejection:bad_candidate",
            "candidate_id" => "bad_candidate",
            "activity_context" => %{"ground_station_id" => "dss_43"},
            "rejection_reasons" => ["invalid_candidate_input"],
            "primary_rejection_reason" => "invalid_candidate_input",
            "required_operator_action" => "none"
          }
        ],
        "provenance" => %{"trust_boundary" => "candidate_rejection_replay_report"}
      }
    }
  end
end
