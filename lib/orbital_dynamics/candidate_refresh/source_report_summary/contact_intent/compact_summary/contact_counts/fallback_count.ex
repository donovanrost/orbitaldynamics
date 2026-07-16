defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.FallbackCount do
  @moduledoc false

  def value(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        parse(value)

      _value ->
        0
    end
  end

  defp parse(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> integer
      _parse -> 0
    end
  end
end
