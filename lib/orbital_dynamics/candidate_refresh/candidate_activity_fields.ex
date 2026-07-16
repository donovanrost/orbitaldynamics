defmodule OrbitalDynamics.CandidateRefresh.CandidateActivityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  @event_timing_keys [
    :interpolation,
    :boundary_refinement,
    :start_boundary,
    :end_boundary,
    :start_boundary_detail,
    :end_boundary_detail,
    :event_timing_policy,
    :event_detector,
    :event_time_tolerance_s,
    :max_sample_step_s,
    :confidence
  ]

  def event_timing_keys, do: @event_timing_keys

  def score(score_terms), do: score_terms |> Map.values() |> Enum.sum()

  def event_timing_metadata(metadata) do
    metadata
    |> Map.take(@event_timing_keys)
    |> encode_value()
  end

  def epoch_seconds(%{seconds_since_j2000: seconds}), do: seconds

  def window_id(scenario_id, type, source_id, index) do
    ["window", scenario_id, type, source_id, index]
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  def activity_id(scenario_id, type, source_id, index) do
    [scenario_id, type, source_id, index]
    |> Enum.map(&encode_value/1)
    |> Enum.join("_")
  end

  def policy_number(policy, key, default) do
    case ValueEncoding.numeric_value(Map.get(policy, key)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

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
