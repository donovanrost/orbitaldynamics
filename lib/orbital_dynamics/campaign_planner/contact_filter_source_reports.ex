defmodule OrbitalDynamics.CampaignPlanner.ContactFilterSourceReports do
  @moduledoc false

  @report_fields [
    {"source_contact_filter_report", "mission_state.source_contact_filter_report"},
    {"contact_filter_report", "mission_state.contact_filter_report"}
  ]

  @prior_report_fields [
    {"source_contact_filter_report", "prior_plan.source_contact_filter_report"},
    {"contact_filter_report", "prior_plan.contact_filter_report"}
  ]

  def reports(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(mission_state, @report_fields, opts) ++
      result_artifact_embedded_reports(mission_state, "source_contact_filter_report", opts) ++
      result_artifact_embedded_reports(mission_state, "contact_filter_report", opts)
  end

  def reports(mission_state, "source_contact_filter_report", opts) do
    source_reports(
      mission_state,
      [
        {"source_contact_filter_report", "mission_state.source_contact_filter_report"}
      ],
      opts
    )
  end

  def reports(mission_state, "contact_filter_report", opts) do
    source_reports(
      mission_state,
      [
        {"contact_filter_report", "mission_state.contact_filter_report"}
      ],
      opts
    )
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

  defp source_reports(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(mission_state, report_key)
  end

  defp prior_plan_result_artifact_reports(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)
    report_keys = Enum.map(@report_fields, &elem(&1, 0))
    callbacks.result_artifact_embedded_reports.(prior_plan, report_keys)
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
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
