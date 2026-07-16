defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.IdFields.ValueCounts.Values.FieldValues do
  @moduledoc false

  def values(%{} = source, field) do
    case Map.get(source, field) do
      values when is_list(values) -> values
      value when value in [nil, ""] -> []
      value -> [value]
    end
  end

  def values(_source, _field), do: []
end
