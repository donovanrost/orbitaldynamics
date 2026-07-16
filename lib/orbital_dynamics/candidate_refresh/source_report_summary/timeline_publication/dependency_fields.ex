defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.DependencyFields do
  @moduledoc false

  alias __MODULE__.DownstreamInvalidation
  alias __MODULE__.IdLists

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(summaries) do
    %{
      "dependency_impact_row_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "dependency_impact_row_count"))
    }
    |> Map.merge(IdLists.fields(summaries))
    |> Map.merge(DownstreamInvalidation.fields(summaries))
  end
end
