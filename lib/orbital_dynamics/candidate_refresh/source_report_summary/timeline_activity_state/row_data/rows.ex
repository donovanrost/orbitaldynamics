defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def for_summary(%{"rows" => rows} = state) when is_list(rows) do
    rows
    |> Enum.map(&EncodedValue.stringify_keys/1)
    |> Enum.filter(&is_map/1)
    |> case do
      [] -> [Map.delete(state, "rows")]
      row_maps -> row_maps
    end
  end

  def for_summary(%{} = state), do: [EncodedValue.stringify_keys(state)]
  def for_summary(_state), do: []
end
