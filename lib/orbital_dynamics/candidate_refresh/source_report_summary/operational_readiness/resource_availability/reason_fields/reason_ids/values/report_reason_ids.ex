defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.ReasonIds.Values.ReportReasonIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence

  def values(report, gate_reason_id_field) do
    gate_reason_ids(report, gate_reason_id_field) ++ evidence_reason_ids(report)
  end

  defp gate_reason_ids(report, gate_reason_id_field) do
    report
    |> Map.get("gates", [])
    |> Enum.flat_map(fn gate ->
      list_value(Map.get(gate, gate_reason_id_field)) ++
        Map.keys(Map.get(gate, "resource_availability_reason_counts") || %{})
    end)
  end

  defp evidence_reason_ids(report) do
    report
    |> Evidence.count_map("resource_availability_reason_counts")
    |> Map.keys()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
