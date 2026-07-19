defmodule OrbitalDynamics.Study.Manifest.GroundStationCatalogInput do
  @moduledoc false

  alias OrbitalDynamics.GroundStation
  alias OrbitalDynamics.Study.Manifest.InputField

  def parse(%{"ground_stations" => [], "candidate_refresh" => %{} = refresh}) do
    case candidate_refresh_mission_state(refresh) do
      {:ok, mission_state} when map_size(mission_state) > 0 ->
        mission_state
        |> mission_state_ground_station_specs()
        |> parse_ground_stations("candidate_refresh.mission_state.ground_stations")

      _mission_state ->
        {:ok, []}
    end
  end

  def parse(%{"ground_stations" => station_specs}) when is_list(station_specs) do
    parse_ground_stations(station_specs, "ground_stations")
  end

  def parse(%{"ground_stations" => _stations}),
    do: {:error, {:invalid_field, "ground_stations"}}

  def parse(%{"candidate_refresh" => %{"mission_state" => %{} = mission_state}}) do
    mission_state
    |> mission_state_ground_station_specs()
    |> parse_ground_stations("candidate_refresh.mission_state.ground_stations")
  end

  def parse(_source), do: {:ok, []}

  defp parse_ground_stations(station_specs, field) when is_list(station_specs) do
    station_specs
    |> Enum.reduce_while({:ok, []}, fn station_spec, {:ok, stations} ->
      case ground_station(station_spec, field) do
        {:ok, station} -> {:cont, {:ok, stations ++ [station]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp parse_ground_stations(:invalid, field), do: {:error, {:invalid_field, field}}

  defp ground_station(%{} = spec, _field) do
    with {:ok, id} <- InputField.required(spec, "id"),
         {:ok, latitude_deg} <- InputField.required_number(spec, "latitude_deg"),
         {:ok, longitude_deg} <- InputField.required_number(spec, "longitude_deg"),
         {:ok, altitude_km} <- InputField.optional_number(spec, "altitude_km"),
         {:ok, minimum_elevation_deg} <-
           InputField.optional_number(spec, "minimum_elevation_deg") do
      {:ok,
       GroundStation.new!(
         id,
         latitude_deg,
         longitude_deg,
         compact_keyword(
           altitude_km: altitude_km,
           minimum_elevation_deg: minimum_elevation_deg
         )
       )}
    end
  end

  defp ground_station(_spec, field), do: {:error, {:invalid_field, field}}

  defp mission_state_ground_station_specs(%{} = mission_state) do
    case mission_state_ground_station_catalog_specs(mission_state) do
      :invalid ->
        :invalid

      catalog_specs ->
        case mission_state_ground_network_station_specs(mission_state) do
          :invalid when catalog_specs == [] -> :invalid
          :invalid -> catalog_specs
          network_specs -> unique_specs_by_id(catalog_specs ++ network_specs)
        end
    end
  end

  defp mission_state_ground_station_catalog_specs(%{"ground_stations" => station_specs})
       when is_list(station_specs),
       do: Enum.map(station_specs, &normalize_ground_station_spec/1)

  defp mission_state_ground_station_catalog_specs(%{"ground_stations" => _station_specs}),
    do: :invalid

  defp mission_state_ground_station_catalog_specs(_mission_state), do: []

  defp mission_state_ground_network_station_specs(%{"ground_network" => ground_network})
       when is_list(ground_network) do
    ground_network
    |> Enum.map(&normalize_ground_station_spec/1)
    |> Enum.filter(fn
      %{"latitude_deg" => latitude_deg, "longitude_deg" => longitude_deg}
      when is_number(latitude_deg) and is_number(longitude_deg) ->
        true

      _station ->
        false
    end)
    |> unique_specs_by_id()
  end

  defp mission_state_ground_network_station_specs(%{"ground_network" => _ground_network}),
    do: :invalid

  defp mission_state_ground_network_station_specs(_mission_state), do: []

  defp normalize_ground_station_spec(%{} = station) do
    station
    |> Map.put_new("id", Map.get(station, "ground_station_id") || Map.get(station, "station_id"))
    |> Map.put_new("minimum_elevation_deg", 5.0)
  end

  defp normalize_ground_station_spec(station), do: station

  defp unique_specs_by_id(specs) do
    specs
    |> Enum.reduce({[], MapSet.new()}, fn
      %{"id" => id} = spec, {acc, ids} when id not in [nil, ""] ->
        if MapSet.member?(ids, id) do
          {acc, ids}
        else
          {acc ++ [spec], MapSet.put(ids, id)}
        end

      spec, {acc, ids} ->
        {acc ++ [spec], ids}
    end)
    |> elem(0)
  end

  defp candidate_refresh_mission_state(%{"mission_state" => %{} = mission_state}),
    do: {:ok, mission_state}

  defp candidate_refresh_mission_state(%{"mission_state" => _mission_state}),
    do: {:error, {:invalid_field, "candidate_refresh.mission_state"}}

  defp candidate_refresh_mission_state(_refresh), do: {:ok, %{}}

  defp compact_keyword(keyword) do
    Enum.reject(keyword, fn {_key, value} -> is_nil(value) end)
  end
end
