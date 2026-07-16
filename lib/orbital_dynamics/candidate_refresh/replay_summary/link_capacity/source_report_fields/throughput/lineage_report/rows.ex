defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport.Rows.ContactLineage
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  def count_map_or_summary(report, summary_field, row_fun) do
    if link_capacity_summary_source?(report) do
      report
      |> Map.get(summary_field)
      |> List.wrap()
      |> Counts.normalized_values()
    else
      row_fun.(report)
    end
  end

  def string_list_or_summary(report, summary_field, row_fun) do
    if link_capacity_summary_source?(report) do
      explicit_string_list(report, summary_field)
    else
      row_fun.(report)
    end
  end

  def rows_for_summary(%{"rows" => rows}) when is_list(rows),
    do: Enum.map(rows, &stringify_keys/1)

  def rows_for_summary(%{} = report), do: [stringify_keys(report)]

  defdelegate row_contact_ids(row, fields), to: ContactLineage
  defdelegate row_source_window_ids(row, fields), to: ContactLineage
  defdelegate row_station_calendar_entry_ids(row, fields), to: ContactLineage
  defdelegate row_station_calendar_provider_entry_ids(row, fields), to: ContactLineage

  def explicit_string_list(report, field) do
    report
    |> stringify_keys()
    |> Map.get(field)
    |> List.wrap()
    |> sorted_non_empty_values()
  end

  def sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp link_capacity_summary_source?(%{} = report) do
    Map.get(report, "source_summary_schema_contract") == "link_capacity_summary.v1" or
      Map.get(report, "schema_contract") == "link_capacity_summary.v1"
  end

  defp link_capacity_summary_source?(_report), do: false

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
