defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts.FallbackCounts do
  @moduledoc false

  def integer(%{} = summary, field) do
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

  def validation_level_counts(%{} = summary) do
    case Map.get(summary, "validation_level_counts") do
      %{} = counts -> counts
      _counts -> %{}
    end
  end
end
