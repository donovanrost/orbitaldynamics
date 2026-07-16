defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.Report.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.Report.Rows.Identity

  def count_or_row_count(report, summary_field, row_counter) do
    if link_capacity_summary_source?(report) do
      summary_count_value(report, summary_field)
    else
      row_counter.(report)
    end
  end

  def numeric_map_or_summary(report, summary_field, row_field) do
    if link_capacity_summary_source?(report) do
      report |> Map.get(summary_field) |> normalize_numeric_map()
    else
      row_numeric_values_by_ground_station(report, row_field)
    end
  end

  def explicit_count_map(report, field) do
    report
    |> stringify_keys()
    |> Map.get(field)
    |> case do
      %{} = value -> value
      _value -> nil
    end
  end

  def rows_for_summary(%{"rows" => rows}) when is_list(rows),
    do: Enum.map(rows, &stringify_keys/1)

  def rows_for_summary(%{} = report), do: [stringify_keys(report)]

  def link_capacity_summary_source?(%{} = report) do
    Map.get(report, "source_summary_schema_contract") == "link_capacity_summary.v1" or
      Map.get(report, "schema_contract") == "link_capacity_summary.v1"
  end

  def link_capacity_summary_source?(_report), do: false

  def relay_data_path_summary_source?(%{} = report) do
    Map.get(report, "source_summary_schema_contract") == "relay_data_path_summary.v1" or
      Map.get(report, "schema_contract") == "relay_data_path_summary.v1"
  end

  def relay_data_path_summary_source?(_report), do: false

  defdelegate station_id(row), to: Identity
  defdelegate spacecraft_id(row), to: Identity

  def summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  def numeric_value(value), do: ValueEncoding.numeric_value(value)

  def positive_number_value?(value), do: is_number(value) and value > 0.0

  defp summary_count_value(report, field) do
    case Map.get(report, field) do
      values when is_list(values) -> length(values)
      %{} = values -> map_size(values)
      value -> summary_integer(%{"value" => value}, "value")
    end
  end

  defp row_numeric_values_by_ground_station(report, field) do
    report
    |> rows_for_summary()
    |> Enum.reduce(%{}, fn row, totals ->
      station_id = station_id(row)
      value = row |> Map.get(field) |> numeric_value()

      if station_id in [nil, ""] or is_nil(value) do
        totals
      else
        Map.update(totals, station_id, value, &(&1 + value))
      end
    end)
    |> non_empty_map()
  end

  defp normalize_numeric_map(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case numeric_value(value) do
        value when is_number(value) -> Map.put(acc, to_string(key), value)
        _value -> acc
      end
    end)
    |> non_empty_map()
  end

  defp normalize_numeric_map(_value), do: nil

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

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
