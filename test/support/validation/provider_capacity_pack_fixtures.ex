defmodule OrbitalDynamics.Validation.ProviderCapacityPackFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def contact_allocation_provider_reservation_request_summary_fixture_observations do
    "contact_allocation_provider_reservation_request_summary.v1"
    |> Validation.artifact_observations(
      contact_allocation_provider_reservation_request_summary_fixture()
    )
  end

  def contact_allocation_provider_reservation_request_summary_fixture do
    read_json!("study_results/contact_allocation_provider_reservation_request_summary_v1.json")
  end

  def contact_allocation_capacity_pack_report_fixture_observations do
    "contact_allocation_report.v1"
    |> Validation.artifact_observations(contact_allocation_capacity_pack_report_fixture())
  end

  def contact_allocation_capacity_pack_report_fixture do
    read_json!("study_results/contact_allocation_capacity_pack_report_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
