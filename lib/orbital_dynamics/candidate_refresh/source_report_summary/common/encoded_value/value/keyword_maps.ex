defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue.Value.KeywordMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue.Value

  def value(%{} = map) do
    Map.new(map, fn {key, value} ->
      {value(key), value(value)}
    end)
  end

  def value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} ->
        {value(key), value(value)}
      end)
    else
      Enum.map(values, &value/1)
    end
  end

  def value(value) when is_tuple(value) do
    value |> Tuple.to_list() |> value()
  end

  def value(value), do: Value.value(value)
end
