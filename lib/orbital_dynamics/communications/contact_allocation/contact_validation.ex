defmodule OrbitalDynamics.Communications.ContactAllocation.ContactValidation do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactAllocation.{
    ContactIdentity,
    StationCapacityEvidence,
    ThroughputEvidence
  }

  @terminal_contact_statuses ~w(canceled cancelled completed executed failed missed partial rejected)

  def candidate?(contact, policy) do
    contact_like_input?(contact, policy) and
      is_nil(ContactIdentity.contact_id_issue(contact)) and
      is_nil(contact_identity_issue(contact, policy)) and
      is_number(Map.get(contact, "starts_at_s")) and
      is_number(Map.get(contact, "ends_at_s")) and
      not is_nil(Map.get(contact, "ground_station_id")) and
      not invalid_station_capacity_declared?(contact, policy) and
      not invalid_required_capacity_declared?(contact, policy) and
      not invalid_unit_interval_declared?(completed_fraction_candidates(contact)) and
      not invalid_unit_interval_declared?(
        contact_feedback_factor_candidates(contact, "contact_success_factor")
      ) and
      not invalid_unit_interval_declared?(
        contact_feedback_factor_candidates(contact, "command_success_factor")
      )
  end

  def contact_like_input?(contact, policy) do
    Map.get(contact, "invalid_contact_shape") == true or
      Map.get(contact, "type") in policy.contact_types or
      Map.get(contact, "direction") in policy.contact_directions or
      provider_downlink_contact_input?(contact)
  end

  def provider_downlink_contact_input?(contact) do
    Map.get(contact, "type") in [nil, "contact", "planned_contact"] and
      Map.get(contact, "direction") in [nil, "downlink"] and
      provider_contact_evidence?(contact)
  end

  def status_allocation_blocked?(contact) do
    contact_status(contact) in @terminal_contact_statuses or
      contact_status(contact) == "blocked_by_policy" or
      contact_approval_status(contact) in ["blocked_by_policy", "rejected"]
  end

  def status_allocation_blocked_reason(contact, station_capacity_policy) do
    status = contact_status(contact)
    approval_status = contact_approval_status(contact)

    cond do
      approval_status == "rejected" ->
        "approval_status_rejected"

      status == "blocked_by_policy" ->
        "activity_status_blocked_by_policy"

      status in @terminal_contact_statuses ->
        "activity_status_#{status}"

      StationCapacityEvidence.station_allocation_blocked?(contact, station_capacity_policy) ->
        StationCapacityEvidence.station_allocation_blocked_reason(
          contact,
          station_capacity_policy
        )

      approval_status == "blocked_by_policy" ->
        "approval_status_blocked_by_policy"
    end
  end

  def contact_status(contact) do
    Map.get(contact, "status") || get_in(contact, ["metadata", "status"]) || "planned"
  end

  def contact_approval_status(contact) do
    Map.get(contact, "approval_status") || get_in(contact, ["metadata", "approval_status"])
  end

  def invalid_reason(contact, policy) do
    cond do
      Map.get(contact, "invalid_contact_shape") == true ->
        "invalid_contact_shape"

      reason = ContactIdentity.contact_id_issue(contact) ->
        reason

      reason = contact_identity_issue(contact, policy) ->
        reason

      is_nil(Map.get(contact, "ground_station_id")) ->
        "missing_ground_station_id"

      not is_number(Map.get(contact, "starts_at_s")) ->
        "missing_contact_starts_at_s"

      not is_number(Map.get(contact, "ends_at_s")) ->
        "missing_contact_ends_at_s"

      invalid_station_capacity_declared?(contact, policy) ->
        "invalid_capacity_fraction"

      invalid_required_capacity_declared?(contact, policy) ->
        "invalid_required_capacity_fraction"

      invalid_unit_interval_declared?(completed_fraction_candidates(contact)) ->
        "invalid_completed_fraction"

      invalid_unit_interval_declared?(
        contact_feedback_factor_candidates(contact, "contact_success_factor")
      ) ->
        "invalid_contact_success_factor"

      invalid_unit_interval_declared?(
        contact_feedback_factor_candidates(contact, "command_success_factor")
      ) ->
        "invalid_command_success_factor"

      true ->
        "invalid_contact_input"
    end
  end

  def completed_fraction_value(contact) do
    contact
    |> completed_fraction_candidates()
    |> StationCapacityEvidence.first_unit_interval()
  end

  def feedback_factor(contact, key) do
    contact
    |> contact_feedback_factor_candidates(key)
    |> StationCapacityEvidence.first_unit_interval()
  end

  defp provider_contact_evidence?(contact) do
    Enum.any?(
      [
        Map.get(contact, "id"),
        Map.get(contact, "contact_id"),
        Map.get(contact, "activity_id"),
        Map.get(contact, "ground_station_id"),
        Map.get(contact, "station"),
        Map.get(contact, "ground_station"),
        Map.get(contact, "starts_at_s"),
        Map.get(contact, "ends_at_s"),
        Map.get(contact, "source_window_id"),
        Map.get(contact, "source_window"),
        get_in(contact, ["metadata", "source_window"]),
        get_in(contact, ["activity_context", "source_window"]),
        ThroughputEvidence.estimated_throughput(contact),
        ThroughputEvidence.actual_throughput(contact),
        completed_fraction_value(contact)
      ],
      fn value -> not is_nil(value) end
    )
  end

  defp contact_identity_issue(contact, policy) do
    ContactIdentity.contact_identity_issue(contact, policy.contact_stable_identity_fields)
  end

  defp completed_fraction_candidates(contact) do
    [
      contact["completed_fraction"],
      contact["completion_fraction"],
      contact["contact_completion_fraction"],
      get_in(contact, ["throughput_model", "completed_fraction"]),
      get_in(contact, ["throughput_model", "completion_fraction"]),
      get_in(contact, ["throughput_model", "contact_completion_fraction"])
    ]
  end

  defp contact_feedback_factor_candidates(contact, key) do
    [contact_value(contact, key)]
  end

  defp contact_value(contact, key) do
    case Map.fetch(contact, key) do
      {:ok, nil} -> get_in(contact, ["metadata", key])
      {:ok, value} -> value
      :error -> get_in(contact, ["metadata", key])
    end
  end

  defp invalid_station_capacity_declared?(contact, policy) do
    StationCapacityEvidence.invalid_station_capacity_declared?(
      contact,
      policy.station_capacity_policy
    )
  end

  defp invalid_required_capacity_declared?(contact, policy) do
    StationCapacityEvidence.invalid_required_capacity_declared?(
      contact,
      policy.station_capacity_policy
    )
  end

  defp invalid_unit_interval_declared?(values) do
    StationCapacityEvidence.invalid_unit_interval_declared?(values)
  end
end
