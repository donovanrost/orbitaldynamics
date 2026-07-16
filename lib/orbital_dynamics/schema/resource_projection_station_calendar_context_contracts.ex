defmodule OrbitalDynamics.Schema.ResourceProjectionStationCalendarContextContracts do
  @moduledoc false

  def entry_ids_by_type(flow_rows, callbacks) when is_list(callbacks) do
    values_by_type(flow_rows, callbacks, fn row -> Map.get(row, "station_calendar_entry_id") end)
  end

  def provider_ids_by_type(flow_rows, callbacks) when is_list(callbacks) do
    values_by_type(flow_rows, callbacks, fn row ->
      Map.get(row, "station_calendar_provider_id")
    end)
  end

  def provider_entry_ids_by_type(flow_rows, callbacks) when is_list(callbacks) do
    values_by_type(flow_rows, callbacks, fn row ->
      Map.get(row, "station_calendar_provider_entry_id")
    end)
  end

  def directions_by_type(flow_rows, callbacks) when is_list(callbacks) do
    flow_rows
    |> Enum.flat_map(fn
      %{} = row ->
        directions = row |> Map.get("station_calendar_directions", []) |> List.wrap()

        for pressure_type <- pressure_kinds(callbacks, row),
            direction <- directions,
            direction not in [nil, ""],
            do: {pressure_type, direction}

      _row ->
        []
    end)
    |> stable_values_by_key(callbacks)
  end

  defp values_by_type(flow_rows, callbacks, value_fun) do
    flow_rows
    |> Enum.flat_map(fn
      %{} = row ->
        Enum.map(pressure_kinds(callbacks, row), fn pressure_type ->
          {pressure_type, value_fun.(row)}
        end)

      _row ->
        []
    end)
    |> stable_values_by_key(callbacks)
  end

  defp pressure_kinds(callbacks, row),
    do: apply(require_callback(callbacks, :resource_projection_pressure_kinds), [row])

  defp stable_values_by_key(pairs, callbacks),
    do: apply(require_callback(callbacks, :stable_values_by_key), [pairs])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
