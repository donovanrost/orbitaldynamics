defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintDirectReportSourceFields do
  @moduledoc false

  @constraint_fields [
    "source_constraint_report",
    "constraint_report"
  ]

  @link_capacity_fields [
    "source_link_capacity_report",
    "link_capacity_report",
    "source_link_capacity_summary",
    "link_capacity_summary",
    "source_relay_data_path_summary",
    "relay_data_path_summary"
  ]

  def constraint_sources(refresh), do: sources(refresh, @constraint_fields)

  def link_capacity_sources(refresh), do: sources(refresh, @link_capacity_fields)

  defp sources(refresh, fields) do
    scoped_sources(refresh, "accepted_planning_state", fields) ++
      scoped_sources(refresh, "mission_state", fields) ++
      root_sources(refresh, fields)
  end

  defp scoped_sources(refresh, scope, fields) do
    Enum.map(fields, fn field ->
      {"#{scope}.#{field}", get_in(refresh, [scope, field])}
    end)
  end

  defp root_sources(refresh, fields) do
    Enum.map(fields, fn field ->
      {field, Map.get(refresh, field)}
    end)
  end
end
