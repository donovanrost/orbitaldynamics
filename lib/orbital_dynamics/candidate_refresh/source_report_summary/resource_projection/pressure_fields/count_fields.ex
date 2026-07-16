defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields do
  @moduledoc false

  alias __MODULE__.CountMaps
  alias __MODULE__.FieldSpecs

  def fields(reports) do
    FieldSpecs.values()
    |> Map.new(fn {field, values_fun} ->
      {field, CountMaps.merged_count_values(reports, values_fun)}
    end)
  end
end
