defmodule OrbitalDynamics.Schema.ContactAllocationCapabilityContext do
  @moduledoc false

  def contact_allocation_capabilities do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
  end

  def contact_allocation_model_limits do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def contact_allocation_capacity_pack_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryJsonSchema.assumptions_from_context(
      &contact_allocation_capacity_pack_statuses/0,
      &contact_allocation_reduced_capacity_pack_statuses/0,
      &contact_allocation_required_capacity_fraction_source_values/0,
      &contact_allocation_required_capacity_value_paths/0,
      &contact_allocation_default_required_capacity_value_paths/0
    )
  end

  def contact_allocation_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.summary_assumptions_from_context(
      &contact_allocation_row_statuses/0,
      &contact_allocation_effective_row_statuses/0,
      &contact_allocation_station_unavailable_aliases/0,
      &contact_allocation_station_blocking_availability/0,
      &contact_allocation_station_availability_precedence/0,
      &contact_allocation_capacity_pack_statuses/0,
      &contact_allocation_reduced_capacity_pack_statuses/0,
      &contact_allocation_station_reservation_match_statuses/0,
      &contact_allocation_station_reservation_expiration_statuses/0,
      &contact_allocation_required_capacity_fraction_source_values/0,
      &contact_allocation_required_capacity_value_paths/0,
      &contact_allocation_default_required_capacity_value_paths/0,
      &contact_allocation_provider_direction_aliases/0
    )
  end

  def contact_allocation_station_pressure_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryJsonSchema.assumptions_from_context(
      &contact_allocation_station_unavailable_aliases/0,
      &contact_allocation_station_blocking_availability/0,
      &contact_allocation_station_availability_precedence/0,
      &contact_allocation_provider_direction_aliases/0
    )
  end

  def contact_allocation_reservation_conflict_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryJsonSchema.assumptions_from_context(
      &contact_allocation_station_reservation_match_statuses/0,
      &contact_allocation_reservation_conflict_match_statuses/0,
      &contact_allocation_station_reservation_expiration_statuses/0,
      &contact_allocation_provider_direction_aliases/0
    )
  end

  def contact_allocation_provider_reservation_request_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryJsonSchema.assumptions_from_context(
      &contact_allocation_provider_reservation_request_statuses/0,
      &contact_allocation_station_reservation_match_statuses/0,
      &contact_allocation_provider_direction_aliases/0
    )
  end

  defp contact_allocation_capacity_pack_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:capacity_pack_statuses)
  end

  defp contact_allocation_reduced_capacity_pack_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:reduced_capacity_pack_statuses)
  end

  defp contact_allocation_station_reservation_match_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_reservation_match_statuses)
  end

  defp contact_allocation_reservation_conflict_match_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:reservation_conflict_match_statuses)
  end

  defp contact_allocation_station_reservation_expiration_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_reservation_expiration_statuses)
  end

  def contact_allocation_provider_reservation_request_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:provider_reservation_request_statuses)
  end

  defp contact_allocation_row_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:row_statuses)
  end

  defp contact_allocation_effective_row_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:effective_row_statuses)
  end

  defp contact_allocation_station_unavailable_aliases do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_unavailable_aliases)
  end

  defp contact_allocation_station_blocking_availability do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_blocking_availability)
  end

  defp contact_allocation_station_availability_precedence do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_availability_precedence)
  end

  defp contact_allocation_provider_direction_aliases do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:provider_direction_aliases)
  end

  defp contact_allocation_required_capacity_fraction_source_values do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:required_capacity_fraction_source_values)
  end

  defp contact_allocation_required_capacity_value_paths do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:required_capacity_value_paths)
  end

  defp contact_allocation_default_required_capacity_value_paths do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:default_required_capacity_value_paths)
  end
end
