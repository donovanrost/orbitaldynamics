defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues.ReasonIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues.AllowedReasons

  alias __MODULE__.FieldValues
  alias __MODULE__.NormalizedValues

  def resource_availability_reason_ids(report) do
    FieldValues.values(report, :resource_availability)
  end

  def station_availability_reason_ids(report) do
    report
    |> FieldValues.values(:station_availability)
    |> AllowedReasons.station_reason_ids()
  end

  def unavailable_resource_reason_ids(report) do
    report
    |> FieldValues.values(:unavailable_resource)
    |> AllowedReasons.unavailable_resource_reason_ids()
  end

  defdelegate sorted_non_empty_values(values), to: NormalizedValues
end
