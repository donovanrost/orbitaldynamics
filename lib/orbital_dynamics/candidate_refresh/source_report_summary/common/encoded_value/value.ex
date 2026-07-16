defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue.Value do
  @moduledoc false

  alias __MODULE__.KeywordMaps

  def value(%{} = map) do
    Map.new(map, fn {key, value} -> {value(key), value(value)} end)
  end

  def value(values) when is_list(values) do
    Enum.map(values, &value/1)
  end

  def value(value) when is_tuple(value), do: value |> Tuple.to_list() |> value()
  def value(nil), do: nil
  def value(value) when is_boolean(value), do: value
  def value(value) when is_atom(value), do: Atom.to_string(value)
  def value(value), do: value

  def value_with_keyword_maps(value), do: KeywordMaps.value(value)
end
