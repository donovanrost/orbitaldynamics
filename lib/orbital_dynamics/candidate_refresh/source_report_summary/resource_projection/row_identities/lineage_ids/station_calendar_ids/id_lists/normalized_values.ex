defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.StationCalendarIds.IdLists.NormalizedValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def ids(values) do
    values
    |> List.flatten()
    |> sorted_string_values()
  end
end
