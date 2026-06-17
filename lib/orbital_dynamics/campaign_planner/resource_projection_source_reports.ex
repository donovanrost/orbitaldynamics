defmodule OrbitalDynamics.CampaignPlanner.ResourceProjectionSourceReports do
  @moduledoc false

  @report_fields [
    {"source_resource_projection_report", "mission_state.source_resource_projection_report"},
    {"resource_projection_report", "mission_state.resource_projection_report"}
  ]

  @prior_report_fields [
    {"source_resource_projection_report", "prior_plan.source_resource_projection_report"},
    {"resource_projection_report", "prior_plan.resource_projection_report"}
  ]

  def reports(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    direct_reports(mission_state, opts, @report_fields) ++
      result_artifact_reports(mission_state, "source_resource_projection_report", opts) ++
      result_artifact_reports(mission_state, "resource_projection_report", opts)
  end

  def reports(mission_state, "source_resource_projection_report", opts) do
    direct_reports(mission_state, opts, [
      {"source_resource_projection_report", "mission_state.source_resource_projection_report"}
    ])
  end

  def reports(mission_state, "resource_projection_report", opts) do
    direct_reports(mission_state, opts, [
      {"resource_projection_report", "mission_state.resource_projection_report"}
    ])
  end

  def prior_plan_reports(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_reports =
      @prior_report_fields
      |> Enum.flat_map(fn {field, source_path} ->
        case Map.get(prior_plan, field) do
          %{} = report -> [{stringify_keys(report), source_path}]
          _report -> []
        end
      end)

    direct_reports ++ prior_plan_result_artifact_reports(prior_plan, opts)
  end

  defp direct_reports(mission_state, opts, fields) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp result_artifact_reports(mission_state, report_key, opts) do
    callbacks = callbacks!(opts)

    mission_state
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      artifact = stringify_keys(artifact || %{})

      case Map.get(artifact, report_key) do
        %{} = report ->
          report =
            report
            |> stringify_keys()
            |> callbacks.put_inherited_result_artifact_trust_boundary.(artifact)

          [{report, "#{source_path}.#{report_key}"}]

        _report ->
          []
      end
    end)
  end

  defp prior_plan_result_artifact_reports(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)
    report_keys = Enum.map(@report_fields, &elem(&1, 0))
    callbacks.result_artifact_embedded_reports.(prior_plan, report_keys)
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary)
    }
  end

  defp prior_plan_callbacks!(opts) do
    %{
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

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
