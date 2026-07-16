defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.NonPassedRows.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def rows_with_status(report) do
    report
    |> Map.get("non_passed_gates", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(&row_with_status/1)
  end

  defp row_with_status(gate) do
    id = gate |> Map.get("id") |> EncodedValue.value()
    status = gate |> Map.get("status") |> EncodedValue.value()

    if id in [nil, ""] or status in [nil, ""] do
      []
    else
      [
        %{
          "id" => id,
          "status" => status,
          "classification" =>
            gate
            |> Map.get("classification")
            |> EncodedValue.value()
            |> gate_classification_for_status(status)
        }
      ]
    end
  end

  defp gate_classification_for_status(nil, "analysis_only"), do: "analysis_only"
  defp gate_classification_for_status(nil, "blocked"), do: "blocked_by_policy"
  defp gate_classification_for_status(nil, "review_required"), do: "operator_review_required"
  defp gate_classification_for_status(classification, _status), do: classification
end
