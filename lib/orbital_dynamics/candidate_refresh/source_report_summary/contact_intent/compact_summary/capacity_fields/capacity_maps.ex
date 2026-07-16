defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields.CapacityMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias __MODULE__.MapValues
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def compact_capacity_fields(summaries) do
    MapValues.values(summaries, FieldSpecs.compact())
  end

  def input_capacity_fields(summaries) do
    MapValues.values(summaries, FieldSpecs.input())
  end

  def required_capacity_fraction(summaries, field) do
    summaries
    |> Enum.map(&(Map.get(&1, field) |> NumericValue.value()))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end
end
