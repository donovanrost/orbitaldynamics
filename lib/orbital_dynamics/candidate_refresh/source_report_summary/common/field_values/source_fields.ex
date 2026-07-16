defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.FieldValues.SourceFields do
  @moduledoc false

  def values(source, field) do
    case Map.get(source, field) do
      values when is_list(values) -> values
      value when value in [nil, ""] -> []
      value -> [value]
    end
  end
end
