defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.CommandWindowFields.SourceValues do
  @moduledoc false

  def paths(sources), do: Enum.map(sources, fn {path, _report} -> path end)

  def reports(sources), do: Enum.map(sources, fn {_path, report} -> report end)

  def trust_boundary_status([]), do: "missing"
  def trust_boundary_status(_trust_boundaries), do: "declared"
end
