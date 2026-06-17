defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.SourceReportFields.Flattened.EvidenceCount do
  @moduledoc false

  def source_report_evidence_count(source_reports) do
    case Map.get(source_reports, "validation_safety_case_summary") do
      %{} = summary ->
        if has_evidence_count_source?(summary) do
          evidence_count(summary, "row_count")
        end

      _summary ->
        nil
    end
  end

  def source_report_evidence_status_count(source_reports, status, fallback_field) do
    case Map.get(source_reports, "validation_safety_case_summary") do
      %{} = summary ->
        if has_evidence_status_count_source?(summary, fallback_field) do
          evidence_status_count(summary, status, fallback_field)
        end

      _summary ->
        nil
    end
  end

  defp evidence_count(summary, fallback_field) do
    case evidence_map_count(summary) do
      {:ok, count} -> count
      :error -> summary_integer(summary, fallback_field)
    end
  end

  defp evidence_status_count(summary, status, fallback_field) do
    cond do
      is_map(Map.get(summary, "evidence_status_counts")) ->
        summary
        |> Map.get("evidence_status_counts")
        |> summary_integer(status)

      is_map(Map.get(summary, "evidence_refs_by_status")) ->
        summary
        |> Map.get("evidence_refs_by_status")
        |> Map.get(status, [])
        |> list_value()
        |> length()

      true ->
        summary_integer(summary, fallback_field)
    end
  end

  defp evidence_map_count(summary) do
    [
      "evidence_status_counts",
      "evidence_refs_by_status",
      "evidence_refs_by_contract",
      "input_contract_counts"
    ]
    |> Enum.find_value(:error, fn field ->
      case Map.get(summary, field) do
        %{} = map -> {:ok, map_count(field, map)}
        _map -> false
      end
    end)
  end

  defp map_count("evidence_status_counts", counts) do
    counts
    |> Map.values()
    |> Enum.map(&summary_integer(%{"count" => &1}, "count"))
    |> Enum.sum()
  end

  defp map_count("input_contract_counts", counts) do
    map_count("evidence_status_counts", counts)
  end

  defp map_count(_field, refs_by_key) do
    refs_by_key
    |> Enum.flat_map(fn {_key, refs} -> list_value(refs) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp has_evidence_count_source?(summary) do
    Enum.any?(
      [
        "row_count",
        "evidence_count",
        "evidence_status_counts",
        "evidence_refs_by_status",
        "evidence_refs_by_contract",
        "input_contract_counts"
      ],
      &Map.has_key?(summary, &1)
    )
  end

  defp has_evidence_status_count_source?(summary, fallback_field) do
    Enum.any?(
      [
        fallback_field,
        "evidence_status_counts",
        "evidence_refs_by_status"
      ],
      &Map.has_key?(summary, &1)
    )
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

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
