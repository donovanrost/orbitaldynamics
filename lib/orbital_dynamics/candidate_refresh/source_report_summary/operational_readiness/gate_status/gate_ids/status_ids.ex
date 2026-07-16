defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.StatusIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.Fallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.NonPassedRows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def for_status(reports, status, fallback_field) do
    reports
    |> Enum.flat_map(&non_passed_ids_for_status(&1, status, fallback_field))
    |> sorted_string_values()
  end

  defp non_passed_ids_for_status(report, status, fallback_field) do
    case NonPassedRows.ids_by_status(report) do
      %{} = ids_by_status when map_size(ids_by_status) > 0 ->
        Map.get(ids_by_status, status, [])

      _ids_by_status ->
        Fallbacks.list(report, fallback_field)
    end
  end
end
