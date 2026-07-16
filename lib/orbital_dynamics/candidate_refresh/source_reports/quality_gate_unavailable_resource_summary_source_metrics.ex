defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateUnavailableResourceSummarySourceMetrics do
  @moduledoc false

  def fields(%{} = summary) do
    %{
      "resource_availability_reason_ids" => summary["unavailable_resource_reason_ids"],
      "station_availability_reason_counts" => summary["station_availability_reason_counts"],
      "station_availability_reason_ids" => summary["station_availability_reason_ids"],
      "unavailable_resource_reason_ids" => summary["unavailable_resource_reason_ids"],
      "resource_blocking_dimension_counts" => summary["resource_blocking_dimension_counts"],
      "blocked_contact_ids_by_blocking_dimension" =>
        summary["blocked_contact_ids_by_blocking_dimension"],
      "blocked_contact_ids_by_spacecraft_id" => summary["blocked_contact_ids_by_spacecraft_id"],
      "blocked_contact_ids_by_status" => summary["blocked_contact_ids_by_status"],
      "resource_availability_gate_ids" => summary["resource_availability_gate_ids"]
    }
  end
end
