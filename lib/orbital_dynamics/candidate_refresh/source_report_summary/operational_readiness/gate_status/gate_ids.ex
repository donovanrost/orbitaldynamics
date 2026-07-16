defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds do
  @moduledoc false

  alias __MODULE__.Fallbacks
  alias __MODULE__.NonPassedRows
  alias __MODULE__.RoutedIds
  alias __MODULE__.StatusIds

  def passed_ids(report) do
    Fallbacks.list(report, "passed_gate_ids")
  end

  def non_passed_ids(report) do
    case NonPassedRows.ids(report) do
      [_id | _ids] = ids ->
        ids

      [] ->
        fallback_non_passed_gate_ids(report)
    end
  end

  def non_passed_ids_by_status(report), do: RoutedIds.by_status(report)

  def non_passed_ids_by_classification(report), do: RoutedIds.by_classification(report)

  def ids_for_status(reports, status, fallback_field) do
    StatusIds.for_status(reports, status, fallback_field)
  end

  defp fallback_non_passed_gate_ids(report) do
    Fallbacks.non_passed_ids(report, NonPassedRows.raw_ids(report))
  end
end
