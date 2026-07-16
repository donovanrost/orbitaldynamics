defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRowCounts do
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
end
