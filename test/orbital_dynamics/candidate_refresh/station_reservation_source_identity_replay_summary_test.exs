defmodule OrbitalDynamics.CandidateRefresh.StationReservationSourceIdentityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "station reservation replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.station_reservation_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_station_reservation_contract")
    refute Map.has_key?(source_summary, "source_report_station_reservation_count")
    refute Map.has_key?(source_summary, "source_report_station_reservation_row_count")
    refute Map.has_key?(source_summary, "source_report_station_reservation_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_station_reservation_pressure"]
  end

  test "station reservation source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "station_reservation_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.station_reservation_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.station_reservation_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "station_reservation_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_station_reservation_contract"] ==
                 "station_reservation_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_station_reservation_contract")
      end

      refute Map.has_key?(source_summary, "source_report_station_reservation_count")
      refute Map.has_key?(source_summary, "source_report_station_reservation_row_count")
      refute Map.has_key?(source_summary, "source_report_station_reservation_paths")
    end
  end

  test "station reservation source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.station_reservation_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_reservation_contract"] ==
             "station_reservation_report.v1"

    assert source_summary["source_report_station_reservation_count"] == 0
    assert source_summary["source_report_station_reservation_row_count"] == 0

    assert source_summary["source_report_station_reservation_paths"] == [
             "provenance.source_reports.station_reservation_report"
           ]
  end

  test "station reservation source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_reservation_contract"] ==
             "station_reservation_report.v1"

    assert source_summary["source_report_station_reservation_count"] == 1
    assert source_summary["source_report_station_reservation_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_station_reservation_paths")
  end

  test "station reservation source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_reservation_contract"] ==
             "station_reservation_report.v1"

    assert source_summary["source_report_station_reservation_count"] == 1
    assert source_summary["source_report_station_reservation_row_count"] == 2
    assert source_summary["source_report_station_reservation_paths"] == []
  end

  test "station reservation replay treats preserved provider-contention maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_station_reservation_report"],
            "affected_contact_count" => 0,
            "provider_calendar_contention_group_count" => 0,
            "provider_calendar_contention_group_ids" => ["reservation_contention_map_only"],
            "provider_calendar_contention_source_entry_ids" => ["provider_source_map_only"],
            "provider_calendar_contention_provider_entry_ids" => ["provider_entry_map_only"],
            "provider_calendar_contention_provider_entry_ids_by_provider" => %{
              "ops_calendar" => ["provider_entry_map_only"]
            },
            "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
              "equator_prime" => ["provider_entry_map_only"]
            },
            "provider_calendar_contention_provider_entry_ids_by_direction" => %{
              "downlink" => ["provider_entry_map_only"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert summary["affected_contact_count"] == 0
    assert summary["provider_calendar_contention_group_count"] == 0

    assert summary["provider_calendar_contention_group_ids"] == [
             "reservation_contention_map_only"
           ]

    assert summary["provider_calendar_contention_source_entry_ids"] == [
             "provider_source_map_only"
           ]

    assert summary["provider_calendar_contention_provider_entry_ids"] == [
             "provider_entry_map_only"
           ]

    assert summary["provider_calendar_contention_provider_entry_ids_by_provider"] == %{
             "ops_calendar" => ["provider_entry_map_only"]
           }

    assert summary["provider_calendar_contention_provider_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["provider_entry_map_only"]
           }

    assert summary["provider_calendar_contention_provider_entry_ids_by_direction"] == %{
             "downlink" => ["provider_entry_map_only"]
           }

    assert summary["branch_local_station_reservation_pressure"]
    assert summary["branch_local_provider_contention_pressure"]
  end

  test "station reservation replay treats preserved expiration evidence as family pressure" do
    base_summary = %{
      "contract" => "station_reservation_report.v1",
      "count" => 1,
      "row_count" => 0,
      "paths" => ["source_station_reservation_report"],
      "affected_contact_count" => 0,
      "affected_contact_ids" => [],
      "contact_ids_by_match_status" => %{},
      "contact_ids_by_status" => %{},
      "direction_counts" => %{},
      "contact_ids_by_direction" => %{},
      "provider_calendar_contention_group_count" => 0,
      "provider_calendar_contention_provider_counts" => %{},
      "provider_calendar_contention_ground_station_counts" => %{},
      "provider_calendar_contention_group_ids" => [],
      "provider_calendar_contention_source_entry_ids" => [],
      "provider_calendar_contention_provider_entry_ids" => [],
      "provider_calendar_contention_provider_entry_ids_by_provider" => %{},
      "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{},
      "provider_calendar_contention_provider_entry_ids_by_direction" => %{},
      "reservation_review_count" => 0,
      "station_reservation_evidence_row_count" => 0,
      "station_reservation_expiration_evidence_row_count" => 0,
      "reservation_expires_at_s" => [],
      "station_reservation_match_status_counts" => %{},
      "reservation_status_counts" => %{},
      "reservation_ids" => [],
      "reservation_ids_by_match_status" => %{},
      "reservation_ids_by_status" => %{},
      "reserved_by_counts" => %{},
      "contact_ids_by_reserved_by" => %{},
      "reservation_ids_by_reserved_by" => %{}
    }

    cases = [
      {"expiration evidence", %{"station_reservation_expiration_evidence_row_count" => 1}},
      {"expiration timestamps", %{"reservation_expires_at_s" => [360.0]}},
      {"earliest expiration", %{"earliest_reservation_expires_at_s" => 360.0}}
    ]

    for {label, evidence} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "station_reservation_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.station_reservation_replay_summary(artifact)

      assert summary["source_report_count"] == 1, label
      assert summary["affected_contact_count"] == 0, label
      assert summary["affected_contact_ids"] == [], label
      assert summary["reservation_review_count"] == 0, label
      assert summary["station_reservation_evidence_row_count"] == 0, label
      assert summary["reservation_ids"] == [], label
      assert summary["reserved_by_counts"] == %{}, label
      assert summary["provider_calendar_contention_group_count"] == 0, label
      refute summary["branch_local_reservation_review_pressure"], label
      refute summary["branch_local_reservation_owner_pressure"], label
      refute summary["branch_local_provider_contention_pressure"], label
      assert summary["branch_local_reservation_expiration_pressure"], label
      assert summary["branch_local_station_reservation_pressure"], label
    end
  end
end
