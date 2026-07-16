defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.SummaryValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  alias __MODULE__.ValueEncoding

  def string_list_map_or_summary(report, summary_field, row_fun) do
    if link_capacity_summary_source?(report) do
      explicit_string_list_map(report, summary_field)
    else
      row_fun.(report)
    end
  end

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

  defp link_capacity_summary_source?(%{} = report) do
    Map.get(report, "source_summary_schema_contract") == "link_capacity_summary.v1" or
      Map.get(report, "schema_contract") == "link_capacity_summary.v1"
  end

  defp link_capacity_summary_source?(_report), do: false

  defp stringify_keys(value), do: ValueEncoding.stringify_keys(value)
end
