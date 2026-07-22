defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.{
    AllocationReportSummary,
    BlockedInputIdentityCorrelation,
    CapacityPackSummary,
    CountMapCorrelation,
    DirectionRouting,
    OutcomeIdentityCorrelation,
    PressureConflictSummary,
    ProviderReservationSummary,
    ReasonIdentityCorrelation,
    ReservationConflictCorrelation,
    ReviewIdentityCorrelation,
    ResourceBlockingCorrelation,
    RowCountCorrelation,
    SourceFields,
    StationPressureRoutingCorrelation,
    StationPressureReviewCorrelation,
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
    |> StationPressureRoutingCorrelation.fields()
    |> ReservationConflictCorrelation.fields()
    |> Map.merge(ProviderReservationSummary.fields(reports))
    |> correlate_direction_fields()
    |> CountMapCorrelation.fields()
    |> RowCountCorrelation.fields()
    |> OutcomeIdentityCorrelation.fields()
    |> ResourceBlockingCorrelation.fields()
    |> BlockedInputIdentityCorrelation.fields()
    |> ReasonIdentityCorrelation.fields()
    |> ReviewIdentityCorrelation.fields()
    |> StationPressureReviewCorrelation.fields()
    |> compact_map()
  end

  defp correlate_direction_fields(summary) do
    Map.merge(summary, DirectionRouting.direction_fields_from_summary(summary))
  end
end
