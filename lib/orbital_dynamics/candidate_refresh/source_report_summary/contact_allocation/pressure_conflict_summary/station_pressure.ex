defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.StationPressure do
  @moduledoc false

  alias __MODULE__.{ContactIds, CountFields}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(ContactIds.fields(reports))
    |> compact_map()
  end
end
