defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StationReservationEvidence.RowContexts.SourceReportKeys do
  @moduledoc false

  def stringify(%_struct{} = struct),
    do: struct |> Map.from_struct() |> stringify()

  def stringify(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify(value)} end)
  end

  def stringify(values) when is_list(values) do
    Enum.map(values, &stringify/1)
  end

  def stringify(value), do: value
end
