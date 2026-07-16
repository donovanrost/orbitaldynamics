defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.RouteMap.FieldMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  def from_fields(fields) do
    Map.new(FieldSpecs.route_field_names(), fn field_name ->
      {field_name, fields |> Keyword.get(field_name) |> empty_map_if_nil()}
    end)
  end

  def route_keys(field_maps) do
    FieldSpecs.route_field_names()
    |> Enum.flat_map(fn field_name ->
      field_maps
      |> Map.fetch!(field_name)
      |> Map.keys()
    end)
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
