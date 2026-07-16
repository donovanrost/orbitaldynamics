defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.OperationalTimelineRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "uplink",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "downlink" => "downlink",
    "down_link" => "downlink",
    "tracking" => "tracking",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "health_check" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check",
    "contact" => "contact"
  }

  def operational_timeline_report_feedback(%{} = report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&RowValues.stringify_keys/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      feedback =
        if operational_timeline_contact_feedback_row?(row) do
          merge_operational_timeline_contact_feedback(row, feedback)
        else
          feedback
        end

      feedback =
        if operational_timeline_command_feedback_row?(row) do
          OperationalFeedback.merge_command_window_feedback(row, feedback)
        else
          feedback
        end

      feedback =
        if operational_timeline_maneuver_feedback_row?(row) do
          merge_operational_timeline_maneuver_feedback(row, feedback)
        else
          feedback
        end

      feedback =
        if operational_timeline_observation_feedback_row?(row) do
          merge_operational_timeline_observation_feedback(row, feedback)
        else
          feedback
        end

      if operational_timeline_station_throughput_feedback_row?(row) do
        merge_operational_timeline_station_throughput_feedback(row, feedback)
      else
        feedback
      end
    end)
    |> RowValues.compact_nonempty()
  end

  def operational_timeline_report_feedback(_report), do: %{}

  def operational_timeline_contact_feedback_row?(%{} = row) do
    operational_timeline_contact_key(row) not in [nil, ""] and
      is_number(operational_timeline_contact_success_factor(row))
  end

  def operational_timeline_command_feedback_row?(%{} = row) do
    OperationalFeedback.command_window_feedback_row?(row) and
      operational_timeline_command_activity?(row)
  end

  def operational_timeline_maneuver_feedback_row?(%{} = row) do
    OperationalFeedback.maneuver_review_success_feedback_row?(row) and
      operational_timeline_maneuver_activity?(row)
  end

  def operational_timeline_observation_feedback_row?(%{} = row) do
    operational_timeline_observation_key(row) not in [nil, ""] and
      is_number(operational_timeline_observation_success_factor(row))
  end

  def operational_timeline_station_throughput_feedback_row?(%{} = row) do
    operational_timeline_station_key(row) not in [nil, ""] and
      is_number(operational_timeline_station_throughput_factor(row))
  end

  def operational_timeline_feedback_key(row) do
    operational_timeline_contact_key(row) ||
      OperationalFeedback.command_window_feedback_key(row) ||
      OperationalFeedback.maneuver_review_feedback_key(row) ||
      operational_timeline_observation_key(row)
  end

  defp operational_timeline_contact_key(row) do
    if operational_timeline_contact_activity?(row) do
      RowValues.stable_id_or_nil(
        row["ground_station_id"] ||
          get_in(row, ["activity_context", "ground_station_id"]) ||
          get_in(row, ["source_activity_context", "ground_station_id"]) ||
          get_in(row, ["import_activity_context", "ground_station_id"])
      )
    end
  end

  defp operational_timeline_station_key(row) do
    RowValues.stable_id_or_nil(
      row["ground_station_id"] ||
        get_in(row, ["activity_context", "ground_station_id"]) ||
        get_in(row, ["source_activity_context", "ground_station_id"]) ||
        get_in(row, ["import_activity_context", "ground_station_id"])
    )
  end

  defp operational_timeline_observation_key(row) do
    if operational_timeline_observation_activity?(row) do
      RowValues.stable_id_or_nil(
        row["target_id"] ||
          get_in(row, ["activity_context", "target_id"]) ||
          get_in(row, ["source_activity_context", "target_id"]) ||
          get_in(row, ["import_activity_context", "target_id"]) ||
          row["activity_id"] ||
          row["id"] ||
          row["source_window_id"] ||
          row["timeline_id"]
      )
    end
  end

  defp operational_timeline_contact_success_factor(row) do
    case RowValues.first_number(row, [
           "contact_success_factor",
           ["activity_context", "contact_success_factor"],
           ["source_activity_context", "contact_success_factor"],
           ["import_activity_context", "contact_success_factor"]
         ]) do
      factor when is_number(factor) -> RowValues.unit_interval(factor)
      _factor -> operational_timeline_result_factor(row, "contact")
    end
  end

  defp operational_timeline_observation_success_factor(row) do
    case RowValues.first_number(row, [
           "observation_success_factor",
           ["activity_context", "observation_success_factor"],
           ["source_activity_context", "observation_success_factor"],
           ["import_activity_context", "observation_success_factor"]
         ]) do
      factor when is_number(factor) -> RowValues.unit_interval(factor)
      _factor -> operational_timeline_result_factor(row, "observation")
    end
  end

  defp operational_timeline_result_factor(row, prefix) do
    success_key = "#{prefix}_success"
    result_key = "#{prefix}_result"

    cond do
      false in [
        row[success_key],
        get_in(row, ["activity_context", success_key]),
        get_in(row, ["source_activity_context", success_key]),
        get_in(row, ["import_activity_context", success_key])
      ] ->
        0.0

      RowValues.failure_token?(
        row[result_key] ||
          get_in(row, ["activity_context", result_key]) ||
          get_in(row, ["source_activity_context", result_key]) ||
            get_in(row, ["import_activity_context", result_key])
      ) ->
        0.0

      true ->
        nil
    end
  end

  defp operational_timeline_station_throughput_factor(row) do
    case RowValues.first_number(row, [
           "station_throughput_factor",
           ["activity_context", "station_throughput_factor"],
           ["source_activity_context", "station_throughput_factor"],
           ["import_activity_context", "station_throughput_factor"],
           "throughput_completion_fraction",
           ["activity_context", "throughput_completion_fraction"],
           ["source_activity_context", "throughput_completion_fraction"],
           ["import_activity_context", "throughput_completion_fraction"]
         ]) do
      factor when is_number(factor) ->
        RowValues.unit_interval(factor)

      _factor ->
        actual =
          RowValues.first_number(row, [
            "actual_throughput_mb",
            ["activity_context", "actual_throughput_mb"],
            ["source_activity_context", "actual_throughput_mb"],
            ["import_activity_context", "actual_throughput_mb"]
          ])

        planned =
          RowValues.first_number(row, [
            "planned_estimated_throughput_mb",
            ["activity_context", "planned_estimated_throughput_mb"],
            ["source_activity_context", "planned_estimated_throughput_mb"],
            ["import_activity_context", "planned_estimated_throughput_mb"],
            "estimated_throughput_mb",
            ["activity_context", "estimated_throughput_mb"],
            ["source_activity_context", "estimated_throughput_mb"],
            ["import_activity_context", "estimated_throughput_mb"],
            "planned_throughput_mb",
            ["activity_context", "planned_throughput_mb"],
            ["source_activity_context", "planned_throughput_mb"],
            ["import_activity_context", "planned_throughput_mb"],
            "estimated_downlink_mb",
            ["activity_context", "estimated_downlink_mb"],
            ["source_activity_context", "estimated_downlink_mb"],
            ["import_activity_context", "estimated_downlink_mb"],
            "required_downlink_mb",
            ["activity_context", "required_downlink_mb"],
            ["source_activity_context", "required_downlink_mb"],
            ["import_activity_context", "required_downlink_mb"]
          ])

        if is_number(actual) and is_number(planned) and planned > 0.0 do
          RowValues.unit_interval(actual / planned)
        end
    end
  end

  defp merge_operational_timeline_contact_feedback(row, feedback) do
    station_key = operational_timeline_contact_key(row)
    factor = operational_timeline_contact_success_factor(row)

    update_in(feedback, ["contact_success_rate"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_key, factor, &min(&1, factor))
    end)
  end

  defp merge_operational_timeline_maneuver_feedback(row, feedback) do
    maneuver_key = OperationalFeedback.maneuver_review_feedback_key(row)
    factor = OperationalFeedback.maneuver_review_success_factor(row)

    update_in(feedback, ["maneuver_success_rate"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(maneuver_key, factor, &min(&1, factor))
    end)
  end

  defp merge_operational_timeline_observation_feedback(row, feedback) do
    observation_key = operational_timeline_observation_key(row)
    factor = operational_timeline_observation_success_factor(row)

    update_in(feedback, ["observation_success_rate"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(observation_key, factor, &min(&1, factor))
    end)
  end

  defp merge_operational_timeline_station_throughput_feedback(row, feedback) do
    station_key = operational_timeline_station_key(row)
    factor = operational_timeline_station_throughput_factor(row)

    update_in(feedback, ["station_throughput_factor"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_key, factor, &min(&1, factor))
    end)
  end

  defp operational_timeline_contact_activity?(row) do
    type = operational_timeline_activity_token(row)
    direction = operational_timeline_direction_token(row)
    kind = operational_timeline_kind_token(row)

    type in ["downlink", "planned_contact", "contact", "tracking"] or
      direction in ["downlink", "uplink", "tracking"] or
      kind in ["downlink", "contact", "tracking"]
  end

  defp operational_timeline_command_activity?(row) do
    type = operational_timeline_activity_token(row)
    direction = operational_timeline_direction_token(row)
    kind = operational_timeline_kind_token(row)

    type in ["command", "health_check"] or
      direction in ["command", "uplink", "health_check"] or
      kind in ["command", "health_check"]
  end

  defp operational_timeline_maneuver_activity?(row) do
    type = operational_timeline_activity_token(row)
    kind = operational_timeline_kind_token(row)

    type in [
      "maneuver",
      "impulsive_burn",
      "burn",
      "stationkeeping_burn",
      "station_keeping_burn",
      "delta_v"
    ] or kind in ["maneuver", "burn", "delta_v"]
  end

  defp operational_timeline_observation_activity?(row) do
    type = operational_timeline_activity_token(row)
    direction = operational_timeline_direction_token(row)
    kind = operational_timeline_kind_token(row)

    type in ["observation", "observe", "imaging", "payload_collection"] or
      direction in ["observation", "observe"] or
      kind in ["observation", "observe", "collection"]
  end

  defp operational_timeline_activity_token(row) do
    (row["activity_type"] ||
       row["type"] ||
       get_in(row, ["activity_context", "activity_type"]) ||
       get_in(row, ["activity_context", "type"]) ||
       get_in(row, ["source_activity_context", "activity_type"]) ||
       get_in(row, ["source_activity_context", "type"]) ||
       get_in(row, ["import_activity_context", "activity_type"]) ||
       get_in(row, ["import_activity_context", "type"]))
    |> RowValues.normalized_token()
  end

  defp operational_timeline_direction_token(row) do
    (row["direction"] ||
       get_in(row, ["activity_context", "direction"]) ||
       get_in(row, ["source_activity_context", "direction"]) ||
       get_in(row, ["import_activity_context", "direction"]))
    |> normalize_direction()
  end

  defp operational_timeline_kind_token(row) do
    (row["operational_kind"] ||
       get_in(row, ["activity_context", "operational_kind"]) ||
       get_in(row, ["source_activity_context", "operational_kind"]) ||
       get_in(row, ["import_activity_context", "operational_kind"]))
    |> RowValues.normalized_token()
  end

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> RowValues.encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      token when is_map_key(@provider_direction_aliases, token) ->
        Map.fetch!(@provider_direction_aliases, token)

      "nil" ->
        nil

      "" ->
        nil

      value ->
        value
    end
  end
end
