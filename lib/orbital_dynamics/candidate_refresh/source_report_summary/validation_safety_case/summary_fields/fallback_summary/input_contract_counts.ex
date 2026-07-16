defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary.InputContractCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def counts(report) do
    case Map.get(report, "input_contract_counts") do
      %{} = counts ->
        counts

      _counts ->
        report
        |> Map.get("input_contracts")
        |> list_value()
        |> count_source_report_values()
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
