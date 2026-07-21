defmodule OrbitalDynamics.CandidateRefresh.ObservationObjectives do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.ObjectiveMatching
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.TargetObservationObjectiveType

  def context(
        refresh,
        scenario_id,
        target_id,
        policy,
        refresh_objectives,
        policy_number,
        numeric_value
      ) do
    objectives =
      refresh
      |> objectives(refresh_objectives)
      |> Enum.filter(fn objective ->
        matches_candidate?(
          objective,
          refresh,
          scenario_id,
          target_id,
          &ObjectiveMatching.matches_spacecraft?/3,
          &encode_value/1
        )
      end)

    required_observations =
      objectives
      |> Enum.map(&required_observations(&1, numeric_value))
      |> Enum.filter(&(is_number(&1) and &1 > 0.0))
      |> Enum.sum()

    if objectives == [] or required_observations <= 0.0 do
      {%{}, %{}}
    else
      objective_ids =
        objectives
        |> Enum.map(&ObjectiveMatching.id/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      objective_types =
        objectives
        |> Enum.map(&Map.get(&1, "type"))
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      weight = policy_number.(policy, "observation_objective_weight", 25.0)

      {
        %{
          "observation_objective_count" => length(objectives),
          "observation_objective_ids" => objective_ids,
          "observation_objective_types" => objective_types,
          "required_observations" => required_observations,
          "observation_objective_source" => "candidate_refresh.objectives.observation"
        },
        %{"observation_objective_value" => required_observations * weight}
      }
    end
  end

  def objectives(refresh, refresh_objectives) do
    refresh
    |> refresh_objectives.()
    |> Enum.filter(fn
      %{"type" => type} ->
        TargetObservationObjectiveType.supported?(type) or
          type in [
            "target_revisit",
            "target_coverage",
            "coverage",
            "priority_commitment",
            "urgent_target"
          ]

      _objective ->
        false
    end)
  end

  def matches_candidate?(
        objective,
        refresh,
        scenario_id,
        target_id,
        objective_matches_spacecraft,
        encode_value
      ) do
    matches_target?(objective, target_id, encode_value) and
      objective_matches_spacecraft.(objective, refresh, scenario_id)
  end

  def target_identity_value(%{} = target, encode_value) do
    Enum.find_value(["target_id", "id"], fn field ->
      target_identity_value(Map.get(target, field), encode_value)
    end)
  end

  def target_identity_value(value, encode_value), do: encode_value.(value)

  def target_priority(
        refresh,
        scenario_id,
        target_id,
        base_priority,
        base_source,
        encode_value,
        numeric_value,
        refresh_objectives
      ) do
    priority_objectives =
      refresh
      |> refresh_objectives.()
      |> Enum.filter(
        &target_priority_candidate?(
          &1,
          refresh,
          scenario_id,
          target_id,
          encode_value
        )
      )
      |> Enum.map(fn objective ->
        {objective, objective_target_priority(objective, target_id, encode_value, numeric_value)}
      end)
      |> Enum.filter(fn {_objective, priority} -> is_number(priority) end)
      |> Enum.sort_by(fn {objective, priority} ->
        {-priority, ObjectiveMatching.id(objective) || ""}
      end)

    case priority_objectives do
      [{objective, priority} | _rest] when priority > base_priority ->
        objective_ids =
          priority_objectives
          |> Enum.filter(fn {_objective, objective_priority} ->
            objective_priority == priority
          end)
          |> Enum.map(fn {objective, _priority} ->
            ObjectiveMatching.id(objective)
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.sort()

        {
          priority,
          %{
            "target_priority_source" => "candidate_refresh.objectives.observation_priority",
            "target_priority_objective_ids" => objective_ids,
            "target_priority_objective_type" => Map.get(objective, "type")
          }
          |> compact_map()
        }

      _objectives ->
        {base_priority, %{"target_priority_source" => base_source}}
    end
  end

  defp target_priority_candidate?(
         objective,
         refresh,
         scenario_id,
         target_id,
         encode_value
       ) do
    target_priority_matches_target?(objective, target_id, encode_value) and
      ObjectiveMatching.matches_spacecraft?(objective, refresh, scenario_id)
  end

  defp target_priority_matches_target?(objective, target_id, encode_value) do
    target_id = encode_value.(target_id)
    objective_target_id = target_priority_objective_target_id(objective, encode_value)
    objective_target_ids = target_priority_objective_target_ids(objective, encode_value)

    cond do
      objective_target_id in [nil, ""] and objective_target_ids == [] ->
        true

      encode_value.(objective_target_id) == target_id ->
        true

      target_id in objective_target_ids ->
        true

      true ->
        false
    end
  end

  defp target_priority_objective_target_id(objective, encode_value) do
    target_priority_identity_value(Map.get(objective, "target_id"), encode_value) ||
      target_priority_identity_value(Map.get(objective, "target"), encode_value)
  end

  defp target_priority_objective_target_ids(objective, encode_value) do
    target_selector_aliases()
    |> Enum.map(&Map.get(objective, &1))
    |> List.flatten()
    |> Enum.map(&target_priority_identity_value(&1, encode_value))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp target_priority_identity_value(%{} = target, encode_value) do
    Enum.find_value(["target_id", "id"], fn field ->
      target_priority_identity_value(Map.get(target, field), encode_value)
    end)
  end

  defp target_priority_identity_value(value, encode_value), do: encode_value.(value)

  def target_specs(objective) do
    ["target" | target_selector_aliases()]
    |> Enum.flat_map(&target_spec_values(Map.get(objective, &1)))
  end

  defp matches_target?(objective, target_id, encode_value) do
    target_id = encode_value.(target_id)
    objective_target_id = objective_target_id(objective, encode_value)
    objective_target_ids = objective_target_ids(objective, encode_value)

    cond do
      objective_target_id in [nil, ""] and objective_target_ids == [] ->
        true

      encode_value.(objective_target_id) == target_id ->
        true

      target_id in objective_target_ids ->
        true

      true ->
        false
    end
  end

  defp objective_target_id(objective, encode_value) do
    target_identity_value(Map.get(objective, "target_id"), encode_value) ||
      target_identity_value(Map.get(objective, "target"), encode_value)
  end

  defp objective_target_ids(objective, encode_value) do
    target_selector_aliases()
    |> Enum.map(&Map.get(objective, &1))
    |> List.flatten()
    |> Enum.map(&target_identity_value(&1, encode_value))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp target_selector_aliases do
    [
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

  defp required_observations(objective, numeric_value) do
    Enum.find_value(
      [
        "required_observations",
        "required_revisits",
        "required_count",
        "required_observation_count",
        "min_observations",
        "missing_observation_count",
        "target_gap_count",
        "target_coverage_gap_count",
        "coverage_gap_count"
      ],
      fn field ->
        case numeric_value.(Map.get(objective, field)) do
          value when is_number(value) -> max(value * 1.0, 0.0)
          _value -> nil
        end
      end
    ) || 1.0
  end

  defp objective_target_priority(objective, target_id, encode_value, numeric_value) do
    objective_target_spec_priority(objective, target_id, encode_value, numeric_value) ||
      direct_objective_top_level_target_priority(objective, numeric_value)
  end

  defp objective_target_spec_priority(objective, target_id, encode_value, numeric_value) do
    target_id = encode_value.(target_id)

    objective
    |> target_specs()
    |> Enum.filter(&(target_priority_identity_value(&1, encode_value) == target_id))
    |> Enum.map(&direct_target_spec_priority(&1, numeric_value))
    |> Enum.filter(&is_number/1)
    |> Enum.max(fn -> nil end)
  end

  defp target_spec_values(values) when is_list(values),
    do: Enum.flat_map(values, &target_spec_values/1)

  defp target_spec_values(%{} = value), do: [value]
  defp target_spec_values(_value), do: []

  defp direct_target_spec_priority(%{} = target, numeric_value) do
    Enum.find_value(["target_priority", "priority", "urgency", "target_value"], fn field ->
      case numeric_value.(Map.get(target, field)) do
        value when is_number(value) ->
          max(value, 0.0)

        _value ->
          nil
      end
    end)
  end

  defp direct_objective_top_level_target_priority(objective, numeric_value) do
    Enum.find_value(["target_priority", "priority", "urgency", "target_value"], fn field ->
      case numeric_value.(Map.get(objective, field)) do
        value when is_number(value) ->
          max(value, 0.0)

        _value ->
          nil
      end
    end)
  end

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
