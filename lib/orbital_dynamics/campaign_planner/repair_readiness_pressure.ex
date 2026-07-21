defmodule OrbitalDynamics.CampaignPlanner.RepairReadinessPressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalReadinessPressureEvents,
    OperationalReadinessSourceReports,
    QualityGatePressureEvents,
    QualityGateSourceReports
  }

  def operational_count(report),
    do: operational_count(report, &OperationalReadinessPressureEvents.reviewable?/1)

  def operational_count(%{} = report, reviewable?) when is_function(reviewable?, 1) do
    report
    |> OperationalReadinessSourceReports.pressure_rows_for_report()
    |> Enum.filter(&is_map/1)
    |> Enum.count(reviewable?)
  rescue
    _error in [ArgumentError, BadMapError, FunctionClauseError] -> 0
  end

  def operational_count(_report, _reviewable?), do: 0

  def quality_gate_count(report),
    do: quality_gate_count(report, &QualityGatePressureEvents.reviewable?/1)

  def quality_gate_count(%{} = report, reviewable?) when is_function(reviewable?, 1) do
    report
    |> QualityGateSourceReports.pressure_rows_for_report()
    |> Enum.filter(&is_map/1)
    |> Enum.count(reviewable?)
  rescue
    _error in [ArgumentError, BadMapError, FunctionClauseError] -> 0
  end

  def quality_gate_count(_report, _reviewable?), do: 0
end
