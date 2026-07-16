defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.FieldValues.CompactMaps do
  @moduledoc false

  def from(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
