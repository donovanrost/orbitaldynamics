defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Relay.Rows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  alias __MODULE__.Normalization

  import Normalization,
    only: [normalized_token: 1, sorted_non_empty_values: 1, stringify_keys: 1]

  def row_ids(report, fields) do
    report
    |> rows_for_summary()
    |> Enum.flat_map(fn row ->
      fields
      |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
      |> List.flatten()
    end)
    |> sorted_non_empty_values()
  end

  def route_ids_by_field(report, field) do
    report
    |> rows_for_summary()
    |> Enum.flat_map(fn row ->
      status = normalized_token(Map.get(row, field))

      row
      |> Map.get("route_id")
      |> List.wrap()
      |> Enum.map(&{status, &1})
    end)
    |> grouped_source_report_ids()
  end

  def explicit_string_list_map(report, field) do
    report
    |> stringify_keys()
    |> Map.get(field)
    |> case do
      %{} = value -> merge_string_list_maps([value])
      _value -> nil
    end
  end

  def explicit_string_list(report, field) do
    report
    |> stringify_keys()
    |> Map.get(field)
    |> List.wrap()
    |> sorted_non_empty_values()
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

  def relay_data_path_summary_source?(%{} = report) do
    Map.get(report, "source_summary_schema_contract") == "relay_data_path_summary.v1" or
      Map.get(report, "schema_contract") == "relay_data_path_summary.v1"
  end

  def relay_data_path_summary_source?(_report), do: false

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

  def numeric_value(value), do: Normalization.numeric_value(value)

  defp grouped_source_report_ids(pairs) do
    pairs
    |> Enum.reject(fn {status, id} -> status in [nil, ""] or id in [nil, ""] end)
    |> Enum.reduce(%{}, fn {status, id}, acc ->
      Map.update(acc, status, [to_string(id)], fn ids ->
        [to_string(id) | ids]
        |> Enum.uniq()
        |> Enum.sort()
      end)
    end)
    |> case do
      map when map_size(map) == 0 -> nil
      map -> map
    end
  end
end
