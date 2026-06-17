defmodule OrbitalDynamics.CampaignPlanner.ContactContentionSourceReports do
  @moduledoc false

  @contention_report_paths %{
    "source_contact_contention_report" => "mission_state.source_contact_contention_report",
    "contact_contention_report" => "mission_state.contact_contention_report"
  }

  @contention_report_fields [
    {"source_contact_contention_report", "mission_state.source_contact_contention_report"},
    {"contact_contention_report", "mission_state.contact_contention_report"}
  ]

  @resolution_report_paths %{
    "source_contact_contention_resolution_report" =>
      "mission_state.source_contact_contention_resolution_report",
    "contact_contention_resolution_report" => "mission_state.contact_contention_resolution_report"
  }

  @resolution_report_fields [
    {"source_contact_contention_resolution_report",
     "mission_state.source_contact_contention_resolution_report"},
    {"contact_contention_resolution_report", "mission_state.contact_contention_resolution_report"}
  ]

  @prior_resolution_report_fields [
    {"source_contact_contention_resolution_report",
     "prior_plan.source_contact_contention_resolution_report"},
    {"contact_contention_resolution_report", "prior_plan.contact_contention_resolution_report"}
  ]

  @resolution_summary_paths %{
    "source_contact_contention_resolution_summary" =>
      "mission_state.source_contact_contention_resolution_summary",
    "contact_contention_resolution_summary" =>
      "mission_state.contact_contention_resolution_summary"
  }

  def contention_reports(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(mission_state, @contention_report_fields, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        Enum.map(@contention_report_fields, &elem(&1, 0)),
        opts
      )
  end

  def resolution_reports(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(mission_state, @resolution_report_fields, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        Enum.map(@resolution_report_fields, &elem(&1, 0)),
        opts
      )
  end

  def prior_resolution_reports(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_reports =
      @prior_resolution_report_fields
      |> Enum.flat_map(fn {field, source_path} ->
        case Map.get(prior_plan, field) do
          %{} = report -> [{stringify_keys(report), source_path}]
          _report -> []
        end
      end)

    direct_reports ++ prior_plan_result_artifact_resolution_reports(prior_plan, opts)
  end

  def reports(mission_state, report_key, opts) do
    paths = Map.merge(@contention_report_paths, @resolution_report_paths)

    case Map.fetch(paths, report_key) do
      {:ok, source_path} -> source_reports(mission_state, [{report_key, source_path}], opts)
      :error -> []
    end
  end

  def summaries(mission_state, summary_key, opts) do
    case Map.fetch(@resolution_summary_paths, summary_key) do
      {:ok, source_path} -> source_reports(mission_state, [{summary_key, source_path}], opts)
      :error -> []
    end
  end

  defp source_reports(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp result_artifact_embedded_reports(mission_state, report_keys, opts) do
    callbacks = callbacks!(opts)

    Enum.flat_map(report_keys, fn report_key ->
      callbacks.result_artifact_embedded_reports.(mission_state, report_key)
    end)
  end

  defp prior_plan_result_artifact_resolution_reports(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)
    report_keys = Enum.map(@resolution_report_fields, &elem(&1, 0))
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
