defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups.Rows do
  @moduledoc false

  def count(report), do: length(values(report))

  def values(report), do: Map.get(report, "conflict_groups", [])
end
