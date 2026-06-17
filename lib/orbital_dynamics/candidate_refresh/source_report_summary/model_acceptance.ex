defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      count_source_report_values: 1,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1,
      sum_report_count: 2
    ]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "model_acceptance_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &model_acceptance_report_summary_row_count/1),
      "record_count" => sum_report_count(reports, &model_acceptance_report_record_count/1),
      "intended_use_counts" => count_report_field_values(reports, "intended_use"),
      "status_counts" => count_report_field_values(reports, "status"),
      "model_count" => sum_report_count(reports, &model_acceptance_report_model_count/1),
      "accepted_count" => sum_report_count(reports, &model_acceptance_report_accepted_count/1),
      "review_required_count" =>
        sum_report_count(reports, &model_acceptance_report_review_required_count/1),
      "blocked_count" => sum_report_count(reports, &model_acceptance_report_blocked_count/1),
      "unknown_model_count" =>
        sum_report_count(reports, &model_acceptance_report_unknown_model_count/1),
      "validation_level_counts" =>
        reports
        |> Enum.map(&model_acceptance_report_validation_level_counts/1)
        |> merge_count_maps(),
      "model_ids_by_status" =>
        reports
        |> Enum.map(&model_acceptance_report_model_id_map(&1, "model_ids_by_status"))
        |> merge_string_list_maps(),
      "model_ids_by_validation_level" =>
        reports
        |> Enum.map(&model_acceptance_report_model_id_map(&1, "model_ids_by_validation_level"))
        |> merge_string_list_maps(),
      "model_ids_by_intended_use" =>
        reports
        |> Enum.map(&model_acceptance_report_model_id_map(&1, "model_ids_by_intended_use"))
        |> merge_string_list_maps(),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
    |> compact_map()
  end

  defp model_acceptance_report_record_count(report), do: length(Map.get(report, "records", []))

  defp model_acceptance_report_summary_row_count(report) do
    case model_acceptance_report_rows(report) do
      [] -> model_acceptance_summary_count(report, "row_count")
      rows -> length(rows)
    end
  end

  defp model_acceptance_report_model_count(report) do
    case model_acceptance_report_rows(report) do
      [] -> model_acceptance_summary_count(report, "model_count")
      rows -> length(rows)
    end
  end

  defp model_acceptance_report_accepted_count(report),
    do: model_acceptance_report_status_count(report, "accepted")

  defp model_acceptance_report_review_required_count(report),
    do: model_acceptance_report_status_count(report, "review_required")

  defp model_acceptance_report_blocked_count(report),
    do: model_acceptance_report_status_count(report, "blocked")

  defp model_acceptance_report_unknown_model_count(report) do
    case model_acceptance_report_rows(report) do
      [] -> model_acceptance_summary_validation_level_count(report, "unknown")
      rows -> Enum.count(rows, &((Map.get(&1, "validation_level") || "unknown") == "unknown"))
    end
  end

  defp model_acceptance_report_status_count(report, status) do
    case model_acceptance_report_rows(report) do
      [] -> model_acceptance_summary_status_count(report, status)
      rows -> Enum.count(rows, &((Map.get(&1, "status") || "unknown") == status))
    end
  end

  defp model_acceptance_report_validation_level_counts(report) do
    case model_acceptance_report_rows(report) do
      [] ->
        model_acceptance_summary_validation_level_counts(report)

      rows ->
        rows
        |> Enum.map(&(Map.get(&1, "validation_level") || "unknown"))
        |> count_source_report_values()
    end
  end

  defp model_acceptance_report_model_id_map(report, "model_ids_by_status" = field) do
    model_acceptance_report_row_model_id_map(report, field, fn _report, row ->
      Map.get(row, "status") || "unknown"
    end)
  end

  defp model_acceptance_report_model_id_map(report, "model_ids_by_validation_level" = field) do
    model_acceptance_report_row_model_id_map(report, field, fn _report, row ->
      Map.get(row, "validation_level") || "unknown"
    end)
  end

  defp model_acceptance_report_model_id_map(report, "model_ids_by_intended_use" = field) do
    model_acceptance_report_row_model_id_map(report, field, fn report, _row ->
      Map.get(report, "intended_use") || "unknown"
    end)
  end

  defp model_acceptance_report_model_id_map(report, field) do
    model_acceptance_report_top_level_model_id_map(report, field)
  end

  defp model_acceptance_report_top_level_model_id_map(report, field) do
    case Map.get(report, field) do
      %{} = model_id_map -> model_id_map
      _model_id_map -> %{}
    end
  end

  defp model_acceptance_report_row_model_id_map(report, fallback_field, group_fun) do
    rows = model_acceptance_report_rows(report)

    if rows == [] do
      model_acceptance_report_top_level_model_id_map(report, fallback_field)
    else
      rows
      |> Enum.group_by(
        &to_string(group_fun.(report, &1)),
        &(Map.get(&1, "model_id") || Map.get(&1, "id"))
      )
      |> Map.new(fn {key, values} ->
        ids =
          values
          |> Enum.reject(&(&1 in [nil, ""]))
          |> Enum.map(&to_string/1)
          |> Enum.uniq()

        {key, ids}
      end)
      |> compact_map()
      |> case do
        nil -> %{}
        model_id_map -> model_id_map
      end
    end
  end

  defp model_acceptance_report_rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
  end

  defp model_acceptance_summary_count(summary, field) do
    case model_acceptance_summary_model_id_count(summary) do
      {:ok, count} -> count
      :error -> summary_integer(summary, field)
    end
  end

  defp model_acceptance_summary_status_count(summary, status) do
    case Map.get(summary, "model_ids_by_status") do
      %{} = model_ids_by_status ->
        model_ids_by_status
        |> Map.get(status, [])
        |> list_value()
        |> length()

      _model_ids_by_status ->
        summary_integer(summary, "#{status}_count")
    end
  end

  defp model_acceptance_summary_validation_level_count(summary, validation_level) do
    case Map.get(summary, "model_ids_by_validation_level") do
      %{} = model_ids_by_validation_level ->
        model_ids_by_validation_level
        |> Map.get(validation_level, [])
        |> list_value()
        |> length()

      _model_ids_by_validation_level ->
        summary_integer(summary, "unknown_model_count")
    end
  end

  defp model_acceptance_summary_validation_level_counts(summary) do
    case Map.get(summary, "model_ids_by_validation_level") do
      %{} = model_ids_by_validation_level ->
        model_acceptance_model_id_count_map(model_ids_by_validation_level)

      _model_ids_by_validation_level ->
        case Map.get(summary, "validation_level_counts") do
          %{} = counts -> counts
          _counts -> %{}
        end
    end
  end

  defp model_acceptance_summary_model_id_count(summary) do
    [
      "model_ids_by_status",
      "model_ids_by_validation_level",
      "model_ids_by_intended_use"
    ]
    |> Enum.find_value(:error, fn field ->
      case Map.get(summary, field) do
        %{} = model_id_map -> {:ok, model_acceptance_model_id_map_model_count(model_id_map)}
        _model_id_map -> false
      end
    end)
  end

  defp model_acceptance_model_id_count_map(model_id_map) do
    model_id_map
    |> Enum.map(fn {key, values} -> {to_string(key), values |> list_value() |> length()} end)
    |> Enum.reject(fn {_key, count} -> count == 0 end)
    |> Map.new()
  end

  defp model_acceptance_model_id_map_model_count(model_id_map) do
    model_id_map
    |> Enum.flat_map(fn {_key, values} -> list_value(values) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(value) do
          {count, ""} -> count
          _error -> 0
        end

      _value ->
        0
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
