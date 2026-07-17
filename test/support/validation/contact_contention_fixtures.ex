defmodule OrbitalDynamics.Validation.ContactContentionFixtures do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactContention
  alias OrbitalDynamics.Validation

  def contact_filter_report_fixture_observations do
    "contact_filter_report.v1"
    |> Validation.artifact_observations(contact_filter_report_fixture())
  end

  def contact_filter_report_fixture do
    read_json!("study_results/contact_filter_report_v1.json")
  end

  def contact_contention_report_fixture_observations do
    "contact_contention_report.v1"
    |> Validation.artifact_observations(contact_contention_report_fixture())
  end

  def contact_contention_report_fixture do
    read_json!("study_results/contact_contention_report_v1.json")
  end

  def contact_contention_cross_station_fixture_observations do
    "contact_contention_report.v1"
    |> Validation.artifact_observations(contact_contention_cross_station_fixture())
  end

  def contact_contention_cross_station_fixture do
    [
      %{
        id: :dl_equator,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 8.0
      },
      %{
        id: :dl_dsn,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        ground_station_id: :deep_space_net,
        starts_at_s: 120.0,
        ends_at_s: 170.0,
        score: 10.0
      },
      %{
        id: :dl_other_spacecraft,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_2,
        ground_station_id: :polar_aux,
        starts_at_s: 125.0,
        ends_at_s: 155.0,
        score: 7.0
      }
    ]
    |> ContactContention.report(source: "generated_cross_station_spacecraft_contention_fixture")
  end

  def contact_contention_resolution_report_fixture_observations do
    "contact_contention_resolution_report.v1"
    |> Validation.artifact_observations(contact_contention_resolution_report_fixture())
  end

  def contact_contention_resolution_report_fixture do
    read_json!("study_results/contact_contention_resolution_report_v1.json")
  end

  def contact_contention_resolution_summary_fixture_observations do
    "contact_contention_resolution_summary.v1"
    |> Validation.artifact_observations(contact_contention_resolution_summary_fixture())
  end

  def contact_contention_resolution_summary_fixture do
    read_json!("study_results/contact_contention_resolution_summary_v1.json")
  end

  def read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
