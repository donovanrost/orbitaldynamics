defmodule OrbitalDynamics.Study.Manifest.TargetCatalogInput do
  @moduledoc false

  alias OrbitalDynamics.Target

  alias OrbitalDynamics.Study.Manifest.{
    CandidateRefreshRunInputSources,
    InputField
  }

  def parse(%{"campaign" => %{"targets" => target_specs}}) when is_list(target_specs) do
    parse_targets(target_specs, "campaign.targets")
  end

  def parse(%{"campaign" => %{"targets" => _targets}}),
    do: {:error, {:invalid_field, "campaign.targets"}}

  def parse(%{"candidate_refresh" => %{"targets" => []} = refresh}) do
    case candidate_refresh_mission_state(refresh) do
      {:ok, mission_state} when map_size(mission_state) > 0 ->
        mission_state
        |> mission_state_target_specs()
        |> parse_targets("candidate_refresh.mission_state.targets")

      _mission_state ->
        {:ok, []}
    end
  end

  def parse(%{"candidate_refresh" => %{"targets" => target_specs}})
      when is_list(target_specs) do
    parse_targets(target_specs, "candidate_refresh.targets")
  end

  def parse(%{"candidate_refresh" => %{"targets" => _targets}}),
    do: {:error, {:invalid_field, "candidate_refresh.targets"}}

  def parse(%{"candidate_refresh" => %{"mission_state" => %{} = mission_state}}) do
    mission_state
    |> mission_state_target_specs()
    |> parse_targets("candidate_refresh.mission_state.targets")
  end

  def parse(_source), do: {:ok, []}

  defp parse_targets(target_specs, field) when is_list(target_specs) do
    target_specs
    |> Enum.reduce_while({:ok, []}, fn target_spec, {:ok, targets} ->
      case target(target_spec, field) do
        {:ok, target} -> {:cont, {:ok, targets ++ [target]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp parse_targets(:invalid, field), do: {:error, {:invalid_field, field}}

  defp target(%{} = spec, _field) do
    with {:ok, id} <- InputField.required(spec, "id"),
         {:ok, latitude_deg} <- InputField.required_number(spec, "latitude_deg"),
         {:ok, longitude_deg} <- InputField.required_number(spec, "longitude_deg"),
         {:ok, altitude_km} <- InputField.optional_number(spec, "altitude_km"),
         {:ok, minimum_elevation_deg} <-
           InputField.optional_number(spec, "minimum_elevation_deg"),
         {:ok, priority} <- InputField.optional_number(spec, "priority") do
      {:ok,
       Target.new!(
         id,
         latitude_deg,
         longitude_deg,
         compact_keyword(
           altitude_km: altitude_km,
           minimum_elevation_deg: minimum_elevation_deg,
           priority: priority
         )
       )}
    end
  end

  defp target(_spec, field), do: {:error, {:invalid_field, field}}

  defp mission_state_target_specs(%{} = mission_state) do
    case mission_state_target_catalog_specs(mission_state) do
      :invalid ->
        :invalid

      catalog_specs ->
        case mission_state_objective_target_specs(mission_state) do
          :invalid when catalog_specs == [] -> :invalid
          :invalid -> catalog_specs
          objective_specs -> unique_specs_by_id(catalog_specs ++ objective_specs)
        end
    end
  end

  defp mission_state_target_catalog_specs(%{"targets" => target_specs})
       when is_list(target_specs) do
    target_specs
    |> Enum.map(&normalize_target_spec/1)
    |> unique_specs_by_id()
  end

  defp mission_state_target_catalog_specs(%{"targets" => _target_specs}), do: :invalid
  defp mission_state_target_catalog_specs(_mission_state), do: []

  defp mission_state_objective_target_specs(%{"objectives" => objectives})
       when is_list(objectives) do
    objectives
    |> Enum.flat_map(&CandidateRefreshRunInputSources.objective_target_specs/1)
    |> Enum.filter(fn
      %{"latitude_deg" => latitude_deg, "longitude_deg" => longitude_deg}
      when is_number(latitude_deg) and is_number(longitude_deg) ->
        true

      _target ->
        false
    end)
    |> unique_specs_by_id()
  end

  defp mission_state_objective_target_specs(%{"objectives" => _objectives}), do: :invalid
  defp mission_state_objective_target_specs(_mission_state), do: []

  defp normalize_target_spec(%{} = target) do
    target
    |> Map.put_new("id", Map.get(target, "target_id"))
    |> Map.put_new("minimum_elevation_deg", 10.0)
  end

  defp normalize_target_spec(target), do: target

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
