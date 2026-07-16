defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def source_reports(refresh_or_artifact, source_report_input_provenance)
      when is_map(refresh_or_artifact) do
    source_reports_from_artifact(refresh_or_artifact, source_report_input_provenance)
  end

  def branch_family(refresh_or_artifact, family, source_report_input_provenance)
      when is_map(refresh_or_artifact) do
    refresh_or_artifact
    |> branch_family_lookup(family, source_report_input_provenance)
  end

  def branch_family(
        _refresh_or_artifact,
        _family,
        _source_report_input_provenance
      ),
      do: nil

  def base_fields(source_reports) when is_map(source_reports) do
    source_reports
    |> base_source_report_fields()
    |> Map.merge(count_fields(source_reports))
    |> Map.merge(path_fields(source_reports))
  end

  defp base_source_report_fields(source_reports) do
    %{
      "model" => "artifact_only_candidate_refresh_source_report_summary",
      "source" => "candidate_refresh.source_report_provenance",
      "source_report_family_count" => map_size(source_reports),
      "source_report_families" => source_reports |> Map.keys() |> Enum.sort(),
      "source_reports" => non_empty_map(source_reports),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "input_provenance_summary_only"
      }
    }
  end

  defp count_fields(source_reports) do
    %{
      "source_report_count" => summary_count(source_reports, "count"),
      "source_report_row_count" => summary_count(source_reports, "row_count"),
      "source_report_counts_by_family" => grouped_by_family(source_reports, "count"),
      "source_report_row_counts_by_family" => grouped_by_family(source_reports, "row_count"),
      "source_report_counts_by_contract" => grouped_by_value(source_reports, "contract", "count"),
      "source_report_row_counts_by_contract" =>
        grouped_by_value(source_reports, "contract", "row_count"),
      "source_report_counts_by_trust_boundary_status" =>
        grouped_by_value(source_reports, "trust_boundary_status", "count"),
      "source_report_row_counts_by_trust_boundary_status" =>
        grouped_by_value(source_reports, "trust_boundary_status", "row_count")
    }
    |> Map.merge(value_fields(source_reports))
  end

  defp summary_count(source_reports, field) do
    source_reports
    |> Map.values()
    |> Enum.map(&report_field(&1, field))
    |> Enum.sum()
    |> report_count()
  end

  defp value_fields(source_reports) do
    %{
      "source_report_contracts" => sorted_values(source_reports, "contract"),
      "trust_boundary_status_counts" => value_counts(source_reports, "trust_boundary_status")
    }
  end

  defp sorted_values(source_reports, field) do
    source_reports
    |> Map.values()
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&valid_value?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp value_counts(source_reports, field) do
    source_reports
    |> Map.values()
    |> Enum.map(fn source_report -> Map.get(source_report, field) end)
    |> Enum.filter(&valid_value?/1)
    |> Enum.reduce(%{}, fn value, counts ->
      Map.update(counts, value, 1, &(&1 + 1))
    end)
    |> non_empty_map()
  end

  defp valid_value?(value), do: is_binary(value) and value != ""

  defp grouped_by_family(source_reports, field) do
    source_reports
    |> Enum.map(fn {family, source_report} ->
      {family, count_by_family(source_report, field)}
    end)
    |> Enum.reject(fn {_family, count} -> is_nil(count) end)
    |> Map.new()
    |> non_empty_map()
  end

  defp grouped_by_value(source_reports, group_field, count_field) do
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

  defp count_by_family(source_report, field) when is_map(source_report) do
    if is_nil(Map.get(source_report, field)) do
      nil
    else
      source_report |> report_field(field) |> report_count()
    end
  end

  defp count_by_family(_source_report, _field), do: nil

  defp report_field(report, field), do: NumericValue.value(Map.get(report, field)) || 0

  defp report_count(value) do
    case NumericValue.value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  defp path_fields(source_reports) do
    %{
      "source_report_paths" => all_paths(source_reports),
      "source_report_paths_by_family" => paths_by_family(source_reports),
      "source_report_paths_by_contract" => paths_by_value(source_reports, "contract"),
      "source_report_paths_by_trust_boundary_status" =>
        paths_by_value(source_reports, "trust_boundary_status")
    }
  end

  defp all_paths(source_reports) do
    source_reports
    |> Enum.flat_map(fn {_family, source_report} -> paths_for_report(source_report) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp paths_by_family(source_reports) do
    source_reports
    |> Enum.map(fn {family, source_report} ->
      {family, paths_for_report(source_report)}
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
          report_paths = paths_for_report(source_report)

          Map.update(grouped_paths, value, report_paths, fn paths ->
            (paths ++ report_paths)
            |> Enum.uniq()
            |> Enum.sort()
          end)
      end
    end)
    |> non_empty_map()
  end

  defp paths_for_report(%{"paths" => paths}) when is_list(paths) do
    paths
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp paths_for_report(%{"path" => path}) when is_binary(path), do: [path]
  defp paths_for_report(_source_report), do: []

  defp branch_family_lookup(refresh_or_artifact, family, source_report_input_provenance) do
    refresh_or_artifact = EncodedValue.value_with_keyword_maps(refresh_or_artifact)

    (get_in(refresh_or_artifact, [
       "candidate_source",
       "candidate_refresh_request_source_report_summary",
       "source_reports",
       family
     ]) ||
       get_in(refresh_or_artifact, [
         "assumptions",
         "candidate_source",
         "candidate_refresh_request_source_report_summary",
         "source_reports",
         family
       ]) ||
       get_in(refresh_or_artifact, [
         "candidate_refresh_request_source_report_summary",
         "source_reports",
         family
       ]) ||
       branch_input_family(refresh_or_artifact, family, source_report_input_provenance))
    |> non_empty_map()
  end

  defp branch_input_family(
         %{"candidate_source" => %{} = candidate_source},
         "contact_intent",
         source_report_input_provenance
       ) do
    case source_report_input_provenance.(candidate_source) do
      %{} = source_reports ->
        source_reports
        |> Map.get("contact_intent")
        |> relabel_branch_paths()

      _source_reports ->
        nil
    end
  end

  defp branch_input_family(_refresh_or_artifact, _family, _source_report_input_provenance),
    do: nil

  defp relabel_branch_paths(%{} = summary) do
    Map.update(summary, "paths", [], fn paths ->
      paths
      |> List.wrap()
      |> Enum.map(&branch_path/1)
    end)
  end

  defp relabel_branch_paths(summary), do: summary

  defp branch_path(path) when is_binary(path) do
    if String.starts_with?(path, "candidate_source.") do
      path
    else
      "candidate_source.candidate_refresh_request.#{path}"
    end
  end

  defp branch_path(path), do: path

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp source_reports_from_artifact(
         %{"schema_contract" => "candidate_refresh.v1", "provenance" => %{} = provenance} =
           refresh,
         source_report_input_provenance
       ) do
    case Map.get(provenance, "source_reports") do
      %{} = source_reports -> source_reports
      _source_reports -> source_report_input_provenance.(refresh) || %{}
    end
  end

  defp source_reports_from_artifact(
         %{
           "candidate_refresh_request_source_report_summary" => %{
             "source_reports" => %{} = source_reports
           }
         },
         _source_report_input_provenance
       ) do
    source_reports
  end

  defp source_reports_from_artifact(
         %{"source_reports" => %{} = source_reports},
         _source_report_input_provenance
       ) do
    source_reports
  end

  defp source_reports_from_artifact(refresh, source_report_input_provenance) do
    source_report_input_provenance.(refresh) || %{}
  end
end
