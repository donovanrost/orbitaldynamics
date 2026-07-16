defmodule OrbitalDynamics.CampaignPlanner.TargetObjectiveSelectors do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.BranchRefreshTargets
  alias OrbitalDynamics.CampaignPlanner.ObjectiveWindowBounds
  alias OrbitalDynamics.CampaignPlanner.TargetObjectiveRequirements

  def expand(objective) do
    case target_ids(objective) do
      [] ->
        [objective]

      target_ids ->
        target_specs = target_specs(objective)

        Enum.map(target_ids, fn target_id ->
          objective
          |> Map.put("target_id", target_id)
          |> maybe_put_objective_id()
          |> maybe_put_commitment_id()
          |> put_inline_target_spec(target_specs[target_id])
        end)
    end
  end

  def coverage_objectives(mission_state) do
    target_catalog = mission_state_target_catalog(mission_state)

    mission_state
    |> Map.get("objectives", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&coverage_objective?/1)
    |> Enum.flat_map(&coverage_objective_targets(&1, target_catalog))
  end

  def coverage_objective?(%{"type" => type}), do: type in ["target_coverage", "coverage"]
  def coverage_objective?(_objective), do: false

  def put_objective_id(%{"id" => id} = objective) when id not in [nil, ""],
    do: Map.put_new(objective, "objective_id", id)

  def put_objective_id(objective), do: objective

  def put_commitment_id(%{"type" => "priority_commitment"} = objective) do
    Map.put_new(objective, "commitment_id", Map.get(objective, "id"))
  end

  def put_commitment_id(objective), do: objective

  defp maybe_put_objective_id(objective), do: put_objective_id(objective)

  defp maybe_put_commitment_id(objective), do: put_commitment_id(objective)

  defp put_inline_target_spec(objective, nil), do: objective

  defp put_inline_target_spec(objective, target) do
    target
    |> Map.take(["latitude_deg", "longitude_deg", "minimum_elevation_deg", "priority"])
    |> Enum.reduce(objective, fn {key, value}, acc -> Map.put_new(acc, key, value) end)
  end

  defp coverage_objective_targets(objective, target_catalog) do
    inline_targets = target_specs(objective)

    target_ids =
      case target_ids(objective) do
        [] -> Map.keys(inline_targets) ++ Map.keys(target_catalog)
        ids -> ids
      end

    target_ids
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(fn target_id ->
      target = Map.get(inline_targets, target_id) || Map.get(target_catalog, target_id, %{})

      %{
        "type" => "target_coverage",
        "target_id" => target_id,
        "scenario_id" => Map.get(objective, "scenario_id"),
        "priority" => Map.get(objective, "priority") || Map.get(target, "priority"),
        "required_observations" =>
          TargetObjectiveRequirements.required_observation_count(objective),
        "coverage_objective_id" => Map.get(objective, "id"),
        "starts_at_s" => ObjectiveWindowBounds.start(objective, nil),
        "ends_at_s" => ObjectiveWindowBounds.finish(objective, nil),
        "candidate_windows" => Map.get(objective, "candidate_windows"),
        "spacecraft_constraints" => Map.get(objective, "spacecraft_constraints"),
        "latitude_deg" => Map.get(target, "latitude_deg"),
        "longitude_deg" => Map.get(target, "longitude_deg"),
        "minimum_elevation_deg" => Map.get(target, "minimum_elevation_deg")
      }
      |> compact_map()
    end)
  end

  defp target_specs(objective) do
    [
      Map.get(objective, "targets"),
      Map.get(objective, "target_specs"),
      Map.get(objective, "required_targets"),
      Map.get(objective, "committed_targets"),
      Map.get(objective, "priority_targets")
    ]
    |> Enum.flat_map(fn
      targets when is_list(targets) -> targets
      _other -> []
    end)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&BranchRefreshTargets.normalize_target_spec/1)
    |> Enum.filter(&BranchRefreshTargets.target_spec?/1)
    |> unique_items_by_id()
    |> Map.new(&{Map.get(&1, "id"), &1})
  end

  defp target_ids(objective) do
    [
      Map.get(objective, "target_id"),
      Map.get(objective, "target_ids"),
      Map.get(objective, "required_target_ids"),
      Map.get(objective, "targets"),
      Map.get(objective, "target_specs"),
      Map.get(objective, "required_targets"),
      Map.get(objective, "committed_targets"),
      Map.get(objective, "priority_targets")
    ]
    |> Enum.flat_map(fn
      values when is_list(values) -> Enum.map(values, &target_id/1)
      value -> [target_id(value)]
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp target_id(%{} = target) do
    target = stringify_keys(target)
    Map.get(target, "target_id") || Map.get(target, "id")
  end

  defp target_id(target_id), do: encode_value(target_id)

  defp mission_state_target_catalog(mission_state) do
    mission_state
    |> Map.get("targets", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&BranchRefreshTargets.normalize_target_spec/1)
    |> unique_items_by_id()
    |> Map.new(&{Map.get(&1, "id"), &1})
  end

  defp unique_items_by_id(items) do
    items
    |> Enum.group_by(&Map.get(&1, "id"))
    |> Enum.reject(fn {id, _items} -> id in [nil, ""] end)
    |> Enum.flat_map(fn
      {_id, [item]} -> [item]
      {_id, _duplicates} -> []
    end)
    |> Enum.sort_by(& &1["id"])
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
