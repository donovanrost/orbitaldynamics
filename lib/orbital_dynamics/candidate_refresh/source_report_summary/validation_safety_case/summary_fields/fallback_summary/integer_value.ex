defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary.IntegerValue do
  @moduledoc false

  def from_field(%{} = summary, field) do
    summary
    |> Map.get(field)
    |> from_value()
  end

  defp from_value(value) when is_integer(value), do: value
  defp from_value(value) when is_float(value), do: trunc(value)

  defp from_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {count, ""} -> count
      _error -> 0
    end
  end

  defp from_value(_value), do: 0
end
