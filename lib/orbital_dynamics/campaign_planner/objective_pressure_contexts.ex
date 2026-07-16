defmodule OrbitalDynamics.CampaignPlanner.ObjectivePressureContexts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ScoreTermIdentifiers
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def observation_context_value(row, fields),
    do: observation_context_value(row, fields, callbacks())

  def observation_context_value(row, fields, callbacks) do
    row
    |> observation_contexts(callbacks)
    |> Enum.find_value(fn context ->
      Enum.find_value(fields, fn field -> Map.get(context, field) end)
    end)
  end

  def observation_context_entity_id(row, fields, entity_keys) do
    observation_context_entity_id(row, fields, entity_keys, callbacks())
  end

  def observation_context_entity_id(row, fields, entity_keys, callbacks) do
    entity_id = Keyword.fetch!(callbacks, :entity_id)

    row
    |> observation_contexts(callbacks)
    |> Enum.find_value(fn context ->
      Enum.find_value(fields, fn field ->
        context
        |> Map.get(field)
        |> entity_id.(entity_keys)
      end)
    end)
  end

  def observation_context_number(row, fields),
    do: observation_context_number(row, fields, callbacks())

  def observation_context_number(row, fields, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    row
    |> observation_context_value(fields, callbacks)
    |> numeric_or_nil.()
  end

  def observation_contexts(row), do: observation_contexts(row, callbacks())

  def observation_contexts(row, callbacks) do
    [
      row["source_observation"],
      row["source_observations"],
      row["observation"],
      row["observations"],
      row["selected_observation"],
      row["selected_observations"],
      row["satisfied_observation"],
      row["satisfied_observations"],
      row["candidate_observation"],
      row["candidate_observations"],
      row["source_activity"],
      row["source_activities"],
      row["activity"],
      row["activities"]
    ]
    |> Enum.flat_map(&observation_context_maps(&1, callbacks))
  end

  def observation_context_maps(values), do: observation_context_maps(values, callbacks())

  def observation_context_maps(values, callbacks) when is_list(values) do
    Enum.flat_map(values, &observation_context_maps(&1, callbacks))
  end

  def observation_context_maps(%{} = context, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    [stringify_keys.(context)]
  end

  def observation_context_maps(_context, _callbacks), do: []

  def gap_context_target_ids(row), do: gap_context_target_ids(row, callbacks())

  def gap_context_target_ids(row, callbacks) do
    target_ids = Keyword.fetch!(callbacks, :target_ids)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    row
    |> gap_contexts(callbacks)
    |> Enum.flat_map(fn context ->
      [
        context["target_id"],
        context["target_ids"],
        context["target"],
        context["targets"],
        context["target_spec"],
        context["target_specs"]
      ]
      |> Enum.flat_map(&target_ids.(&1))
    end)
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
  end

  def gap_context_target_spec(row, target_id),
    do: gap_context_target_spec(row, target_id, callbacks())

  def gap_context_target_spec(row, target_id, callbacks) do
    row
    |> gap_contexts(callbacks)
    |> Enum.find_value(fn context ->
      cond do
        context["target_id"] == target_id ->
          context

        true ->
          context
          |> gap_context_target_specs(callbacks)
          |> Enum.find(fn target ->
            (Map.get(target, "target_id") || Map.get(target, "id")) == target_id
          end)
      end
    end)
  end

  def gap_context_target_specs(context), do: gap_context_target_specs(context, callbacks())

  def gap_context_target_specs(context, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    [
      context["target"],
      context["targets"],
      context["target_spec"],
      context["target_specs"]
    ]
    |> List.flatten()
    |> Enum.map(fn
      %{} = target -> stringify_keys.(target)
      _target -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  def gap_contexts(row), do: gap_contexts(row, callbacks())

  def gap_contexts(row, callbacks) do
    [
      row["source_observation"],
      row["source_observations"],
      row["observation"],
      row["observations"],
      row["candidate_observation"],
      row["candidate_observations"],
      row["source_activity"],
      row["source_activities"],
      row["activity"],
      row["activities"],
      row["candidate_activity"],
      row["candidate_activities"]
    ]
    |> Enum.flat_map(&observation_context_maps(&1, callbacks))
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      entity_id: &ScoreTermIdentifiers.entity_id/2,
      target_ids: &ScoreTermIdentifiers.target_ids/1
    ]
  end
end
