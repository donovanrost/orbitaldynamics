defmodule OrbitalDynamics.Timeline.CandidateRejectionReasonPolicy do
  @moduledoc false

  def declared(activity, candidate_rejection_reasons) do
    values =
      activity
      |> declared_values()
      |> Enum.map(&candidate_rejection_reason(&1, candidate_rejection_reasons))

    if Enum.any?(values, &(&1 == "declared_rejection")) do
      values
    else
      values
    end
  end

  def declared_values(activity) do
    activity
    |> rejection_reason_values([
      "rejection_reason",
      "rejection_reasons",
      "candidate_rejection_reason",
      "candidate_rejection_reasons",
      "why_rejected"
    ])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp rejection_reason_values(activity, keys) do
    keys
    |> Enum.flat_map(fn key ->
      [Map.get(activity, key), get_in(activity, ["metadata", key])]
    end)
    |> Enum.flat_map(&split_rejection_reason_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp split_rejection_reason_value(values) when is_list(values),
    do: Enum.flat_map(values, &split_rejection_reason_value/1)

  defp split_rejection_reason_value(value) when value in [nil, ""], do: []

  defp split_rejection_reason_value(value) when is_atom(value),
    do: split_rejection_reason_value(Atom.to_string(value))

  defp split_rejection_reason_value(value) when is_binary(value) do
    value
    |> String.split([",", ";", "|"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp split_rejection_reason_value(_value), do: []

  defp candidate_rejection_reason(value, candidate_rejection_reasons) do
    normalized =
      value
      |> to_string()
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "_")
      |> String.trim("_")

    aliases = %{
      "access_window_missing" => "no_access_window",
      "no_access" => "no_access_window",
      "target_visibility_missing" => "no_target_visibility_window",
      "no_target_visibility" => "no_target_visibility_window",
      "eclipse" => "eclipse_conflict",
      "low_battery" => "battery_margin_too_low",
      "battery_low" => "battery_margin_too_low",
      "storage_margin_too_low" => "storage_full",
      "fuel_low" => "fuel_margin_too_low",
      "payload_not_available" => "payload_unavailable",
      "antenna_not_available" => "antenna_unavailable",
      "station_not_available" => "station_unavailable",
      "reserved_station" => "station_reserved",
      "reduced_station_capacity" => "station_capacity_reduced",
      "short_contact" => "contact_too_short",
      "locked_overlap" => "overlaps_locked_timeline_item",
      "activity_overlap_locked" => "overlaps_locked_timeline_item",
      "authority_missing" => "command_authority_missing",
      "blocked_by_policy" => "policy_blocked",
      "policy" => "policy_blocked",
      "state_stale" => "stale_state",
      "incompatible_model" => "model_incompatible",
      "schema_validation_failed" => "quality_gate_failed"
    }

    canonical = Map.get(aliases, normalized, normalized)

    if canonical in candidate_rejection_reasons do
      canonical
    else
      "declared_rejection"
    end
  end
end
