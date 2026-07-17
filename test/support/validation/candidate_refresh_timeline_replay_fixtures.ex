defmodule OrbitalDynamics.Validation.CandidateRefreshTimelineReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, Timeline, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [result_set: 1]

  import OrbitalDynamics.Validation.TimelineActivityStateFixtures,
    only: [
      timeline_activity_lifecycle_state_fixture: 0,
      timeline_lifecycle_state_summary_fixture: 0
    ]

  def candidate_refresh_timeline_activity_precondition_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_timeline_activity_precondition_fixture()
    )
  end

  def candidate_refresh_timeline_activity_precondition_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_timeline_activity_precondition_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_timeline_activity_precondition_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-timeline-precondition-challenge",
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
      "source_timeline_activity_precondition_summary" =>
        candidate_refresh_timeline_activity_precondition_summaries()
    }
  end

  def candidate_refresh_timeline_activity_precondition_summaries do
    [
      %{
        id: :cmd_preflight,
        type: :command,
        payload_available: false,
        degraded: true,
        resource_blocking_dimension: :power,
        dependency_activity_ids: [:health_check_1, :obs_1, :obs_1],
        dependency_timeline_ids: [:"timeline:health_check_1", :"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict, :dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict", :"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_preflight"}
      }
      |> Timeline.activity_precondition_summary(),
      %{id: :bad_missing_type}
      |> Timeline.activity_precondition_summary()
    ]
    |> Enum.map(
      &Map.put(&1, "provenance", %{
        "trust_boundary" => "generated_timeline_precondition_fixture"
      })
    )
  end

  def candidate_refresh_timeline_lifecycle_state_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_timeline_lifecycle_state_fixture())
  end

  def candidate_refresh_timeline_lifecycle_state_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_timeline_lifecycle_state_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_timeline_lifecycle_state_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-timeline-lifecycle-challenge",
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
      "source_timeline_lifecycle_state_summary" =>
        candidate_refresh_timeline_lifecycle_state_summary()
    }
  end

  def candidate_refresh_timeline_lifecycle_state_summary do
    timeline_lifecycle_state_summary_fixture()
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_timeline_lifecycle_fixture"
    })
  end

  def candidate_refresh_timeline_activity_lifecycle_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_timeline_activity_lifecycle_fixture())
  end

  def candidate_refresh_timeline_activity_lifecycle_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_timeline_activity_lifecycle_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_timeline_activity_lifecycle_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-timeline-activity-lifecycle-challenge",
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
      "source_timeline_activity_lifecycle_state" =>
        candidate_refresh_timeline_activity_lifecycle_state()
    }
  end

  def candidate_refresh_timeline_activity_lifecycle_state do
    timeline_activity_lifecycle_state_fixture()
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_timeline_activity_lifecycle_fixture"
    })
  end

  def candidate_refresh_timeline_transition_application_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_timeline_transition_application_fixture()
    )
  end

  def candidate_refresh_timeline_transition_application_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_timeline_transition_application_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_timeline_transition_application_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-transition-application-challenge",
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
      "source_timeline_transition_application_summary" =>
        candidate_refresh_timeline_transition_application_summary()
    }
  end

  def candidate_refresh_timeline_transition_application_summary do
    activity = %{
      id: :obs_waiting_on_gate,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_gate"}
    }

    [activity]
    |> Timeline.transition_application_summary([activity])
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_timeline_transition_application_fixture"
    })
  end
end
