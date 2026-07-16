defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessSummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessSummaryEncoding

  @summary_sources [
    {"artifact_only_import_eligibility_summary", "operational_import_eligibility_summary.v1"},
    {"artifact_only_operational_readiness_gate_summary", "operational_readiness_gate_summary.v1"},
    {"artifact_only_operational_execution_boundary_summary",
     "operational_execution_boundary_summary.v1"}
  ]

  @summary_contracts Enum.map(@summary_sources, fn {_model, contract} -> contract end)

  def summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    gate_count = Map.get(summary, "gate_count") || Map.get(summary, :gate_count)

    (is_integer(gate_count) or is_float(gate_count)) and
      Enum.any?(@summary_sources, fn {expected_model, expected_contract} ->
        model == expected_model or schema_contract == expected_contract
      end)
  end

  def summary?(_summary), do: false

  def summary_contract?(contract), do: contract in @summary_contracts

  def report_from_summary(%{} = summary) do
    summary = stringify_keys(summary)

    summary
    |> Map.put("source_summary_schema_contract", Map.get(summary, "schema_contract"))
    |> Map.put("source_summary_model", Map.get(summary, "model"))
    |> Map.put("source_artifact_type", Map.get(summary, "source_artifact_type"))
  end

  defp stringify_keys(value), do: OperationalReadinessSummaryEncoding.stringify_keys(value)
end
