defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue.StringKeys.Traversal do
  @moduledoc false

  def map(%_struct{} = struct, key_value, scalar_value) do
    struct
    |> Map.from_struct()
    |> map(key_value, scalar_value)
  end

  def map(%{} = values, key_value, scalar_value) do
    Map.new(values, fn {key, value} ->
      {key_value.(key), map(value, key_value, scalar_value)}
    end)
  end

  def map(values, key_value, scalar_value) when is_list(values) do
    Enum.map(values, &map(&1, key_value, scalar_value))
  end

  def map(value, _key_value, scalar_value), do: scalar_value.(value)
end
