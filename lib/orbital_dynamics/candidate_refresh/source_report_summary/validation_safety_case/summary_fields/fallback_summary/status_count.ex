defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary.StatusCount do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary.IntegerValue

  def count(summary, status, fallback_field) do
    cond do
      is_map(Map.get(summary, "evidence_status_counts")) ->
        summary
        |> Map.get("evidence_status_counts")
        |> IntegerValue.from_field(status)

      is_map(Map.get(summary, "evidence_refs_by_status")) ->
        summary
        |> Map.get("evidence_refs_by_status")
        |> Map.get(status, [])
        |> list_value()
        |> length()

      true ->
        IntegerValue.from_field(summary, fallback_field)
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
