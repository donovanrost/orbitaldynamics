defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.Common do
  @moduledoc false

  def quality_gate_status_classification("blocked"), do: "blocked"
  def quality_gate_status_classification("analysis_only"), do: "analysis_only"
  def quality_gate_status_classification(_status), do: "review_only"

  def quality_gate_status_readiness_level("blocked"), do: "blocked"
  def quality_gate_status_readiness_level("analysis_only"), do: "analysis_only"
  def quality_gate_status_readiness_level(_status), do: "operator_review"

  def count_map_value_sum(counts) when is_map(counts) do
    counts
    |> Map.values()
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  def count_map_value_sum(_counts), do: 0

  def sorted_count_map_keys(counts) when is_map(counts) do
    counts
    |> stringify_keys()
    |> Enum.filter(fn {_key, value} ->
      case numeric_or_nil(value) do
        number when is_number(number) -> number > 0
        _value -> false
      end
    end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.sort()
  end

  def sorted_count_map_keys(_counts), do: []

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value), do: encode_value(value)

  def compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def numeric_or_nil(nil), do: nil
  def numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  def numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  def numeric_or_nil(_value), do: nil

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
