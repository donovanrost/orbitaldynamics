defmodule OrbitalDynamics.Schema.LinkCapacityCapabilityContext do
  @moduledoc false

  def link_capacity_station_unavailable_aliases do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:station_unavailable_aliases)
  end

  def link_capacity_station_availability_precedence do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:station_availability_precedence)
  end

  def link_capacity_provider_direction_aliases do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:provider_direction_aliases)
  end

  def link_capacity_station_capacity_value_paths do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:station_capacity_value_paths)
  end

  def link_capacity_source_station_capacity_value_paths do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:source_station_capacity_value_paths)
  end

  def link_capacity_assumptions_json_schema(required_properties) do
    OrbitalDynamics.Schema.LinkCapacityReportJsonSchema.assumptions_from_deps(
      [
        station_unavailable_aliases: &link_capacity_station_unavailable_aliases/0,
        station_availability_precedence: &link_capacity_station_availability_precedence/0,
        station_capacity_value_paths: &link_capacity_station_capacity_value_paths/0,
        source_station_capacity_value_paths: &link_capacity_source_station_capacity_value_paths/0,
        provider_direction_aliases: &link_capacity_provider_direction_aliases/0
      ],
      required_properties
    )
  end
end
