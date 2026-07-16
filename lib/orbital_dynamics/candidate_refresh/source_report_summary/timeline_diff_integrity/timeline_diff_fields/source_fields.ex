defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.SourceFields do
  @moduledoc false

  alias __MODULE__.{BaseFields, CountFields, StatusFields}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def fields(%{} = report) do
    report
    |> BaseFields.values()
    |> Map.merge(CountFields.values(report))
    |> Map.merge(status_fields(report))
    |> compact_map()
  end

  defp status_fields(report) do
    StatusFields.values(report)
  end
end
