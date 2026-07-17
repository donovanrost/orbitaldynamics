defmodule OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, ResultSet, Validation}

  import OrbitalDynamics.Validation.ContactContentionFixtures,
    only: [contact_contention_cross_station_fixture: 0]

  def result_set(assumptions) do
    ResultSet.new!(%{
      study_id: :validation,
      trajectory_results: [],
      event_results: [],
      errors: [],
      assumptions: assumptions,
      metadata: %{}
    })
  end

  def candidate_refresh_contact_contention_challenge_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_contact_contention_challenge_fixture())
  end

  def candidate_refresh_contact_contention_challenge_fixture do
    contact_contention_report =
      contact_contention_cross_station_fixture()
      |> update_in(["provenance"], fn provenance ->
        (provenance || %{})
        |> Map.put("trust_boundary", "generated_cross_station_spacecraft_contention_fixture")
      end)

    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh:
        candidate_refresh_contact_contention_challenge_request(contact_contention_report),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_contact_contention_challenge_request(contact_contention_report) do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-contact-contention-challenge",
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
      "source_contact_contention_report" => contact_contention_report
    }
  end

  def candidate_refresh_contact_intent_direction_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_contact_intent_direction_fixture())
  end

  def candidate_refresh_contact_intent_direction_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_contact_intent_direction_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_contact_intent_direction_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-contact-intent-direction-challenge",
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
      "source_contact_intents" => [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_direct_capacity",
          "activity_id" => "intent_direct_capacity",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "Down Link",
          "starts_at_s" => 10.0,
          "ends_at_s" => 70.0,
          "station_calendar_status" => "reserved",
          "cadence_import_status" => "ready_for_import",
          "policy_classification" => "review_only",
          "required_capacity_fraction" => 0.25,
          "capacity_pack_required_capacity_fraction" => 99.0,
          "direction_routing" => %{
            "stale_direction" => %{"capacity_pack_contact_ids" => ["stale_contact_intent"]}
          },
          "provenance" => %{
            "trust_boundary" => "generated_contact_intent_direction_fixture"
          }
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_nested_capacity",
          "activity_id" => "intent_nested_capacity",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "tracking_pass",
          "starts_at_s" => 80.0,
          "ends_at_s" => 130.0,
          "station_availability" => "unavailable",
          "cadence_import_status" => "blocked",
          "policy_classification" => "blocked_by_policy",
          "capacity_model" => %{"station_capacity_requirement" => "0.4"},
          "provenance" => %{
            "trust_boundary" => "generated_contact_intent_direction_fixture"
          }
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_station_only",
          "activity_id" => "intent_station_only",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "Command",
          "starts_at_s" => 140.0,
          "ends_at_s" => 180.0,
          "provenance" => %{
            "trust_boundary" => "generated_contact_intent_direction_fixture"
          }
        }
      ]
    }
  end
end
