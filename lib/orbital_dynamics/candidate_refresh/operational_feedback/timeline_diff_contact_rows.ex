defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffContactRows do
  @moduledoc false

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

  def timeline_diff_changed_contact_feedback_row?(%{} = row) do
    timeline_diff_status(row) == "changed" and
      timeline_diff_contact_activity?(row) and
      timeline_diff_changed_contact_station_id(row) not in [nil, ""] and
      is_number(timeline_diff_changed_contact_success_factor(row))
  end

  def merge_changed_contact_feedback(row, feedback) do
    station_id = timeline_diff_changed_contact_station_id(row)
    factor = timeline_diff_changed_contact_success_factor(row)

    update_in(feedback, ["contact_success_rate"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_id, factor, &min(&1, factor))
    end)
  end

  defp timeline_diff_status(row), do: RowValues.normalized_token(row["diff_status"])

  defp timeline_diff_contact_activity?(row) do
    timeline_diff_contact_activity?(row, "source") or
      timeline_diff_contact_activity?(row, "replacement")
  end

  defp timeline_diff_contact_activity?(row, side) do
    activity_type =
      row["#{side}_activity_type"] ||
        get_in(row, ["#{side}_activity_context", "activity_type"]) ||
        get_in(row, ["#{side}_activity_context", "type"])

    direction = row["#{side}_direction"] || get_in(row, ["#{side}_activity_context", "direction"])

    activity_type = RowValues.normalized_token(activity_type)
    direction = normalize_direction(direction)

    activity_type in ["downlink", "planned_contact", "contact", "tracking"] or
      direction in ["downlink", "uplink", "tracking"]
  end

  defp timeline_diff_changed_contact_station_id(row) do
    RowValues.stable_id_or_nil(
      row["replacement_ground_station_id"] ||
        row["source_ground_station_id"] ||
        get_in(row, ["replacement_activity_context", "ground_station_id"]) ||
        get_in(row, ["source_activity_context", "ground_station_id"]) ||
        get_in(row, ["replacement_activity_context", "station_id"]) ||
        get_in(row, ["source_activity_context", "station_id"]) ||
        get_in(row, ["replacement_activity_context", "timeline_identity", "subject_id"]) ||
        get_in(row, ["source_activity_context", "timeline_identity", "subject_id"])
    )
  end

  defp timeline_diff_changed_contact_success_factor(row) do
    case RowValues.first_number(row, [
           "contact_success_factor",
           "replacement_contact_success_factor",
           ["replacement_activity_context", "contact_success_factor"]
         ]) do
      factor when is_number(factor) ->
        RowValues.unit_interval(factor)

      _factor ->
        timeline_diff_changed_contact_result_factor(row) ||
          timeline_diff_changed_source_contact_success_factor(row)
    end
  end

  defp timeline_diff_changed_source_contact_success_factor(row) do
    case RowValues.first_number(row, [
           "source_contact_success_factor",
           ["source_activity_context", "contact_success_factor"]
         ]) do
      factor when is_number(factor) and factor < 1.0 -> RowValues.unit_interval(factor)
      _factor -> nil
    end
  end

  defp timeline_diff_changed_contact_result_factor(row) do
    cond do
      false in [
        row["contact_success"],
        row["replacement_contact_success"],
        get_in(row, ["replacement_activity_context", "contact_success"]),
        get_in(row, ["source_activity_context", "contact_success"])
      ] ->
        0.0

      RowValues.failure_token?(
        row["contact_result"] ||
          row["replacement_contact_result"] ||
          get_in(row, ["replacement_activity_context", "contact_result"]) ||
            get_in(row, ["source_activity_context", "contact_result"])
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
