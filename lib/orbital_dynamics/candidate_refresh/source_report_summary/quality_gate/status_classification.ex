defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification do
  @moduledoc false

  alias __MODULE__.ClassificationCounts
  alias __MODULE__.GateCounts
  alias __MODULE__.StatusIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def fields(reports) do
    reports
    |> status_classification_count_fields()
    |> Map.merge(StatusIds.fields(reports))
    |> compact_map()
  end

  defp status_classification_count_fields(reports) do
    ClassificationCounts.fields(reports)
    |> Map.merge(GateCounts.fields(reports))
  end
end
