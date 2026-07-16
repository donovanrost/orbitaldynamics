defmodule OrbitalDynamics.CampaignPlanner.ObjectiveTradeoffTargets do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ObjectivePressureContexts
  alias OrbitalDynamics.CampaignPlanner.ObjectiveTargetIdentifiers
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ScoreTermValues

  @selected_target_fields [
    "selected_targets",
    "satisfied_targets",
    "selected_revisit_targets",
    "satisfied_revisit_targets",
    "selected_coverage_targets",
    "satisfied_coverage_targets",
    "selected_target_ids",
    "satisfied_target_ids",
    "selected_revisit_target_ids",
    "satisfied_revisit_target_ids",
    "selected_coverage_target_ids",
    "satisfied_coverage_target_ids"
  ]

  @required_target_fields [
    "required_target",
    "required_targets",
    "committed_target",
    "committed_targets",
    "priority_target",
    "priority_targets",
    "candidate_target",
    "candidate_targets",
    "uncovered_target",
    "uncovered_targets",
    "unsatisfied_target",
    "unsatisfied_targets",
    "missing_target",
    "missing_targets",
    "missed_target",
    "missed_targets",
    "missed_observation_target",
    "missed_observation_targets",
    "revisit_target",
    "revisit_targets",
    "required_revisit_target",
    "required_revisit_targets",
    "missing_revisit_target",
    "missing_revisit_targets",
    "coverage_target",
    "coverage_targets",
    "required_coverage_target",
    "required_coverage_targets",
    "missing_coverage_target",
    "missing_coverage_targets",
    "target_gap_target",
    "target_gap_targets",
    "missed_target_ids",
    "missed_observation_target_ids",
    "required_target_ids",
    "candidate_target_ids",
    "uncovered_target_ids",
    "unsatisfied_target_ids",
    "missing_target_ids",
    "revisit_target_ids",
    "required_revisit_target_ids",
    "missing_revisit_target_ids",
    "coverage_target_ids",
    "required_coverage_target_ids",
    "missing_coverage_target_ids",
    "target_gap_ids"
  ]

  @gap_target_fields [
    "target_id",
    "target",
    "target_ids",
    "targets",
    "target_spec",
    "target_specs"
    | @required_target_fields
  ]

  @missed_target_fields [
    "missed_target",
    "missed_targets",
    "missed_observation_target",
    "missed_observation_targets",
    "missed_target_ids",
    "missed_observation_target_ids"
  ]

  @requirement_universe_target_fields [
    "required_target",
    "required_targets",
    "committed_target",
    "committed_targets",
    "priority_target",
    "priority_targets",
    "candidate_target",
    "candidate_targets",
    "revisit_target",
    "revisit_targets",
    "required_revisit_target",
    "required_revisit_targets",
    "coverage_target",
    "coverage_targets",
    "required_coverage_target",
    "required_coverage_targets",
    "required_target_ids",
    "candidate_target_ids",
    "revisit_target_ids",
    "required_revisit_target_ids",
    "coverage_target_ids",
    "required_coverage_target_ids"
  ]

  def required_observations(row), do: required_observations(row, callbacks())

  def required_observations(row, callbacks) do
    explicit =
      [
        row["required_observations"],
        row["required_observation_count"],
        row["required_count"],
        row["required_revisits"],
        row["required_revisit_count"],
        row["target_required_revisit_count"],
        row["required_coverage_count"],
        row["target_required_coverage_count"]
      ]
      |> Enum.map(&numeric_or_nil(&1, callbacks))
      |> Enum.find(&is_number/1)

    explicit ||
      required_observations_from_direct_gap(row, callbacks) ||
      required_observations_from_score_terms(row, callbacks) ||
      required_target_count(row, callbacks)
  end

  def planned_observations(row), do: planned_observations(row, callbacks())

  def planned_observations(row, callbacks) do
    [
      row["planned_observations"],
      row["selected_observation_count"],
      row["planned_observation_count"],
      row["selected_count"],
      row["planned_revisits"],
      row["selected_revisits"],
      row["satisfied_revisits"],
      row["planned_revisit_count"],
      row["selected_revisit_count"],
      row["satisfied_revisit_count"],
      row["target_planned_revisit_count"],
      row["planned_coverage_count"],
      row["selected_coverage_count"],
      row["satisfied_coverage_count"],
      row["target_planned_coverage_count"]
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        value

      _value ->
        if requirement_universe_target_ids(row, callbacks) == [] do
          0
        else
          selected_target_count(row, callbacks) || 0
        end
    end
  end

  def gap_target_ids(row), do: gap_target_ids(row, callbacks())

  def gap_target_ids(row, callbacks) do
    selected_targets =
      row
      |> target_id_values(@selected_target_fields, callbacks)
      |> MapSet.new()

    row
    |> target_id_values(@gap_target_fields, callbacks)
    |> Kernel.++(gap_context_target_ids(row, callbacks))
    |> Enum.reject(&MapSet.member?(selected_targets, &1))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def has_missed_targets?(row), do: has_missed_targets?(row, callbacks())

  def has_missed_targets?(row, callbacks) do
    row
    |> target_id_values(@missed_target_fields, callbacks)
    |> Enum.any?()
  end

  def required_target_count(row), do: required_target_count(row, callbacks())

  def required_target_count(row, callbacks) do
    row
    |> target_id_values(@required_target_fields, callbacks)
    |> target_count_or_nil(callbacks)
  end

  def selected_target_count(row), do: selected_target_count(row, callbacks())

  def selected_target_count(row, callbacks) do
    row
    |> target_id_values(@selected_target_fields, callbacks)
    |> target_count_or_nil(callbacks)
  end

  def requirement_universe_target_ids(row), do: requirement_universe_target_ids(row, callbacks())

  def requirement_universe_target_ids(row, callbacks) do
    target_id_values(row, @requirement_universe_target_fields, callbacks)
  end

  def target_priority(row, target_spec), do: target_priority(row, target_spec, callbacks())

  def target_priority(row, target_spec, callbacks) do
    [
      target_spec["priority"],
      target_spec["target_priority"],
      row["priority"],
      row["target_priority"],
      score_term_number(row, ["target_value"], callbacks),
      score_term_number(row, ["mission_value_score"], callbacks)
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
  end

  def target_number(row, target_spec, field),
    do: target_number(row, target_spec, field, callbacks())

  def target_number(row, target_spec, field, callbacks) do
    numeric_or_nil(Map.get(target_spec, field) || Map.get(row, field), callbacks)
  end

  def target_reasons(row), do: target_reasons(row, callbacks())

  def target_reasons(row, callbacks) do
    []
    |> maybe_append_reason(true, "objective_tradeoff_target_gap")
    |> maybe_append_reason(
      has_missed_targets?(row, callbacks),
      "objective_tradeoff_missed_targets"
    )
    |> maybe_append_reason(
      score_term_target_gap?(row, callbacks),
      "objective_tradeoff_score_term_target_gap"
    )
    |> maybe_append_reason(row["selected"] == false, "objective_tradeoff_unselected")
    |> Enum.reverse()
  end

  def score_term_target_gap?(row), do: score_term_target_gap?(row, callbacks())

  def score_term_target_gap?(row, callbacks),
    do: positive_number?(score_term_target_gap(row, callbacks))

  def score_term_target_gap(row), do: score_term_target_gap(row, callbacks())

  def score_term_target_gap(row, callbacks) do
    score_term_number(
      row,
      [
        "observation_count_gap",
        "missing_observation_count",
        "target_observation_gap_count",
        "missed_target_count",
        "target_gap_count",
        "target_coverage_gap_count",
        "coverage_gap_count",
        "observation_shortfall_count",
        "revisit_gap_count",
        "missing_revisit_count",
        "target_revisit_gap_count",
        "revisit_shortfall_count",
        "coverage_shortfall_count"
      ],
      callbacks
    )
  end

  def direct_target_gap(row), do: direct_target_gap(row, callbacks())

  def direct_target_gap(row, callbacks) do
    [
      row["observation_count_gap"],
      row["missing_observation_count"],
      row["target_observation_gap_count"],
      row["observation_shortfall_count"],
      row["revisit_gap_count"],
      row["missing_revisit_count"],
      row["target_revisit_gap_count"],
      row["revisit_shortfall_count"],
      row["coverage_shortfall_count"],
      row["target_coverage_gap_count"],
      row["coverage_gap_count"]
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
  end

  defp required_observations_from_score_terms(row, callbacks) do
    case score_term_target_gap(row, callbacks) do
      gap when is_number(gap) and gap > 0.0 ->
        planned_observations(row, callbacks) + gap

      _gap ->
        nil
    end
  end

  defp required_observations_from_direct_gap(row, callbacks) do
    case direct_target_gap(row, callbacks) do
      gap when is_number(gap) and gap > 0.0 ->
        planned_observations(row, callbacks) + gap

      _gap ->
        nil
    end
  end

  defp callbacks do
    [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      score_term_number: &ScoreTermValues.number/2,
      target_count_or_nil: &ObjectiveTargetIdentifiers.target_count_or_nil/1,
      target_id_values: &ObjectiveTargetIdentifiers.target_id_values/2,
      gap_context_target_ids: &ObjectivePressureContexts.gap_context_target_ids/1
    ]
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp numeric_or_nil(value, callbacks), do: callback(callbacks, :numeric_or_nil, [value])

  defp score_term_number(row, keys, callbacks),
    do: callback(callbacks, :score_term_number, [row, keys])

  defp target_count_or_nil(target_ids, callbacks),
    do: callback(callbacks, :target_count_or_nil, [target_ids])

  defp target_id_values(row, fields, callbacks),
    do: callback(callbacks, :target_id_values, [row, fields])

  defp gap_context_target_ids(row, callbacks),
    do: callback(callbacks, :gap_context_target_ids, [row])

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, false, _reason), do: reasons
end
