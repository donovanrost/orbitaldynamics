defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields.ThroughputMaps.ValueMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.NumericValues,
    as: DirectionNumericValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_numeric_maps: 1
    ]

  def from_reports(reports) do
    Map.new(FieldSpecs.all(), fn {key, source_field, _output_field} ->
      {key, direction_numeric_map_merge(reports, source_field)}
    end)
  end

  def fields(%{} = values) do
    Map.new(FieldSpecs.all(), fn {key, _source_field, output_field} ->
      {output_field, Map.fetch!(values, key)}
    end)
  end

  defp direction_numeric_map_merge(reports, field) do
    reports
    |> Enum.map(&DirectionNumericValues.numeric_values_by_direction(&1, field))
    |> merge_numeric_maps()
  end
end
