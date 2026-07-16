defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.Constraint
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacity
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintDirectReportSourceFields

  def constraint_reports(refresh) do
    refresh
    |> LinkConstraintDirectReportSourceFields.constraint_sources()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      Constraint.entries(path, report_or_reports)
    end)
  end

  def link_capacity_reports(refresh) do
    refresh
    |> LinkConstraintDirectReportSourceFields.link_capacity_sources()
    |> Enum.flat_map(fn {path, report_or_summary} ->
      LinkCapacity.entries(path, report_or_summary)
    end)
  end
end
