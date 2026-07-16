defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.ValueMaps do
  @moduledoc false

  alias __MODULE__.NormalizedMaps

  def nested_map_value_lists(%{} = value_map) do
    NormalizedMaps.nested_map_value_lists(value_map)
  end

  def nested_map_value_lists(_value_map), do: nil

  def map_value_lists(%{} = value_map) do
    NormalizedMaps.map_value_lists(value_map)
  end

  def map_value_lists(_value), do: nil

  def normalize_numeric_map(%{} = value_map) do
    NormalizedMaps.normalize_numeric_map(value_map)
  end

  def normalize_numeric_map(_value_map), do: nil

  def nested_normalize_numeric_map(%{} = value_map) do
    NormalizedMaps.nested_normalize_numeric_map(value_map)
  end

  def nested_normalize_numeric_map(_value_map), do: nil
end
