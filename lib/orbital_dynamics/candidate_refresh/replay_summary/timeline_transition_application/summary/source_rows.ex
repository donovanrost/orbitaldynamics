defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.Summary.SourceRows do
  @moduledoc false

  def source_row_count(report) do
    cond do
      summary_source?(report) ->
        first_numeric_report_count(report, [
          "source_report_row_count",
          "row_count",
          "application_count"
        ])

      true ->
        case Map.get(report, "applications", []) do
          rows when is_list(rows) and rows != [] ->
            length(rows)

          _rows ->
            first_numeric_report_count(report, [
              "row_count",
              "application_count"
            ])
        end
    end
  end

  defp first_numeric_report_count(report, fields) do
    fields
    |> Enum.find_value(fn field ->
      case numeric_value(Map.get(report, field)) do
        value when is_number(value) -> report_count(value)
        _value -> nil
      end
    end)
    |> Kernel.||(0)
  end

  defp summary_source?(%{} = report) do
    (Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")) ==
      "timeline_transition_application_summary.v1"
  end

  defp summary_source?(_report), do: false

  defp report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _parse -> nil
    end
  end

  defp numeric_value(_value), do: nil
end
