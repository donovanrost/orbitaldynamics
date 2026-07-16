defmodule OrbitalDynamics.CampaignPlanner.ObjectiveTargetIdentifiers do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ObjectivePressureContexts
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def target_id_values(row, fields), do: target_id_values(row, fields, callbacks())

  def target_id_values(row, fields, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    fields
    |> Enum.flat_map(fn field -> target_ids(Map.get(row, field), callbacks) end)
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
  end

  def target_ids(values), do: target_ids(values, callbacks())

  def target_ids(values, callbacks) when is_list(values) do
    Enum.flat_map(values, &target_ids(&1, callbacks))
  end

  def target_ids(%{} = target, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    target = stringify_keys.(target)
    [Map.get(target, "target_id") || Map.get(target, "id")]
  end

  def target_ids(value, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    [encode_value.(value)]
  end

  def target_count_or_nil(target_ids) do
    target_ids
    |> Enum.uniq()
    |> case do
      [] -> nil
      ids -> length(ids)
    end
  end

  def target_spec(row, target_id), do: target_spec(row, target_id, callbacks())

  def target_spec(row, target_id, callbacks) do
    target_spec(row, target_id, default_target_spec_fields(row), callbacks)
  end

  def target_spec_from_fields(row, target_id, fields) do
    target_spec(row, target_id, fields, callbacks())
  end

  def target_spec(row, target_id, fields, callbacks) do
    gap_context_target_spec = Keyword.fetch!(callbacks, :gap_context_target_spec)

    fields
    |> target_specs(callbacks)
    |> Enum.find(fn target ->
      (Map.get(target, "target_id") || Map.get(target, "id")) == target_id
    end)
    |> case do
      %{} = target -> target
      _target -> gap_context_target_spec.(row, target_id) || %{}
    end
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      encode_value: &ValueEncoding.encode_value/1,
      gap_context_target_spec: &gap_context_target_spec/2
    ]
  end

  defp objective_pressure_context_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp gap_context_target_spec(row, target_id) do
    ObjectivePressureContexts.gap_context_target_spec(
      row,
      target_id,
      objective_pressure_context_callbacks()
    )
  end

  defp default_target_spec_fields(row) do
    [
      row["target"],
      row["targets"],
      row["target_spec"],
      row["target_specs"],
      row["required_target"],
      row["required_targets"],
      row["committed_target"],
      row["committed_targets"],
      row["priority_target"],
      row["priority_targets"],
      row["candidate_target"],
      row["candidate_targets"],
      row["uncovered_target"],
      row["uncovered_targets"],
      row["unsatisfied_target"],
      row["unsatisfied_targets"],
      row["missing_target"],
      row["missing_targets"],
      row["missed_target"],
      row["missed_targets"],
      row["missed_observation_target"],
      row["missed_observation_targets"],
      row["revisit_target"],
      row["revisit_targets"],
      row["required_revisit_target"],
      row["required_revisit_targets"],
      row["missing_revisit_target"],
      row["missing_revisit_targets"],
      row["coverage_target"],
      row["coverage_targets"],
      row["required_coverage_target"],
      row["required_coverage_targets"],
      row["missing_coverage_target"],
      row["missing_coverage_targets"],
      row["target_gap_target"],
      row["target_gap_targets"]
    ]
  end

  defp target_specs(values, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    values
    |> List.flatten()
    |> Enum.map(fn
      %{} = target -> stringify_keys.(target)
      _target -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end
end
