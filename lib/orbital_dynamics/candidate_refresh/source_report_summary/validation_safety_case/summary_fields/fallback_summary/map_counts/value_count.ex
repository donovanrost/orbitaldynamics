defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary.MapCounts.ValueCount do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary

  def from_map("evidence_status_counts", counts) do
    counts
    |> Map.values()
    |> Enum.map(&FallbackSummary.integer(%{"count" => &1}, "count"))
    |> Enum.sum()
  end

  def from_map("input_contract_counts", counts) do
    from_map("evidence_status_counts", counts)
  end

  def from_map(_field, refs_by_key) do
    refs_by_key
    |> Enum.flat_map(fn {_key, refs} -> list_value(refs) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
