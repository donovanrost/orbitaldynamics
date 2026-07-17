defmodule OrbitalDynamics.Validation.ContactAllocationFixtures do
  alias OrbitalDynamics.Validation

  def contact_allocation_report_fixture_observations do
    "contact_allocation_report.v1"
    |> Validation.artifact_observations(contact_allocation_report_fixture())
  end

  def contact_allocation_report_fixture do
    read_json!("study_results/contact_allocation_report_v1.json")
  end

  def contact_allocation_summary_fixture_observations do
    "contact_allocation_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_summary_v1.json")
    )
  end

  def contact_allocation_capacity_pack_summary_fixture_observations do
    "contact_allocation_capacity_pack_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")
    )
  end

  def contact_allocation_reservation_conflict_summary_fixture_observations do
    "contact_allocation_reservation_conflict_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_reservation_conflict_summary_v1.json")
    )
  end

  def contact_allocation_station_pressure_summary_fixture_observations do
    "contact_allocation_station_pressure_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_station_pressure_summary_v1.json")
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
