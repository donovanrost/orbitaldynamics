defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.CountFields.CountMaps.CountValues.RowCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def by(report, identity_fun) do
    report
    |> RowValues.rows()
    |> Enum.map(identity_fun)
    |> count_source_report_values()
  end

  def by_field(report, field) do
    report
    |> RowValues.rows()
    |> Enum.map(&RowValues.normalized_field(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end
end
