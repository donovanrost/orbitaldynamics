defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.{
    DirectionRouting,
    HoldFields,
    ProviderContentionFields,
    ReservationFields,
    SourceFields
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    hold_summary = HoldFields.fields(reports)

    SourceFields.fields(sources, reports)
    |> Map.merge(ProviderContentionFields.fields(reports))
    |> Map.merge(ReservationFields.fields(reports))
    |> Map.merge(DirectionRouting.fields(reports, hold_summary))
    |> Map.merge(hold_summary)
    |> compact_map()
  end
end
