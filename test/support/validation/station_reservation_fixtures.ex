defmodule OrbitalDynamics.Validation.StationReservationFixtures do
  alias OrbitalDynamics.Communications.StationCalendar
  alias OrbitalDynamics.Validation

  def station_calendar_report_fixture_observations do
    "station_calendar_report.v1"
    |> Validation.artifact_observations(station_calendar_report_fixture())
  end

  def station_reservation_report_fixture_observations do
    "station_reservation_report.v1"
    |> Validation.artifact_observations(station_reservation_report_fixture())
  end

  def station_reservation_report_fixture do
    station_calendar_report_fixture()
    |> StationCalendar.reservation_report()
  end

  def station_reservation_review_summary_fixture_observations do
    "station_reservation_review_summary.v1"
    |> Validation.artifact_observations(station_reservation_review_summary_fixture())
  end

  def station_reservation_review_summary_fixture do
    read_json!("study_results/station_reservation_review_summary_v1.json")
  end

  def station_reservation_hold_summary_fixture_observations do
    "station_reservation_hold_summary.v1"
    |> Validation.artifact_observations(station_reservation_hold_summary_fixture())
  end

  def station_reservation_hold_summary_fixture do
    read_json!("study_results/station_reservation_hold_summary_v1.json")
  end

  def station_reservation_hold_import_readiness_summary_fixture_observations do
    "station_reservation_hold_import_readiness_summary.v1"
    |> Validation.artifact_observations(
      station_reservation_hold_import_readiness_summary_fixture()
    )
  end

  def station_reservation_hold_import_readiness_summary_fixture do
    read_json!("study_results/station_reservation_hold_import_readiness_summary_v1.json")
  end

  def station_calendar_precedence_summary_fixture_observations do
    "station_calendar_precedence_summary.v1"
    |> Validation.artifact_observations(station_calendar_precedence_summary_fixture())
  end

  def station_calendar_precedence_summary_fixture do
    read_json!("study_results/station_calendar_precedence_summary_v1.json")
  end

  def station_calendar_provider_fixture_observations do
    "station_calendar_provider.v1"
    |> Validation.artifact_observations(station_calendar_provider_fixture())
  end

  def station_calendar_provider_fixture do
    read_json!("study_results/station_calendar_provider_v1.json")
  end

  def checked_in_station_calendar_report_fixture_observations do
    "station_calendar_report.v1"
    |> Validation.artifact_observations(checked_in_station_calendar_report_fixture())
  end

  def checked_in_station_calendar_report_fixture do
    read_json!("study_results/station_calendar_report_v1.json")
  end

  def station_calendar_report_fixture do
    contacts = [
      %{
        id: :dl_hold,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_downlink_hold,
          station_id: :equator_prime,
          availability: :reservation_hold,
          directions: [:downlink],
          start_s: 100.0,
          end_s: 200.0,
          hold_id: :provider_hold_1,
          hold_expires_at_s: 95.0,
          held_by: :ops_calendar,
          hold_status: :tentative_hold
        }
      ]
    }

    StationCalendar.report(contacts, provider, source: "stale_provider_calendar")
  end

  def provider_counteroffer_report_fixture_observations do
    "provider_counteroffer_report.v1"
    |> Validation.artifact_observations(provider_counteroffer_report_fixture())
  end

  def provider_counteroffer_report_fixture do
    contacts = [
      %{
        id: :dl_counteroffer,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 140.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_counteroffer_window,
          station_id: :equator_prime,
          availability: :available,
          directions: [:downlink],
          start_s: 130.0,
          end_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          counteroffer_cost_delta: 125.5,
          schedule_lock_deadline_s: 150.0,
          counteroffer_start_s: 130.0,
          counteroffer_end_s: 170.0
        }
      ]
    }

    contacts
    |> StationCalendar.report(provider, source: "provider_counteroffer_fixture")
    |> StationCalendar.provider_counteroffer_report()
  end

  def provider_counteroffer_review_summary_fixture_observations do
    "provider_counteroffer_review_summary.v1"
    |> Validation.artifact_observations(provider_counteroffer_review_summary_fixture())
  end

  def provider_counteroffer_review_summary_fixture do
    read_json!("study_results/provider_counteroffer_review_summary_v1.json")
  end

  def provider_counteroffer_import_readiness_summary_fixture_observations do
    "provider_counteroffer_import_readiness_summary.v1"
    |> Validation.artifact_observations(provider_counteroffer_import_readiness_summary_fixture())
  end

  def provider_counteroffer_import_readiness_summary_fixture do
    read_json!("study_results/provider_counteroffer_import_readiness_summary_v1.json")
  end

  def provider_counteroffer_plan_impact_summary_fixture_observations do
    "provider_counteroffer_plan_impact_summary.v1"
    |> Validation.artifact_observations(provider_counteroffer_plan_impact_summary_fixture())
  end

  def provider_counteroffer_plan_impact_summary_fixture do
    read_json!("study_results/provider_counteroffer_plan_impact_summary_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
