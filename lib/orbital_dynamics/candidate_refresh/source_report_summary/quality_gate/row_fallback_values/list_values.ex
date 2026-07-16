defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.ListValues do
  @moduledoc false

  def list(report, field) do
    report
    |> Map.get(field)
    |> normalize()
  end

  defp normalize(values) when is_list(values), do: values
  defp normalize(_values), do: []
end
