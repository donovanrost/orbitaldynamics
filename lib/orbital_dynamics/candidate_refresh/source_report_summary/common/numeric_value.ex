defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue do
  @moduledoc false

  def value(value) when is_number(value), do: value * 1.0

  def value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  def value(_value), do: nil
end
