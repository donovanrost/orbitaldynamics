defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceRejectionFilterReplayRisk do
  @moduledoc false

  def candidate_rejection(%{"branch_local_rejection_pressure" => true} = replay_summary) do
    if candidate_rejection_scoring_pressure?(replay_summary) do
      candidate_rejection_pressure_risk(replay_summary)
    else
      []
    end
  end

  def candidate_rejection(_replay_summary), do: []

  def contact_filter(%{"branch_local_contact_filter_pressure" => true} = replay_summary) do
    if contact_filter_scoring_pressure?(replay_summary) do
      contact_filter_pressure_risk(replay_summary)
    else
      []
    end
  end

  def contact_filter(_replay_summary), do: []

  defp candidate_rejection_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_review_pressure") == true or
      Map.get(replay_summary, "branch_local_invalid_input_pressure") == true or
      summary_positive?(replay_summary, "rejected_count")
  end

  defp candidate_rejection_pressure_risk(replay_summary) do
    candidate_ids =
      replay_summary
      |> Map.get("candidate_rejection_candidate_id_counts", %{})
      |> map_keys()

    ground_station_ids =
      replay_summary
      |> Map.get("candidate_rejection_ground_station_counts", %{})
      |> map_keys()

    [
      %{
        "type" => "candidate_rejection_pressure",
        "severity" => "high",
        "reason" =>
          "candidate source candidate-rejection replay reports rejected, reviewable, or invalid candidate pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "rejected_count" => Map.get(replay_summary, "rejected_count"),
        "reviewable_count" => Map.get(replay_summary, "reviewable_count"),
        "invalid_candidate_input_count" =>
          Map.get(replay_summary, "invalid_candidate_input_count"),
        "rejection_reason_counts" => Map.get(replay_summary, "rejection_reason_counts"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "candidate_rejection_candidate_id_counts" =>
          Map.get(replay_summary, "candidate_rejection_candidate_id_counts"),
        "candidate_rejection_ground_station_counts" =>
          Map.get(replay_summary, "candidate_rejection_ground_station_counts"),
        "candidate_ids" => candidate_ids,
        "ground_station_ids" => ground_station_ids,
        "branch_local_review_pressure" => Map.get(replay_summary, "branch_local_review_pressure"),
        "branch_local_invalid_input_pressure" =>
          Map.get(replay_summary, "branch_local_invalid_input_pressure"),
        "feedback_source" => "candidate_source.candidate_rejection_replay_summary",
        "feedback_scope" => "candidate_rejection",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp contact_filter_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_candidate_suppression_pressure") == true or
      Map.get(replay_summary, "branch_local_invalid_contact_input_pressure") == true or
      Map.get(replay_summary, "branch_local_station_suppression_pressure") == true
  end

  defp contact_filter_pressure_risk(replay_summary) do
    directions =
      replay_summary
      |> Map.get("direction_counts", %{})
      |> map_keys()
      |> Kernel.++(List.wrap(Map.get(replay_summary, "directions", [])))
      |> sorted_encoded_values()

    ground_station_ids =
      replay_summary
      |> Map.get("station_suppression_ground_station_counts", %{})
      |> map_keys()

    station_availabilities =
      replay_summary
      |> Map.get("station_suppression_availability_counts", %{})
      |> map_keys()

    [
      %{
        "type" => "downlink_completion_gap",
        "severity" => "medium",
        "reason" =>
          "candidate source contact-filter replay reports suppressed candidates, invalid contact inputs, or station suppression",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "suppressed_candidate_count" => Map.get(replay_summary, "suppressed_candidate_count"),
        "invalid_contact_input_count" => Map.get(replay_summary, "invalid_contact_input_count"),
        "invalid_contact_input_ids" => Map.get(replay_summary, "invalid_contact_input_ids"),
        "suppressed_reason_counts" => Map.get(replay_summary, "suppressed_reason_counts"),
        "contact_ids_by_suppressed_reason" =>
          Map.get(replay_summary, "contact_ids_by_suppressed_reason"),
        "directions" => directions,
        "direction_counts" => Map.get(replay_summary, "direction_counts"),
        "contact_ids_by_direction" => Map.get(replay_summary, "contact_ids_by_direction"),
        "direction_routing" => Map.get(replay_summary, "direction_routing"),
        "station_suppression_count" => Map.get(replay_summary, "station_suppression_count"),
        "station_suppression_ground_station_counts" =>
          Map.get(replay_summary, "station_suppression_ground_station_counts"),
        "station_suppression_availability_counts" =>
          Map.get(replay_summary, "station_suppression_availability_counts"),
        "station_suppression_status_counts" =>
          Map.get(replay_summary, "station_suppression_status_counts"),
        "station_suppression_contact_ids_by_ground_station" =>
          Map.get(replay_summary, "station_suppression_contact_ids_by_ground_station"),
        "station_suppression_contact_ids_by_availability" =>
          Map.get(replay_summary, "station_suppression_contact_ids_by_availability"),
        "station_suppression_contact_ids_by_status" =>
          Map.get(replay_summary, "station_suppression_contact_ids_by_status"),
        "station_suppression_station_calendar_entry_ids_by_ground_station" =>
          Map.get(
            replay_summary,
            "station_suppression_station_calendar_entry_ids_by_ground_station"
          ),
        "station_suppression_station_calendar_entry_ids_by_availability" =>
          Map.get(
            replay_summary,
            "station_suppression_station_calendar_entry_ids_by_availability"
          ),
        "station_suppression_station_calendar_entry_ids_by_status" =>
          Map.get(replay_summary, "station_suppression_station_calendar_entry_ids_by_status"),
        "station_suppression_station_calendar_provider_entry_ids_by_ground_station" =>
          Map.get(
            replay_summary,
            "station_suppression_station_calendar_provider_entry_ids_by_ground_station"
          ),
        "station_suppression_station_calendar_provider_entry_ids_by_availability" =>
          Map.get(
            replay_summary,
            "station_suppression_station_calendar_provider_entry_ids_by_availability"
          ),
        "station_suppression_station_calendar_provider_entry_ids_by_status" =>
          Map.get(
            replay_summary,
            "station_suppression_station_calendar_provider_entry_ids_by_status"
          ),
        "station_suppression_station_reservation_ids_by_ground_station" =>
          Map.get(replay_summary, "station_suppression_station_reservation_ids_by_ground_station"),
        "station_suppression_station_reservation_ids_by_availability" =>
          Map.get(replay_summary, "station_suppression_station_reservation_ids_by_availability"),
        "station_suppression_station_reservation_ids_by_status" =>
          Map.get(replay_summary, "station_suppression_station_reservation_ids_by_status"),
        "ground_station_ids" => ground_station_ids,
        "station_availabilities" => station_availabilities,
        "branch_local_candidate_suppression_pressure" =>
          Map.get(replay_summary, "branch_local_candidate_suppression_pressure"),
        "branch_local_invalid_contact_input_pressure" =>
          Map.get(replay_summary, "branch_local_invalid_contact_input_pressure"),
        "branch_local_station_suppression_pressure" =>
          Map.get(replay_summary, "branch_local_station_suppression_pressure"),
        "feedback_source" => "candidate_source.contact_filter_replay_summary",
        "feedback_scope" => "contact_filter",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp summary_positive?(summary, field) do
    case numeric_or_nil(Map.get(summary, field)) do
      value when is_number(value) -> value > 0
      _value -> false
    end
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {parsed, ""} -> parsed
      _parsed -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp map_keys(%{} = map), do: map |> Map.keys() |> sorted_encoded_values()
  defp map_keys(_map), do: []

  defp sorted_encoded_values(values) do
    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
