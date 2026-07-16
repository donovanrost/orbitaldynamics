defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues.ReasonIds.FieldSpecs do
  @moduledoc false

  @field_specs %{
    resource_availability: {
      "resource_availability_reason_ids",
      "resource_availability_reason_counts",
      "resource_availability_reason_ids",
      "resource_availability_reason_counts"
    },
    station_availability: {
      "station_availability_reason_ids",
      "station_availability_reason_counts",
      "station_availability_reason_ids",
      "resource_availability_reason_counts"
    },
    unavailable_resource: {
      "unavailable_resource_reason_ids",
      "unavailable_resource_reason_counts",
      "unavailable_resource_reason_ids",
      "resource_availability_reason_counts"
    }
  }

  def fetch!(reason_family), do: Map.fetch!(@field_specs, reason_family)
end
