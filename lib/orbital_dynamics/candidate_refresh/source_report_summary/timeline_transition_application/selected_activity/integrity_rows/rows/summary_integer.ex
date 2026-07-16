defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.IntegrityRows.Rows.SummaryInteger do
  @moduledoc false

  def value(summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        parse_integer(value)

      _value ->
        0
    end
  end

  defp parse_integer(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> integer
      _parse -> 0
    end
  end
end
