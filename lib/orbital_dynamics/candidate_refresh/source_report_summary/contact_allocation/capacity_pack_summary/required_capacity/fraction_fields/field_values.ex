defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.RequiredCapacity.FractionFields.FieldValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.RequiredCapacity.AggregateValues

  alias __MODULE__.FieldSpecs

  def fields(reports) do
    Map.merge(numeric_sum_fields(reports), numeric_map_fields(reports))
  end

  defp numeric_sum_fields(reports) do
    build_fields(reports, &AggregateValues.numeric_sum/2, FieldSpecs.numeric_sums())
  end

  defp numeric_map_fields(reports) do
    build_fields(reports, &AggregateValues.numeric_map_merge/2, FieldSpecs.numeric_maps())
  end

  defp build_fields(reports, aggregate, fields) do
    Map.new(fields, fn {field, extractor} -> {field, aggregate.(reports, extractor)} end)
  end
end
