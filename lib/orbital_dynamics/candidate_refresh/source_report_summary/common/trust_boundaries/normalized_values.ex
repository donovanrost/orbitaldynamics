defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.TrustBoundaries.NormalizedValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from(values) do
    values
    |> Enum.map(&EncodedValue.value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
