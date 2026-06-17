defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary.SourceReports do
  @moduledoc false

  def fields(pressure_reports) do
    %{
      "source_report_count" => pressure_summary_integer_sum(pressure_reports, "count"),
      "source_report_row_count" => pressure_summary_integer_sum(pressure_reports, "row_count"),
      "source_report_families" =>
        pressure_summary_values(pressure_reports, fn {family, _summary} -> family end),
      "source_report_contracts" =>
        pressure_summary_values(pressure_reports, fn {_family, summary} ->
          Map.get(summary, "contract")
        end),
      "source_report_counts_by_family" => pressure_summary_counts_by_family(pressure_reports),
      "source_report_row_counts_by_family" =>
        pressure_summary_counts_by_family(pressure_reports, "row_count"),
      "source_report_paths" => pressure_summary_paths(pressure_reports),
      "source_report_paths_by_family" => pressure_summary_paths_by_family(pressure_reports),
      "source_report_counts_by_trust_boundary_status" =>
        pressure_summary_counts_by_trust_boundary_status(pressure_reports),
      "trust_boundaries" => pressure_summary_trust_boundaries(pressure_reports)
    }
  end

  defp pressure_summary_integer_sum(pressure_reports, field) do
    pressure_reports
    |> Map.values()
    |> Enum.map(&summary_integer(&1, field))
    |> Enum.sum()
  end

  defp pressure_summary_counts_by_family(pressure_reports, field \\ "count") do
    pressure_reports
    |> Map.new(fn {family, summary} -> {family, pressure_summary_count(summary, field)} end)
    |> Enum.reject(fn {_family, count} -> is_nil(count) end)
    |> Map.new()
  end

  defp pressure_summary_count(summary, field) when is_map(summary) do
    if is_nil(Map.get(summary, field)) do
      nil
    else
      summary_integer(summary, field)
    end
  end

  defp pressure_summary_count(_summary, _field), do: nil

  defp pressure_summary_counts_by_trust_boundary_status(pressure_reports) do
    pressure_reports
    |> Enum.reduce(%{}, fn {_family, summary}, acc ->
      status = Map.get(summary, "trust_boundary_status")
      count = pressure_summary_count(summary, "count")

      if is_binary(status) and status != "" and not is_nil(count) do
        Map.update(acc, status, count, &(&1 + count))
      else
        acc
      end
    end)
  end

  defp pressure_summary_paths(pressure_reports) do
    pressure_reports
    |> Map.values()
    |> Enum.flat_map(&(Map.get(&1, "paths", []) |> List.wrap()))
    |> pressure_string_values()
  end

  defp pressure_summary_paths_by_family(pressure_reports) do
    pressure_reports
    |> Map.new(fn {family, summary} ->
      {family, summary |> Map.get("paths", []) |> List.wrap() |> pressure_string_values()}
    end)
    |> Enum.reject(fn {_family, paths} -> paths == [] end)
    |> Map.new()
  end

  defp pressure_summary_trust_boundaries(pressure_reports) do
    pressure_reports
    |> Map.values()
    |> Enum.flat_map(&(Map.get(&1, "trust_boundaries", []) |> List.wrap()))
    |> pressure_string_values()
  end

  defp pressure_summary_values(pressure_reports, value_fun) do
    pressure_reports
    |> Enum.map(value_fun)
    |> pressure_string_values()
  end

  defp pressure_string_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp summary_integer(%{} = summary, field) do
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

  defp summary_integer(_summary, _field), do: 0
end
