defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportReportCounts do
  @moduledoc false

  def duplicate_identity_count(rows) do
    Enum.count(rows, &duplicate_identity_row?/1)
  end

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

  defp duplicate_identity_row?(row) do
    row["timeline_identity_collision"] == true or
      row["duplicate_timeline_identity_scope"] in [
        "source",
        "replacement",
        "source_and_replacement"
      ]
  end
end
