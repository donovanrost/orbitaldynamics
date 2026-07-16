defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.SummaryValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding, as: CandidateValueEncoding
  alias __MODULE__.ValueEncoding

  def rows_for_summary(%{"rows" => rows}) when is_list(rows),
    do: Enum.map(rows, &stringify_keys/1)

  def rows_for_summary(%{} = report), do: [stringify_keys(report)]

  def explicit_string_list_map(report, field) do
    report
    |> stringify_keys()
    |> Map.get(field)
    |> case do
      %{} = value -> merge_string_list_maps([value])
      _value -> nil
    end
  end

  def numeric_value(value), do: CandidateValueEncoding.numeric_value(value)

  defp stringify_keys(value), do: ValueEncoding.stringify_keys(value)
end
