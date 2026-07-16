defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffManeuverRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  def timeline_diff_changed_maneuver_feedback_row?(%{} = row) do
    timeline_diff_status(row) == "changed" and
      timeline_diff_maneuver_activity?(row) and
      timeline_diff_changed_maneuver_key(row) not in [nil, ""] and
      is_number(timeline_diff_changed_maneuver_success_factor(row))
  end

  def merge_changed_maneuver_feedback(row, feedback) do
    maneuver_key = timeline_diff_changed_maneuver_key(row)
    factor = timeline_diff_changed_maneuver_success_factor(row)

    update_in(feedback, ["maneuver_success_rate"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(maneuver_key, factor, &min(&1, factor))
    end)
  end

  defp timeline_diff_status(row), do: RowValues.normalized_token(row["diff_status"])

  defp timeline_diff_maneuver_activity?(row) do
    timeline_diff_maneuver_activity?(row, "source") or
      timeline_diff_maneuver_activity?(row, "replacement")
  end

  defp timeline_diff_maneuver_activity?(row, side) do
    activity_type =
      row["#{side}_activity_type"] ||
        get_in(row, ["#{side}_activity_context", "activity_type"]) ||
        get_in(row, ["#{side}_activity_context", "type"])

    activity_type = RowValues.normalized_token(activity_type)

    activity_type in [
      "maneuver",
      "impulsive_burn",
      "burn",
      "stationkeeping_burn",
      "station_keeping_burn",
      "delta_v",
      "orbit_adjust",
      "orbit_adjustment"
    ]
  end

  defp timeline_diff_changed_maneuver_key(row) do
    RowValues.stable_id_or_nil(
      row["replacement_maneuver_id"] ||
        row["source_maneuver_id"] ||
        get_in(row, ["replacement_activity_context", "maneuver_id"]) ||
        get_in(row, ["source_activity_context", "maneuver_id"]) ||
        get_in(row, ["replacement_timeline_identity", "subject_id"]) ||
        get_in(row, ["source_timeline_identity", "subject_id"]) ||
        get_in(row, ["replacement_activity_context", "timeline_identity", "subject_id"]) ||
        get_in(row, ["source_activity_context", "timeline_identity", "subject_id"]) ||
        row["replacement_activity_id"] ||
        row["source_activity_id"] ||
        get_in(row, ["replacement_activity_context", "id"]) ||
        get_in(row, ["source_activity_context", "id"]) ||
        row["timeline_id"]
    )
  end

  defp timeline_diff_changed_maneuver_success_factor(row) do
    case RowValues.first_number(row, [
           "maneuver_success_factor",
           "replacement_maneuver_success_factor",
           ["replacement_activity_context", "maneuver_success_factor"]
         ]) do
      factor when is_number(factor) ->
        RowValues.unit_interval(factor)

      _factor ->
        timeline_diff_changed_maneuver_result_factor(row) ||
          timeline_diff_changed_source_maneuver_success_factor(row)
    end
  end

  defp timeline_diff_changed_source_maneuver_success_factor(row) do
    case RowValues.first_number(row, [
           "source_maneuver_success_factor",
           ["source_activity_context", "maneuver_success_factor"]
         ]) do
      factor when is_number(factor) and factor < 1.0 -> RowValues.unit_interval(factor)
      _factor -> nil
    end
  end

  defp timeline_diff_changed_maneuver_result_factor(row) do
    cond do
      false in [
        row["maneuver_success"],
        row["replacement_maneuver_success"],
        get_in(row, ["replacement_activity_context", "maneuver_success"]),
        get_in(row, ["source_activity_context", "maneuver_success"])
      ] ->
        0.0

      RowValues.failure_token?(
        row["maneuver_result"] ||
          row["replacement_maneuver_result"] ||
          get_in(row, ["replacement_activity_context", "maneuver_result"]) ||
            get_in(row, ["source_activity_context", "maneuver_result"])
      ) ->
        0.0

      RowValues.failure_token?(
        row["replacement_status"] ||
          get_in(row, ["replacement_activity_context", "status"]) ||
            get_in(row, ["replacement_activity_context", "realized_status"])
      ) ->
        0.0

      true ->
        nil
    end
  end
end
