defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffCommandRows
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffContactRows
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffDownlinkRows
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffManeuverRows
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffObservationRows

  def report_feedback(%{} = report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&RowValues.stringify_keys/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      cond do
        removed_downlink_feedback_row?(row) ->
          TimelineDiffDownlinkRows.merge_removed_downlink_feedback(row, feedback)

        changed_downlink_shortfall_feedback_row?(row) ->
          TimelineDiffDownlinkRows.merge_changed_downlink_shortfall_feedback(row, feedback)

        changed_contact_feedback_row?(row) ->
          TimelineDiffContactRows.merge_changed_contact_feedback(row, feedback)

        changed_observation_quality_feedback_row?(row) ->
          TimelineDiffObservationRows.merge_changed_observation_quality_feedback(row, feedback)

        changed_command_feedback_row?(row) ->
          TimelineDiffCommandRows.merge_changed_command_feedback(row, feedback)

        changed_maneuver_feedback_row?(row) ->
          TimelineDiffManeuverRows.merge_changed_maneuver_feedback(row, feedback)

        true ->
          feedback
      end
    end)
    |> RowValues.compact_nonempty()
  end

  def report_feedback(_report), do: %{}

  def removed_downlink_feedback_row?(%{} = row),
    do: TimelineDiffDownlinkRows.timeline_diff_removed_downlink_feedback_row?(row)

  def changed_downlink_shortfall_feedback_row?(%{} = row),
    do: TimelineDiffDownlinkRows.timeline_diff_changed_downlink_shortfall_feedback_row?(row)

  def changed_contact_feedback_row?(%{} = row),
    do: TimelineDiffContactRows.timeline_diff_changed_contact_feedback_row?(row)

  def changed_observation_quality_feedback_row?(%{} = row),
    do: TimelineDiffObservationRows.timeline_diff_changed_observation_quality_feedback_row?(row)

  def changed_command_feedback_row?(%{} = row),
    do: TimelineDiffCommandRows.timeline_diff_changed_command_feedback_row?(row)

  def changed_maneuver_feedback_row?(%{} = row),
    do: TimelineDiffManeuverRows.timeline_diff_changed_maneuver_feedback_row?(row)

  def status(row), do: RowValues.normalized_token(row["diff_status"])

  def changed_fields(row) do
    row
    |> Map.get("changed_fields", [])
    |> List.wrap()
    |> Enum.map(&RowValues.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def observation_activity?(row),
    do: TimelineDiffObservationRows.timeline_diff_observation_activity?(row)

  def observation_activity?(row, side),
    do: TimelineDiffObservationRows.timeline_diff_observation_activity?(row, side)

  def changed_observation_target_id(row),
    do: TimelineDiffObservationRows.timeline_diff_changed_observation_target_id(row)

  def changed_observation_success_factor(row),
    do: TimelineDiffObservationRows.timeline_diff_changed_observation_success_factor(row)
end
