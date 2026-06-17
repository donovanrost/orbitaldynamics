defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshSourceInputs do
  @moduledoc false

  def timeline_feedback_source_report(mission_state, opts) do
    mission_state
    |> direct_source_timeline_feedback_reports(opts)
    |> report_from_reports(opts)
    |> non_empty_report()
  end

  def timeline_feedback_report_input(mission_state, opts) do
    mission_state
    |> direct_canonical_timeline_feedback_reports(opts)
    |> report_from_reports(opts)
    |> non_empty_report()
  end

  def operational_timeline_source_report(mission_state, opts) do
    mission_state
    |> direct_source_operational_timeline_reports(opts)
    |> report_from_reports(opts)
    |> non_empty_report()
  end

  def operational_timeline_report_input(mission_state, opts) do
    mission_state
    |> direct_canonical_operational_timeline_reports(opts)
    |> report_from_reports(opts)
    |> non_empty_report()
  end

  def merge_reports(reports_with_sources, opts) do
    callbacks = callbacks!(opts)
    reports = Enum.map(reports_with_sources, fn {report, _source_path} -> report end)

    reports
    |> List.first(%{})
    |> Map.put("rows", Enum.flat_map(reports, &(Map.get(&1, "rows", []) || [])))
    |> Map.put(
      "row_count",
      Enum.sum(Enum.map(reports, callbacks.timeline_feedback_report_row_count))
    )
  end

  defp direct_source_timeline_feedback_reports(mission_state, opts) do
    direct_timeline_feedback_reports(
      mission_state,
      [{"source_timeline_feedback_report", "mission_state.source_timeline_feedback_report"}],
      opts
    )
  end

  defp direct_canonical_timeline_feedback_reports(mission_state, opts) do
    direct_timeline_feedback_reports(
      mission_state,
      [{"timeline_feedback_report", "mission_state.timeline_feedback_report"}],
      opts
    )
  end

  defp direct_timeline_feedback_reports(mission_state, fields, opts) do
    direct_reports(mission_state, fields, opts)
  end

  defp direct_source_operational_timeline_reports(mission_state, opts) do
    direct_operational_timeline_reports(
      mission_state,
      [
        {"source_operational_timeline_report", "mission_state.source_operational_timeline_report"}
      ],
      opts
    )
  end

  defp direct_canonical_operational_timeline_reports(mission_state, opts) do
    direct_operational_timeline_reports(
      mission_state,
      [{"operational_timeline_report", "mission_state.operational_timeline_report"}],
      opts
    )
  end

  defp direct_operational_timeline_reports(mission_state, fields, opts) do
    direct_reports(mission_state, fields, opts)
  end

  defp direct_reports(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp report_from_reports([{report, _source_path}], _opts), do: report

  defp report_from_reports(reports, opts) when is_list(reports) and reports != [],
    do: merge_reports(reports, opts)

  defp report_from_reports(_reports, _opts), do: %{}

  defp non_empty_report(%{} = report) when map_size(report) > 0, do: report
  defp non_empty_report(_report), do: nil

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      timeline_feedback_report_row_count:
        Keyword.fetch!(opts, :timeline_feedback_report_row_count)
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
