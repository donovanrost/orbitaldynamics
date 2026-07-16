defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.ValueCounts.EncodedCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_values(values) do
    values
    |> Enum.map(&EncodedValue.value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.reduce(%{}, fn value, counts -> Map.update(counts, value, 1, &(&1 + 1)) end)
  end
end
