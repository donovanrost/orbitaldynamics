defmodule OrbitalDynamics.Study.Manifest.CandidateRefreshRunInputSources do
  @moduledoc false

  def build(%{"candidate_refresh" => %{} = refresh} = source) do
    %{
      "accepted_planning_state" => candidate_refresh_accepted_planning_state_sources(refresh),
      "targets" => candidate_refresh_target_sources(refresh),
      "ground_stations" => candidate_refresh_ground_station_sources(source)
    }
  end

  def objective_target_specs(%{} = objective) do
    objective_specs =
      objective
      |> normalize_target_spec()
      |> List.wrap()

    nested_specs =
      objective_target_selector_aliases()
      |> Enum.flat_map(&target_spec_values(Map.get(objective, &1)))
      |> Enum.map(&normalize_target_spec/1)

    objective_specs ++ nested_specs
  end

  def objective_target_specs(_objective), do: [:invalid]

  defp candidate_refresh_accepted_planning_state_sources(refresh) do
    cond do
      Map.has_key?(refresh, "accepted_planning_state") ->
        ["candidate_refresh.accepted_planning_state"]

      Map.has_key?(refresh, "orbit_data") ->
        ["candidate_refresh.orbit_data"]

      is_map(get_in(refresh, ["mission_state", "accepted_planning_state"])) ->
        ["candidate_refresh.mission_state.accepted_planning_state"]

      Map.has_key?(Map.get(refresh, "mission_state", %{}), "spacecraft_states") ->
        ["candidate_refresh.mission_state.spacecraft_states"]

      true ->
        []
    end
  end

  defp candidate_refresh_target_sources(%{"targets" => target_specs} = refresh)
       when is_list(target_specs) do
    cond do
      target_specs != [] ->
        ["candidate_refresh.targets"]

      is_map(Map.get(refresh, "mission_state")) ->
        mission_state_target_sources(Map.get(refresh, "mission_state"))

      true ->
        ["candidate_refresh.targets"]
    end
  end

  defp candidate_refresh_target_sources(%{"mission_state" => %{} = mission_state}),
    do: mission_state_target_sources(mission_state)

  defp candidate_refresh_target_sources(_refresh), do: []

  defp mission_state_target_sources(%{} = mission_state) do
    []
    |> maybe_append_source(
      "candidate_refresh.mission_state.targets",
      non_empty_list?(Map.get(mission_state, "targets"))
    )
    |> maybe_append_source(
      "candidate_refresh.mission_state.objectives",
      mission_state_objective_targets_present?(mission_state)
    )
  end

  defp candidate_refresh_ground_station_sources(%{
         "ground_stations" => station_specs,
         "candidate_refresh" => %{} = refresh
       })
       when is_list(station_specs) do
    cond do
      station_specs != [] ->
        ["ground_stations"]

      is_map(Map.get(refresh, "mission_state")) ->
        mission_state_ground_station_sources(Map.get(refresh, "mission_state"))

      true ->
        ["ground_stations"]
    end
  end

  defp candidate_refresh_ground_station_sources(%{
         "candidate_refresh" => %{"mission_state" => %{} = mission_state}
       }),
       do: mission_state_ground_station_sources(mission_state)

  defp candidate_refresh_ground_station_sources(_source), do: []

  defp mission_state_ground_station_sources(%{} = mission_state) do
    []
    |> maybe_append_source(
      "candidate_refresh.mission_state.ground_stations",
      non_empty_list?(Map.get(mission_state, "ground_stations"))
    )
    |> maybe_append_source(
      "candidate_refresh.mission_state.ground_network",
      mission_state_ground_network_geometry_present?(mission_state)
    )
  end

  defp mission_state_objective_targets_present?(%{"objectives" => objectives})
       when is_list(objectives) do
    Enum.any?(objectives, fn objective ->
      objective
      |> objective_target_specs()
      |> Enum.any?(&target_geometry?/1)
    end)
  end

  defp mission_state_objective_targets_present?(_mission_state), do: false

  defp mission_state_ground_network_geometry_present?(%{"ground_network" => ground_network})
       when is_list(ground_network),
       do: Enum.any?(ground_network, &ground_station_geometry?/1)

  defp mission_state_ground_network_geometry_present?(_mission_state), do: false

  defp target_geometry?(%{"latitude_deg" => latitude_deg, "longitude_deg" => longitude_deg})
       when is_number(latitude_deg) and is_number(longitude_deg),
       do: true

  defp target_geometry?(_target), do: false

  defp ground_station_geometry?(%{
         "latitude_deg" => latitude_deg,
         "longitude_deg" => longitude_deg
       })
       when is_number(latitude_deg) and is_number(longitude_deg),
       do: true

  defp ground_station_geometry?(_station), do: false

  defp non_empty_list?(value), do: is_list(value) and value != []

  defp maybe_append_source(sources, source, true), do: sources ++ [source]
  defp maybe_append_source(sources, _source, false), do: sources

  defp normalize_target_spec(%{} = target) do
    target
    |> Map.put_new("id", Map.get(target, "target_id"))
    |> Map.put_new("minimum_elevation_deg", 10.0)
  end

  defp objective_target_selector_aliases do
    [
      "target",
      "target_ids",
      "targets",
      "target_specs",
      "required_target_ids",
      "required_targets",
      "committed_targets",
      "priority_targets",
      "uncovered_target_ids",
      "uncovered_targets",
      "unsatisfied_target_ids",
      "unsatisfied_targets",
      "missing_target_ids",
      "missing_targets",
      "missed_target",
      "missed_targets",
      "target_gap_ids",
      "target_gap_targets"
    ]
  end

  defp target_spec_values(values) when is_list(values),
    do: Enum.flat_map(values, &target_spec_values/1)

  defp target_spec_values(%{} = value), do: [value]
  defp target_spec_values(_value), do: []
end
