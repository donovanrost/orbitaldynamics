defmodule OrbitalDynamics.CampaignPlanner.SourceReportArtifacts do
  @moduledoc false

  def direct_entries(artifacts, source_path, opts) when is_list(opts) do
    opts
    |> Keyword.fetch!(:source_artifact_entries)
    |> then(& &1.(artifacts, source_path))
  end

  def source_artifacts(container, fields, opts, stringify_keys) when is_list(opts) do
    container = stringify_keys.(container || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      direct_entries(Map.get(container, field), source_path, opts)
    end)
  end

  def direct_reports(container, fields, stringify_keys) do
    fields
    |> Enum.flat_map(fn {field, source_path} ->
      case Map.get(container, field) do
        %{} = report -> [{stringify_keys.(report), source_path}]
        _report -> []
      end
    end)
  end

  def source_reports(container, fields, opts, stringify_keys) when is_list(opts) do
    source_report_entries = Keyword.fetch!(opts, :source_report_entries)
    container = stringify_keys.(container || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      source_report_entries.(Map.get(container, field), source_path)
    end)
  end

  def embedded_reports(container, report_keys, opts) when is_list(opts) do
    opts
    |> Keyword.fetch!(:result_artifact_embedded_reports)
    |> then(& &1.(container, report_keys))
  end

  def source_reports_with_embedded_reports(
        container,
        {field, source_path},
        report_keys,
        opts,
        stringify_keys
      )
      when is_list(opts) and is_function(stringify_keys, 1) do
    container = stringify_keys.(container || %{})

    source_reports(container, [{field, source_path}], opts, stringify_keys) ++
      embedded_reports(container, report_keys, opts)
  end

  def source_reports_with_embedded_fallback(
        container,
        direct_source_fun,
        report_keys,
        opts,
        stringify_keys
      )
      when is_list(opts) and is_function(direct_source_fun, 1) and
             is_function(stringify_keys, 1) do
    case direct_source_fun.(container) do
      [] ->
        container
        |> stringify_keys.()
        |> embedded_reports(report_keys, opts)

      reports ->
        reports
    end
  end

  def inherited_result_artifact_reports(container, report_keys, opts, stringify_keys)
      when is_list(opts) do
    callbacks = inherited_result_artifact_callbacks!(opts)

    container
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      artifact = stringify_keys.(artifact || %{})

      report_keys
      |> List.wrap()
      |> Enum.flat_map(fn report_key ->
        case Map.get(artifact, report_key) do
          %{} = report ->
            report =
              report
              |> stringify_keys.()
              |> callbacks.put_inherited_result_artifact_trust_boundary.(artifact)

            [{report, "#{source_path}.#{report_key}"}]

          _report ->
            []
        end
      end)
    end)
  end

  def inherited_result_artifact_entries(container, opts, stringify_keys, entries_with_source)
      when is_list(opts) and is_function(entries_with_source, 2) do
    callbacks = inherited_result_artifact_callbacks!(opts)

    container
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      artifact = stringify_keys.(artifact || %{})

      entries_with_source.(artifact, source_path)
      |> Enum.map(fn {entry, entry_source_path} ->
        entry =
          entry
          |> callbacks.put_inherited_result_artifact_trust_boundary.(artifact)

        {entry, entry_source_path}
      end)
    end)
  end

  def result_artifact_embedded_entries(artifacts_with_sources, report_keys, opts)
      when is_list(artifacts_with_sources) and is_list(report_keys) and is_list(opts) do
    result_artifact_embedded_report_entries =
      Keyword.fetch!(opts, :result_artifact_embedded_report_entries)

    artifacts_with_sources
    |> Enum.flat_map(fn {artifact, source_path} ->
      report_keys
      |> Enum.flat_map(fn report_key ->
        result_artifact_embedded_report_entries.(
          Map.get(artifact, report_key),
          artifact,
          "#{source_path}.#{report_key}"
        )
      end)
    end)
  end

  defp inherited_result_artifact_callbacks!(opts) do
    %{
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary)
    }
  end
end
