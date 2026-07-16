defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps.PairMaps.PairValues.ValueLists do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def sorted_non_empty(values) do
    case sorted_string_values(values) do
      [] -> nil
      values -> values
    end
  end
end
