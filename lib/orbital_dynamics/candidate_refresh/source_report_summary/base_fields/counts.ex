defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.BaseFields.Counts do
  @moduledoc false

  def fields(source_reports) when is_map(source_reports) do
    %{
      "source_report_count" => summary_count(source_reports, "count"),
      "source_report_row_count" => summary_count(source_reports, "row_count"),
      "source_report_counts_by_family" => counts_by_family(source_reports, "count"),
      "source_report_row_counts_by_family" => counts_by_family(source_reports, "row_count"),
      "source_report_counts_by_contract" => counts_by_value(source_reports, "contract", "count"),
      "source_report_row_counts_by_contract" =>
        counts_by_value(source_reports, "contract", "row_count"),
      "source_report_counts_by_trust_boundary_status" =>
        counts_by_value(source_reports, "trust_boundary_status", "count"),
      "source_report_row_counts_by_trust_boundary_status" =>
        counts_by_value(source_reports, "trust_boundary_status", "row_count"),
      "source_report_contracts" => values(source_reports, "contract"),
      "trust_boundary_status_counts" => count_values(source_reports, "trust_boundary_status")
    }
  end

  defp summary_count(source_reports, field) do
    source_reports
    |> Map.values()
    |> Enum.map(&numeric_report_count(&1, field))
    |> Enum.sum()
    |> report_count()
  end

  defp counts_by_family(source_reports, field) do
    source_reports
    |> Enum.map(fn {family, source_report} ->
      {family, count_by_family(source_report, field)}
    end)
    |> Enum.reject(fn {_family, count} -> is_nil(count) end)
    |> Map.new()
    |> non_empty_map()
  end

  defp count_by_family(source_report, field) when is_map(source_report) do
    if is_nil(Map.get(source_report, field)) do
      nil
    else
      source_report |> numeric_report_count(field) |> report_count()
    end
  end

  defp count_by_family(_source_report, _field), do: nil

  defp counts_by_value(source_reports, group_field, count_field) do
    source_reports
    |> Enum.reduce(%{}, fn {_family, source_report}, counts ->
      value = Map.get(source_report, group_field)
      count = count_by_family(source_report, count_field)

      if is_binary(value) and value != "" and not is_nil(count) do
        Map.update(counts, value, count, &(&1 + count))
      else
        counts
      end
    end)
    |> Enum.map(fn {value, count} -> {value, report_count(count)} end)
    |> Map.new()
    |> non_empty_map()
  end

  defp values(source_reports, field) do
    source_reports
    |> Map.values()
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp count_values(source_reports, field) do
    source_reports
    |> Map.values()
    |> Enum.map(fn source_report -> Map.get(source_report, field) end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.reduce(%{}, fn value, counts ->
      Map.update(counts, value, 1, &(&1 + 1))
    end)
    |> non_empty_map()
  end

  defp numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  defp report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
