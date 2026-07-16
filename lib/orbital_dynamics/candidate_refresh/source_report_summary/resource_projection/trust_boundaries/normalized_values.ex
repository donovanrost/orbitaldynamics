defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.NormalizedValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def sorted_unique(values) do
    values
    |> Enum.map(&EncodedValue.value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
