defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps.ListMaps.StringListMaps.StringValues do
  @moduledoc false

  def from(values) do
    values
    |> list_values()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
  end

  defp list_values(values) when is_list(values), do: values
  defp list_values(_values), do: []
end
