defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationReportFields do
  @moduledoc false

  @fields [
    "source_contact_allocation_report",
    "contact_allocation_report",
    "source_contact_allocation_summary",
    "contact_allocation_summary",
    "source_contact_allocation_station_pressure_summary",
    "contact_allocation_station_pressure_summary",
    "source_contact_allocation_reservation_conflict_summary",
    "contact_allocation_reservation_conflict_summary",
    "source_contact_allocation_capacity_pack_summary",
    "contact_allocation_capacity_pack_summary",
    "source_contact_allocation_provider_reservation_request_summary",
    "contact_allocation_provider_reservation_request_summary"
  ]

  def fields, do: @fields
end
