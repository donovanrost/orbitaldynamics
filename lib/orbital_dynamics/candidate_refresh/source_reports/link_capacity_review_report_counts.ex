defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewRows

  def count_rows(rows, field) do
    rows
    |> Enum.map(&(Map.get(&1, field) |> LinkCapacityReviewRows.normalized_source_report_token()))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end
end
