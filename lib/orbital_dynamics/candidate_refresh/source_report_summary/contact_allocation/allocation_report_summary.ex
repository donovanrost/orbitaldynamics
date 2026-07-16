defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary do
  @moduledoc false

  alias __MODULE__.ContactFields
  alias __MODULE__.CountFields
  alias __MODULE__.ReportCountMaps

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def fields(reports) do
    reports
    |> allocation_report_fields()
    |> Map.merge(CountFields.fields(reports))
    |> compact_map()
  end

  defp allocation_report_fields(reports) do
    reports
    |> ReportCountMaps.fields()
    |> Map.merge(ContactFields.fields(reports))
  end
end
