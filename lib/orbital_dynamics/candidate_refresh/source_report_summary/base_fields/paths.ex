defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.BaseFields.Paths do
  @moduledoc false

  def fields(source_reports) when is_map(source_reports) do
    %{
      "source_report_paths" => paths(source_reports),
      "source_report_paths_by_family" => paths_by_family(source_reports),
      "source_report_paths_by_contract" => paths_by_value(source_reports, "contract"),
      "source_report_paths_by_trust_boundary_status" =>
        paths_by_value(source_reports, "trust_boundary_status")
    }
  end

  defp paths(source_reports) do
    source_reports
    |> Enum.flat_map(fn {_family, source_report} -> source_report_paths(source_report) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp paths_by_family(source_reports) do
    source_reports
    |> Enum.map(fn {family, source_report} ->
      {family, source_report_paths(source_report)}
    end)
    |> Enum.reject(fn {_family, paths} -> paths == [] end)
    |> Map.new()
    |> non_empty_map()
  end

  defp paths_by_value(source_reports, field) do
    source_reports
    |> Enum.reduce(%{}, fn {_family, source_report}, grouped_paths ->
      source_report
      |> Map.get(field)
      |> case do
        value when not is_binary(value) or value == "" ->
          grouped_paths

        value ->
          Map.update(grouped_paths, value, source_report_paths(source_report), fn paths ->
            (paths ++ source_report_paths(source_report))
            |> Enum.uniq()
            |> Enum.sort()
          end)
      end
    end)
    |> non_empty_map()
  end

  defp source_report_paths(%{"paths" => paths}) when is_list(paths) do
    paths
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_report_paths(%{"path" => path}) when is_binary(path), do: [path]
  defp source_report_paths(_source_report), do: []

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
