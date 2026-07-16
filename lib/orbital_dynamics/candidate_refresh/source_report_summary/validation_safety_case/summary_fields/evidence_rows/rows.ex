defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceRows.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def evidence_rows(report) do
    report
    |> Map.get("evidence", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def evidence_status(row) do
    Map.get(row, "status") || Map.get(row, "evidence_status")
  end

  def evidence_contract(row) do
    Map.get(row, "schema_contract") || Map.get(row, "input_contract")
  end

  def evidence_ref(row) do
    Map.get(row, "evidence_ref") || Map.get(row, "ref")
  end

  def ref_group_value(row, "schema_contract"), do: evidence_contract(row)
  def ref_group_value(row, field), do: Map.get(row, field)
end
