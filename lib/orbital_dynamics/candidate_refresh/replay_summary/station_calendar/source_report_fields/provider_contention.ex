defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention do
  @moduledoc false

  alias __MODULE__.Aggregate
  alias __MODULE__.Capacity
  alias __MODULE__.Direction
  alias __MODULE__.Identity

  def source_report_provider_contention_fields(source_reports) do
    source_reports
    |> Aggregate.source_report_aggregate_fields()
    |> Map.merge(Identity.source_report_identity_fields(source_reports))
    |> Map.merge(Capacity.source_report_capacity_fields(source_reports))
    |> Map.merge(Direction.source_report_direction_fields(source_reports))
  end
end
