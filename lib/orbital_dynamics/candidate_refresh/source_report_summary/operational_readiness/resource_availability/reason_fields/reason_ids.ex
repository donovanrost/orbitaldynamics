defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.ReasonIds do
  @moduledoc false

  alias __MODULE__.Values

  def resource_availability(reports), do: Values.resource_availability(reports)
  def station_availability(reports), do: Values.station_availability(reports)
  def unavailable_resource(reports), do: Values.unavailable_resource(reports)
end
