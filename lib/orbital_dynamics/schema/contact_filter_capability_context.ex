defmodule OrbitalDynamics.Schema.ContactFilterCapabilityContext do
  @moduledoc false

  def contact_filter_report_model_limits do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def contact_filter_suppressed_directions do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:suppressed_directions)
  end

  def contact_filter_suppression_reasons do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:suppression_reasons)
  end

  def contact_filter_station_unavailable_aliases do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:station_unavailable_aliases)
  end

  def contact_filter_station_availability_precedence do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:station_availability_precedence)
  end

  def contact_filter_station_capacity_value_paths do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:station_capacity_value_paths)
  end

  def contact_filter_contact_capacity_value_paths do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:contact_capacity_value_paths)
  end

  def contact_filter_provider_direction_aliases do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:provider_direction_aliases)
  end

  def contact_filter_report_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactFilterReportJsonSchema.assumptions_from_context(
      &contact_filter_suppressed_directions/0,
      &contact_filter_suppression_reasons/0,
      &contact_filter_station_unavailable_aliases/0,
      &contact_filter_station_availability_precedence/0,
      &contact_filter_station_capacity_value_paths/0,
      &contact_filter_contact_capacity_value_paths/0,
      &contact_filter_provider_direction_aliases/0
    )
  end
end
