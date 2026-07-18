defmodule OrbitalDynamics.Timeline.CandidateRejectionDerivedReasonPolicy do
  @moduledoc false

  def derive(activity, timeline_row) do
    []
    |> maybe_add_reason(timeline_row["invalid_activity_input"] == true, "invalid_candidate_input")
    |> maybe_add_reason(station_unavailable?(activity), "station_unavailable")
    |> maybe_add_reason(station_reserved?(activity), "station_reserved")
    |> maybe_add_reason(station_capacity_reduced?(activity), "station_capacity_reduced")
    |> maybe_add_reason(locked_overlap?(activity), "overlaps_locked_timeline_item")
    |> maybe_add_reason(
      first_boolean(activity, ["payload_available"]) == false,
      "payload_unavailable"
    )
    |> maybe_add_reason(
      first_boolean(activity, ["antenna_available"]) == false,
      "antenna_unavailable"
    )
    |> maybe_add_reason(negative_margin?(activity, ["fuel_margin"]), "fuel_margin_too_low")
    |> maybe_add_reason(negative_margin?(activity, ["storage_margin"]), "storage_full")
    |> maybe_add_reason(
      negative_margin?(activity, ["battery_margin", "power_margin", "battery_state_of_charge"]),
      "battery_margin_too_low"
    )
    |> maybe_add_reason(contact_too_short?(activity), "contact_too_short")
    |> maybe_add_reason(policy_blocked?(activity), "policy_blocked")
    |> maybe_add_reason(stale_state?(activity), "stale_state")
    |> maybe_add_reason(model_incompatible?(activity), "model_incompatible")
    |> maybe_add_reason(quality_gate_failed?(activity), "quality_gate_failed")
  end

  defp maybe_add_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_add_reason(reasons, _condition, _reason), do: reasons

  defp station_unavailable?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionStationPolicy.station_unavailable?(activity)
  end

  defp station_reserved?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionStationPolicy.station_reserved?(activity)
  end

  defp station_capacity_reduced?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionStationPolicy.station_capacity_reduced?(activity)
  end

  defp locked_overlap?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy.locked_overlap?(activity)
  end

  defp negative_margin?(activity, fields) do
    OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy.negative_margin?(activity, fields)
  end

  defp contact_too_short?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy.contact_too_short?(activity)
  end

  defp policy_blocked?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy.policy_blocked?(activity)
  end

  defp stale_state?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy.stale_state?(activity)
  end

  defp model_incompatible?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy.model_incompatible?(activity)
  end

  defp quality_gate_failed?(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy.quality_gate_failed?(activity)
  end

  defp first_boolean(activity, fields) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.first_boolean(activity, fields)
  end
end
