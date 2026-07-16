defmodule OrbitalDynamics.Schema.ResourceProjectionStationCalendarContextContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.ResourceProjectionPressureContracts

  import OrbitalDynamics.Schema.CollectionAggregation, only: [stable_values_by_key: 1]

  def entry_ids_by_type(flow_rows) do
    values_by_type(flow_rows, fn row -> Map.get(row, "station_calendar_entry_id") end)
  end

  def provider_ids_by_type(flow_rows) do
    values_by_type(flow_rows, fn row ->
      Map.get(row, "station_calendar_provider_id")
    end)
  end

  def provider_entry_ids_by_type(flow_rows) do
    values_by_type(flow_rows, fn row ->
      Map.get(row, "station_calendar_provider_entry_id")
    end)
  end

  def directions_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn
      %{} = row ->
        directions = row |> Map.get("station_calendar_directions", []) |> List.wrap()

        for pressure_type <- ResourceProjectionPressureContracts.kinds(row),
            direction <- directions,
            direction not in [nil, ""],
            do: {pressure_type, direction}

      _row ->
        []
    end)
    |> stable_values_by_key()
  end

  defp values_by_type(flow_rows, value_fun) do
    flow_rows
    |> Enum.flat_map(fn
      %{} = row ->
        Enum.map(ResourceProjectionPressureContracts.kinds(row), fn pressure_type ->
          {pressure_type, value_fun.(row)}
        end)

      _row ->
        []
    end)
    |> stable_values_by_key()
  end
end
