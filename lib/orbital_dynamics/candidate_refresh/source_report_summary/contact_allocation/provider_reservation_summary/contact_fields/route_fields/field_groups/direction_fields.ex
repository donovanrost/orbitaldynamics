defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields.RouteFields.FieldGroups.DirectionFields do
  @moduledoc false

  alias __MODULE__.Specs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields.RouteFields.RouteMaps

  def direction_fields(reports) do
    Map.new(Specs.direction_fields(), fn {field, field_fun} ->
      {field, RouteMaps.string_list_maps(reports, field_fun)}
    end)
  end

  def nested_direction_station_fields(reports) do
    Map.new(Specs.nested_direction_station_fields(), fn {field, field_fun} ->
      {field, RouteMaps.nested_string_list_maps(reports, field_fun)}
    end)
  end
end
