defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary do
  @moduledoc false

  alias __MODULE__.BaseFields

  def source_reports(refresh_or_artifact, callbacks) when is_map(refresh_or_artifact) do
    source_report_input_provenance = Keyword.fetch!(callbacks, :source_report_input_provenance)

    source_reports_from_artifact(refresh_or_artifact, source_report_input_provenance)
  end

  def branch_family(refresh_or_artifact, family, callbacks) when is_map(refresh_or_artifact) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    refresh_or_artifact = stringify_keys.(refresh_or_artifact)

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
       branch_input_family(refresh_or_artifact, family, callbacks))
    |> non_empty_map()
  end

  def branch_family(_refresh_or_artifact, _family, _callbacks), do: nil

  def base_fields(source_reports) when is_map(source_reports) do
    BaseFields.fields(source_reports)
  end

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

  defp branch_input_family(
         %{"candidate_source" => %{} = candidate_source},
         "contact_intent",
         callbacks
       ) do
    source_report_input_provenance = Keyword.fetch!(callbacks, :source_report_input_provenance)

    case source_report_input_provenance.(candidate_source) do
      %{} = source_reports ->
        source_reports
        |> Map.get("contact_intent")
        |> relabel_branch_paths()

      _source_reports ->
        nil
    end
  end

  defp branch_input_family(_refresh_or_artifact, _family, _callbacks), do: nil

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
end
