defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.{
    AllocationReportSummary,
    CapacityPackSummary,
    DirectionRouting,
    PressureConflictSummary,
    ProviderReservationSummary,
    SourceFields,
    StationReservationSummary
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.put("direction_routing", DirectionRouting.fields(reports))
    |> Map.merge(StationReservationSummary.fields(reports))
    |> Map.merge(AllocationReportSummary.fields(reports))
    |> Map.merge(CapacityPackSummary.fields(reports))
    |> Map.merge(PressureConflictSummary.fields(reports))
    |> Map.merge(ProviderReservationSummary.fields(reports))
    |> compact_map()
  end
end
