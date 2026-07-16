defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.SourceFields.SourceContracts do
  @moduledoc false

  def fields(reports) do
    %{
      "provider_reservation_request_summary_schema_contract" =>
        source_summary_schema_contract(
          reports,
          "contact_allocation_provider_reservation_request_summary.v1"
        ),
      "contact_allocation_summary_schema_contract" =>
        source_summary_schema_contract(reports, "contact_allocation_summary.v1"),
      "station_pressure_summary_schema_contract" =>
        source_summary_schema_contract(
          reports,
          "contact_allocation_station_pressure_summary.v1"
        ),
      "reservation_conflict_summary_schema_contract" =>
        source_summary_schema_contract(
          reports,
          "contact_allocation_reservation_conflict_summary.v1"
        ),
      "capacity_pack_summary_schema_contract" =>
        source_summary_schema_contract(reports, "contact_allocation_capacity_pack_summary.v1")
    }
  end

  defp source_summary_schema_contract(reports, expected_contract) do
    reports
    |> Enum.map(&Map.get(&1, "source_summary_schema_contract"))
    |> Enum.filter(&(&1 == expected_contract))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      _contracts -> nil
    end
  end
end
