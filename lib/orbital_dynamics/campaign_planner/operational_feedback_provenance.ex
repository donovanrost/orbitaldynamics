defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedbackProvenance do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CandidateRefreshOperationalFeedback,
    DirectOperationalFeedback,
    OperationalFeedbackSourceMetadata,
    OperationalFeedbackSources,
    RealizedActivitiesFeedbackSource
  }

  @merge_order [
    "prior_plan.source_timeline_feedback_report.operational_feedback",
    "prior_plan.planned_activity",
    "prior_plan.proposed_contact",
    "prior_plan.realized_activity",
    "prior_plan.operational_timeline_report.rows",
    "prior_plan.command_window_report.rows",
    "prior_plan.maneuver_review_report.rows",
    "prior_plan.cadence_import_manifest.rows.source_operational_feedback",
    "prior_plan.cadence_import_manifest.rows.source_review_row",
    "prior_plan.operator_review_package.rows.source_operational_feedback",
    "prior_plan.operator_review_package.rows",
    "prior_plan.operational_feedback",
    "mission_state.realized_activities",
    "mission_state.realized_activity",
    "mission_state.planned_activity",
    "mission_state.proposed_contact",
    "mission_state.operational_timeline_report.rows",
    "mission_state.command_window_report.rows",
    "mission_state.maneuver_review_report.rows",
    "mission_state.cadence_import_manifest.rows.source_operational_feedback",
    "mission_state.cadence_import_manifest.rows.source_review_row",
    "mission_state.operator_review_package.rows.source_operational_feedback",
    "mission_state.operator_review_package.rows",
    "mission_state.timeline_feedback_report.operational_feedback",
    "mission_state.operational_feedback",
    "request.candidate_refresh.operational_feedback",
    "request.operational_feedback"
  ]

  def build(
        prior_plan,
        mission_state,
        candidate_refresh,
        explicit_operational_feedback,
        realized_activities_operational_feedback,
        operational_feedback
      ) do
    build(
      prior_plan,
      mission_state,
      candidate_refresh,
      explicit_operational_feedback,
      realized_activities_operational_feedback,
      operational_feedback,
      default_callbacks()
    )
  end

  def build(
        prior_plan,
        mission_state,
        candidate_refresh,
        explicit_operational_feedback,
        realized_activities_operational_feedback,
        operational_feedback,
        callbacks
      ) do
    prior_source_feedback =
      callback!(callbacks, :prior_plan_timeline_feedback_operational_feedback).(prior_plan)

    prior_planned_activity_feedback =
      callback!(callbacks, :prior_plan_planned_activity_operational_feedback).(prior_plan)

    prior_proposed_contact_feedback =
      callback!(callbacks, :prior_plan_proposed_contact_operational_feedback).(prior_plan)

    prior_realized_activity_feedback =
      callback!(callbacks, :prior_plan_realized_activity_operational_feedback).(prior_plan)

    prior_operational_timeline_feedback =
      callback!(callbacks, :prior_plan_operational_timeline_operational_feedback).(prior_plan)

    prior_command_window_feedback =
      callback!(callbacks, :prior_plan_command_window_operational_feedback).(prior_plan)

    prior_maneuver_review_feedback =
      callback!(callbacks, :prior_plan_maneuver_review_operational_feedback).(prior_plan)

    prior_cadence_import_source_feedback =
      callback!(callbacks, :prior_plan_cadence_import_source_operational_feedback).(prior_plan)

    prior_cadence_import_feedback =
      callback!(callbacks, :prior_plan_cadence_import_operational_feedback).(prior_plan)

    prior_operator_review_source_feedback =
      callback!(callbacks, :prior_plan_operator_review_source_operational_feedback).(prior_plan)

    prior_operator_review_feedback =
      callback!(callbacks, :prior_plan_operator_review_operational_feedback).(prior_plan)

    mission_source_feedback =
      callback!(callbacks, :mission_state_timeline_feedback_operational_feedback).(mission_state)

    mission_planned_activity_feedback =
      callback!(callbacks, :mission_state_planned_activity_operational_feedback).(mission_state)

    mission_proposed_contact_feedback =
      callback!(callbacks, :mission_state_proposed_contact_operational_feedback).(mission_state)

    mission_realized_activity_feedback =
      callback!(callbacks, :mission_state_realized_activity_operational_feedback).(
        mission_state,
        prior_plan
      )

    mission_operational_timeline_feedback =
      callback!(callbacks, :mission_state_operational_timeline_operational_feedback).(
        mission_state
      )

    mission_command_window_feedback =
      callback!(callbacks, :mission_state_command_window_operational_feedback).(mission_state)

    mission_maneuver_review_feedback =
      callback!(callbacks, :mission_state_maneuver_review_operational_feedback).(mission_state)

    mission_cadence_import_source_feedback =
      callback!(callbacks, :mission_state_cadence_import_source_operational_feedback).(
        mission_state
      )

    mission_cadence_import_feedback =
      callback!(callbacks, :mission_state_cadence_import_operational_feedback).(mission_state)

    mission_operator_review_source_feedback =
      callback!(callbacks, :mission_state_operator_review_source_operational_feedback).(
        mission_state
      )

    mission_operator_review_feedback =
      callback!(callbacks, :mission_state_operator_review_operational_feedback).(mission_state)

    prior_feedback = callback!(callbacks, :prior_plan_direct_operational_feedback).(prior_plan)

    mission_feedback =
      callback!(callbacks, :mission_state_direct_operational_feedback).(mission_state)

    candidate_refresh_feedback =
      callback!(callbacks, :candidate_refresh_operational_feedback).(candidate_refresh)

    realized_activities = Map.get(mission_state, "realized_activities", [])

    sources =
      [
        source(
          callbacks,
          "prior_plan.source_timeline_feedback_report.operational_feedback",
          prior_source_feedback,
          callback!(callbacks, :prior_plan_timeline_feedback_source_metadata).(prior_plan)
        ),
        source(
          callbacks,
          "prior_plan.planned_activity",
          prior_planned_activity_feedback,
          callback!(callbacks, :prior_plan_planned_activity_source_metadata).(prior_plan)
        ),
        source(
          callbacks,
          "prior_plan.proposed_contact",
          prior_proposed_contact_feedback,
          callback!(callbacks, :prior_plan_proposed_contact_source_metadata).(prior_plan)
        ),
        source(
          callbacks,
          "prior_plan.realized_activity",
          prior_realized_activity_feedback,
          callback!(callbacks, :prior_plan_realized_activity_source_metadata).(prior_plan)
        ),
        source(
          callbacks,
          "prior_plan.operational_timeline_report.rows",
          prior_operational_timeline_feedback,
          callback!(callbacks, :prior_plan_operational_timeline_source_metadata).(prior_plan)
        ),
        source(
          callbacks,
          "prior_plan.command_window_report.rows",
          prior_command_window_feedback,
          callback!(callbacks, :prior_plan_command_window_source_metadata).(prior_plan)
        ),
        source(
          callbacks,
          "prior_plan.maneuver_review_report.rows",
          prior_maneuver_review_feedback,
          callback!(callbacks, :prior_plan_maneuver_review_source_metadata).(prior_plan)
        ),
        replay_source(
          callbacks,
          "prior_plan.cadence_import_manifest.rows.source_operational_feedback",
          prior_cadence_import_source_feedback,
          callback!(callbacks, :prior_plan_cadence_import_source_operational_feedback_metadata).(
            prior_plan
          ),
          callback!(callbacks, :prior_plan_cadence_import_all_operational_feedback_rows).(
            prior_plan
          )
        ),
        source(
          callbacks,
          "prior_plan.cadence_import_manifest.rows.source_review_row",
          prior_cadence_import_feedback,
          callback!(callbacks, :prior_plan_cadence_import_source_review_metadata).(prior_plan)
        ),
        replay_source(
          callbacks,
          "prior_plan.operator_review_package.rows.source_operational_feedback",
          prior_operator_review_source_feedback,
          callback!(callbacks, :prior_plan_operator_review_source_operational_feedback_metadata).(
            prior_plan
          ),
          callback!(callbacks, :prior_plan_operator_review_all_operational_feedback_rows).(
            prior_plan
          )
        ),
        source(
          callbacks,
          "prior_plan.operator_review_package.rows",
          prior_operator_review_feedback,
          callback!(callbacks, :prior_plan_operator_review_source_metadata).(prior_plan)
        ),
        source(
          callbacks,
          "prior_plan.operational_feedback",
          prior_feedback,
          callback!(callbacks, :prior_plan_direct_operational_feedback_metadata).(prior_plan)
        ),
        callback!(callbacks, :realized_activities_feedback_source).(
          realized_activities,
          realized_activities_operational_feedback,
          prior_plan
        ),
        source(
          callbacks,
          "mission_state.realized_activity",
          mission_realized_activity_feedback,
          callback!(callbacks, :mission_state_realized_activity_source_metadata).(
            mission_state,
            prior_plan
          )
        ),
        source(
          callbacks,
          "mission_state.planned_activity",
          mission_planned_activity_feedback,
          callback!(callbacks, :mission_state_planned_activity_source_metadata).(mission_state)
        ),
        source(
          callbacks,
          "mission_state.proposed_contact",
          mission_proposed_contact_feedback,
          callback!(callbacks, :mission_state_proposed_contact_source_metadata).(mission_state)
        ),
        source(
          callbacks,
          "mission_state.operational_timeline_report.rows",
          mission_operational_timeline_feedback,
          callback!(callbacks, :mission_state_operational_timeline_source_metadata).(
            mission_state
          )
        ),
        source(
          callbacks,
          "mission_state.command_window_report.rows",
          mission_command_window_feedback,
          callback!(callbacks, :mission_state_command_window_source_metadata).(mission_state)
        ),
        source(
          callbacks,
          "mission_state.maneuver_review_report.rows",
          mission_maneuver_review_feedback,
          callback!(callbacks, :mission_state_maneuver_review_source_metadata).(mission_state)
        ),
        replay_source(
          callbacks,
          "mission_state.cadence_import_manifest.rows.source_operational_feedback",
          mission_cadence_import_source_feedback,
          callback!(callbacks, :mission_state_cadence_import_source_operational_feedback_metadata).(
            mission_state
          ),
          callback!(callbacks, :mission_state_cadence_import_all_operational_feedback_rows).(
            mission_state
          )
        ),
        source(
          callbacks,
          "mission_state.cadence_import_manifest.rows.source_review_row",
          mission_cadence_import_feedback,
          callback!(callbacks, :mission_state_cadence_import_source_review_metadata).(
            mission_state
          )
        ),
        replay_source(
          callbacks,
          "mission_state.operator_review_package.rows.source_operational_feedback",
          mission_operator_review_source_feedback,
          callback!(
            callbacks,
            :mission_state_operator_review_source_operational_feedback_metadata
          ).(mission_state),
          callback!(callbacks, :mission_state_operator_review_all_operational_feedback_rows).(
            mission_state
          )
        ),
        source(
          callbacks,
          "mission_state.operator_review_package.rows",
          mission_operator_review_feedback,
          callback!(callbacks, :mission_state_operator_review_source_metadata).(mission_state)
        ),
        source(
          callbacks,
          "mission_state.timeline_feedback_report.operational_feedback",
          mission_source_feedback,
          callback!(callbacks, :mission_state_timeline_feedback_source_metadata).(mission_state)
        ),
        source(
          callbacks,
          "mission_state.operational_feedback",
          mission_feedback,
          callback!(callbacks, :mission_state_direct_operational_feedback_metadata).(
            mission_state
          )
        ),
        source(
          callbacks,
          "request.candidate_refresh.operational_feedback",
          candidate_refresh_feedback,
          callback!(callbacks, :candidate_refresh_operational_feedback_metadata).(
            candidate_refresh
          )
        ),
        source(callbacks, "request.operational_feedback", explicit_operational_feedback)
      ]
      |> Enum.reject(&is_nil/1)

    input_keys = callback!(callbacks, :operational_feedback_data_keys).(operational_feedback)

    {effective_sources, overridden_sources} =
      callback!(callbacks, :operational_feedback_source_resolution).(sources, input_keys)

    %{
      "model" => "deterministic_merge_explicit_overrides_mission_state_overrides_prior_plan",
      "merge_order" => @merge_order,
      "input_keys" => input_keys,
      "effective_sources" => effective_sources,
      "overridden_sources" => overridden_sources,
      "source_count" => length(sources),
      "sources" => sources,
      "explicit_request_override" =>
        callback!(callbacks, :operational_feedback_override?).(explicit_operational_feedback)
    }
  end

  defp source(callbacks, source, feedback, extra \\ %{}) do
    callback!(callbacks, :operational_feedback_source).(source, feedback, extra)
  end

  defp replay_source(callbacks, source, feedback, extra, rows) do
    callback!(callbacks, :operational_feedback_replay_source).(source, feedback, extra, rows)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      prior_plan_timeline_feedback_operational_feedback:
        &OperationalFeedbackSources.prior_plan_timeline_feedback_operational_feedback/1,
      prior_plan_planned_activity_operational_feedback:
        &OperationalFeedbackSources.prior_plan_planned_activity_operational_feedback/1,
      prior_plan_proposed_contact_operational_feedback:
        &OperationalFeedbackSources.prior_plan_proposed_contact_operational_feedback/1,
      prior_plan_realized_activity_operational_feedback:
        &OperationalFeedbackSources.prior_plan_realized_activity_operational_feedback/1,
      prior_plan_operational_timeline_operational_feedback:
        &OperationalFeedbackSources.prior_plan_operational_timeline_operational_feedback/1,
      prior_plan_command_window_operational_feedback:
        &OperationalFeedbackSources.prior_plan_command_window_operational_feedback/1,
      prior_plan_maneuver_review_operational_feedback:
        &OperationalFeedbackSources.prior_plan_maneuver_review_operational_feedback/1,
      prior_plan_cadence_import_source_operational_feedback:
        &OperationalFeedbackSources.prior_plan_cadence_import_source_operational_feedback/1,
      prior_plan_cadence_import_operational_feedback:
        &OperationalFeedbackSources.prior_plan_cadence_import_operational_feedback/1,
      prior_plan_operator_review_source_operational_feedback:
        &OperationalFeedbackSources.prior_plan_operator_review_source_operational_feedback/1,
      prior_plan_operator_review_operational_feedback:
        &OperationalFeedbackSources.prior_plan_operator_review_operational_feedback/1,
      mission_state_timeline_feedback_operational_feedback:
        &OperationalFeedbackSources.mission_state_timeline_feedback_operational_feedback/1,
      mission_state_planned_activity_operational_feedback:
        &OperationalFeedbackSources.mission_state_planned_activity_operational_feedback/1,
      mission_state_proposed_contact_operational_feedback:
        &OperationalFeedbackSources.mission_state_proposed_contact_operational_feedback/1,
      mission_state_realized_activity_operational_feedback:
        &OperationalFeedbackSources.mission_state_realized_activity_operational_feedback/2,
      mission_state_operational_timeline_operational_feedback:
        &OperationalFeedbackSources.mission_state_operational_timeline_operational_feedback/1,
      mission_state_command_window_operational_feedback:
        &OperationalFeedbackSources.mission_state_command_window_operational_feedback/1,
      mission_state_maneuver_review_operational_feedback:
        &OperationalFeedbackSources.mission_state_maneuver_review_operational_feedback/1,
      mission_state_cadence_import_source_operational_feedback:
        &OperationalFeedbackSources.mission_state_cadence_import_source_operational_feedback/1,
      mission_state_cadence_import_operational_feedback:
        &OperationalFeedbackSources.mission_state_cadence_import_operational_feedback/1,
      mission_state_operator_review_source_operational_feedback:
        &OperationalFeedbackSources.mission_state_operator_review_source_operational_feedback/1,
      mission_state_operator_review_operational_feedback:
        &OperationalFeedbackSources.mission_state_operator_review_operational_feedback/1,
      prior_plan_direct_operational_feedback: &DirectOperationalFeedback.prior_plan_feedback/1,
      mission_state_direct_operational_feedback:
        &DirectOperationalFeedback.mission_state_feedback/1,
      candidate_refresh_operational_feedback: &CandidateRefreshOperationalFeedback.feedback/1,
      operational_feedback_source: &OperationalFeedbackSourceMetadata.source/3,
      operational_feedback_replay_source: &OperationalFeedbackSourceMetadata.replay_source/4,
      realized_activities_feedback_source: &RealizedActivitiesFeedbackSource.source/3,
      prior_plan_timeline_feedback_source_metadata:
        &OperationalFeedbackSources.prior_plan_timeline_feedback_source_metadata/1,
      prior_plan_planned_activity_source_metadata:
        &OperationalFeedbackSources.prior_plan_planned_activity_source_metadata/1,
      prior_plan_proposed_contact_source_metadata:
        &OperationalFeedbackSources.prior_plan_proposed_contact_source_metadata/1,
      prior_plan_realized_activity_source_metadata:
        &OperationalFeedbackSources.prior_plan_realized_activity_source_metadata/1,
      prior_plan_operational_timeline_source_metadata:
        &OperationalFeedbackSources.prior_plan_operational_timeline_source_metadata/1,
      prior_plan_command_window_source_metadata:
        &OperationalFeedbackSources.prior_plan_command_window_source_metadata/1,
      prior_plan_maneuver_review_source_metadata:
        &OperationalFeedbackSources.prior_plan_maneuver_review_source_metadata/1,
      prior_plan_cadence_import_source_operational_feedback_metadata:
        &OperationalFeedbackSources.prior_plan_cadence_import_source_operational_feedback_metadata/1,
      prior_plan_cadence_import_source_review_metadata:
        &OperationalFeedbackSources.prior_plan_cadence_import_source_review_metadata/1,
      prior_plan_operator_review_source_operational_feedback_metadata:
        &OperationalFeedbackSources.prior_plan_operator_review_source_operational_feedback_metadata/1,
      prior_plan_operator_review_source_metadata:
        &OperationalFeedbackSources.prior_plan_operator_review_source_metadata/1,
      prior_plan_direct_operational_feedback_metadata:
        &DirectOperationalFeedback.prior_plan_metadata/1,
      prior_plan_cadence_import_all_operational_feedback_rows:
        &OperationalFeedbackSources.prior_plan_cadence_import_all_operational_feedback_rows/1,
      prior_plan_operator_review_all_operational_feedback_rows:
        &OperationalFeedbackSources.prior_plan_operator_review_all_operational_feedback_rows/1,
      mission_state_realized_activity_source_metadata:
        &OperationalFeedbackSources.mission_state_realized_activity_source_metadata/2,
      mission_state_planned_activity_source_metadata:
        &OperationalFeedbackSources.mission_state_planned_activity_source_metadata/1,
      mission_state_proposed_contact_source_metadata:
        &OperationalFeedbackSources.mission_state_proposed_contact_source_metadata/1,
      mission_state_operational_timeline_source_metadata:
        &OperationalFeedbackSources.mission_state_operational_timeline_source_metadata/1,
      mission_state_command_window_source_metadata:
        &OperationalFeedbackSources.mission_state_command_window_source_metadata/1,
      mission_state_maneuver_review_source_metadata:
        &OperationalFeedbackSources.mission_state_maneuver_review_source_metadata/1,
      mission_state_cadence_import_source_operational_feedback_metadata:
        &OperationalFeedbackSources.mission_state_cadence_import_source_operational_feedback_metadata/1,
      mission_state_cadence_import_source_review_metadata:
        &OperationalFeedbackSources.mission_state_cadence_import_source_review_metadata/1,
      mission_state_operator_review_source_operational_feedback_metadata:
        &OperationalFeedbackSources.mission_state_operator_review_source_operational_feedback_metadata/1,
      mission_state_operator_review_source_metadata:
        &OperationalFeedbackSources.mission_state_operator_review_source_metadata/1,
      mission_state_timeline_feedback_source_metadata:
        &OperationalFeedbackSources.mission_state_timeline_feedback_source_metadata/1,
      mission_state_direct_operational_feedback_metadata:
        &DirectOperationalFeedback.mission_state_metadata/1,
      mission_state_cadence_import_all_operational_feedback_rows:
        &OperationalFeedbackSources.mission_state_cadence_import_all_operational_feedback_rows/1,
      mission_state_operator_review_all_operational_feedback_rows:
        &OperationalFeedbackSources.mission_state_operator_review_all_operational_feedback_rows/1,
      candidate_refresh_operational_feedback_metadata:
        &CandidateRefreshOperationalFeedback.metadata/1,
      operational_feedback_data_keys: &OperationalFeedbackSourceMetadata.data_keys/1,
      operational_feedback_source_resolution: &OperationalFeedbackSourceMetadata.resolution/2,
      operational_feedback_override?: &OperationalFeedbackSourceMetadata.override?/1
    ]
  end
end
