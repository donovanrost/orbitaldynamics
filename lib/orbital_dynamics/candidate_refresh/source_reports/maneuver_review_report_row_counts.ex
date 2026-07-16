defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewReportRowCounts do
  @moduledoc false

  def count_rows(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  def count_rows(rows, field, value) do
    rows
    |> Enum.count(&(Map.get(&1, field) == value))
    |> case do
      0 -> nil
      count -> count
    end
  end
end
