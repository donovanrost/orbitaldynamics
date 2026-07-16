defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields.RowFields do
  @moduledoc false

  alias __MODULE__.CountMapFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields.RowCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(reports) do
    %{}
    |> Map.merge(dependent_count_fields(reports))
    |> Map.merge(CountMapFields.fields(reports))
  end

  defp dependent_count_fields(reports) do
    %{
      "dependent_activity_count" =>
        sum_report_count(reports, &RowCounts.row_count(&1, "dependent_activity_count")),
      "source_dependent_activity_count" =>
        sum_report_count(
          reports,
          &RowCounts.scope_count(&1, "source_dependent_activity_count", "source")
        ),
      "replacement_dependent_activity_count" =>
        sum_report_count(
          reports,
          &RowCounts.scope_count(&1, "replacement_dependent_activity_count", "replacement")
        )
    }
  end
end
