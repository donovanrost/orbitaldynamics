defmodule OrbitalDynamics.CandidateRefresh.OperationalReadinessSourceIdentityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "operational readiness replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_operational_readiness_contract")
    refute Map.has_key?(source_summary, "source_report_operational_readiness_count")
    refute Map.has_key?(source_summary, "source_report_operational_readiness_row_count")
    refute Map.has_key?(source_summary, "source_report_operational_readiness_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
    refute summary["branch_local_resource_pressure"]
  end

  test "operational readiness source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.operational_readiness_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "operational_readiness_report" =>
              Map.put(
                placeholder,
                "contract",
                "operational_readiness_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_operational_readiness_contract"] ==
               "operational_readiness_report.v1"

      refute Map.has_key?(source_summary, "source_report_operational_readiness_count")

      refute Map.has_key?(
               source_summary,
               "source_report_operational_readiness_row_count"
             )

      refute Map.has_key?(source_summary, "source_report_operational_readiness_paths")
    end
  end

  test "operational readiness source summary preserves non-identity rollups with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "readiness_level_counts" => %{"operator_review" => 1},
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_readiness_contract"] ==
             "operational_readiness_report.v1"

    refute Map.has_key?(source_summary, "source_report_operational_readiness_count")

    refute Map.has_key?(
             source_summary,
             "source_report_operational_readiness_row_count"
           )

    refute Map.has_key?(source_summary, "source_report_operational_readiness_paths")

    assert source_summary["source_report_operational_readiness_readiness_level_counts"] ==
             %{"operator_review" => 1}

    assert source_summary[
             "source_report_operational_readiness_resource_blocking_dimension_counts"
           ] == %{"communications" => 1}
  end

  test "operational readiness source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.operational_readiness_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_readiness_contract"] ==
             "operational_readiness_report.v1"

    assert source_summary["source_report_operational_readiness_count"] == 0
    assert source_summary["source_report_operational_readiness_row_count"] == 0

    assert source_summary["source_report_operational_readiness_paths"] == [
             "provenance.source_reports.operational_readiness_report"
           ]
  end

  test "operational readiness source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_readiness_contract"] ==
             "operational_readiness_report.v1"

    assert source_summary["source_report_operational_readiness_count"] == 1
    assert source_summary["source_report_operational_readiness_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_operational_readiness_paths")
  end

  test "operational readiness source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_readiness_contract"] ==
             "operational_readiness_report.v1"

    assert source_summary["source_report_operational_readiness_count"] == 1
    assert source_summary["source_report_operational_readiness_row_count"] == 2
    assert source_summary["source_report_operational_readiness_paths"] == []
  end

  test "operational readiness replay treats resource routing maps as resource pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_operational_readiness_report"],
            "review_gate_count" => 0,
            "blocked_gate_count" => 0,
            "review_required_count" => 0,
            "manifest_review_required_count" => 0,
            "missing_import_count" => 0,
            "blocked_import_count" => 0,
            "invalid_cadence_import_count" => 0,
            "resource_availability_pressure_count" => 0,
            "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
            "resource_availability_reason_ids" => ["antenna_unavailable"],
            "station_availability_reason_ids" => [],
            "station_availability_reason_counts" => %{},
            "unavailable_resource_reason_ids" => ["antenna_unavailable"],
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["resource_availability_pressure_count"] == 0
    assert summary["resource_availability_reason_counts"] == %{"antenna_unavailable" => 1}
    assert summary["resource_availability_reason_ids"] == ["antenna_unavailable"]
    assert summary["unavailable_resource_reason_ids"] == ["antenna_unavailable"]
    assert summary["resource_blocking_dimension_counts"] == %{"communications" => 1}
    assert summary["branch_local_resource_pressure"]
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
  end

  test "operational readiness replay treats review and import maps as pressure" do
    base_summary = %{
      "contract" => "operational_readiness_report.v1",
      "count" => 1,
      "row_count" => 1,
      "paths" => ["source_operational_readiness_report"],
      "review_gate_count" => 0,
      "blocked_gate_count" => 0,
      "review_required_count" => 0,
      "manifest_review_required_count" => 0,
      "missing_import_count" => 0,
      "blocked_import_count" => 0,
      "invalid_cadence_import_count" => 0,
      "resource_availability_pressure_count" => 0,
      "resource_availability_reason_counts" => %{},
      "resource_availability_reason_ids" => [],
      "station_availability_reason_ids" => [],
      "station_availability_reason_counts" => %{},
      "unavailable_resource_reason_ids" => [],
      "resource_blocking_dimension_counts" => %{},
      "review_type_counts" => %{},
      "import_action_counts" => %{},
      "source_review_type_counts" => %{}
    }

    cases = [
      {"review type", %{"review_type_counts" => %{"contact_allocation_review" => 1}},
       "branch_local_review_pressure"},
      {"source review type",
       %{"source_review_type_counts" => %{"contact_allocation_review" => 1}},
       "branch_local_review_pressure"},
      {"import action", %{"import_action_counts" => %{"review_contact_allocation" => 1}},
       "branch_local_import_pressure"}
    ]

    for {label, evidence, expected_pressure} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "operational_readiness_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

      assert summary["source_report_count"] == 1, label
      assert summary["review_gate_count"] == 0, label
      assert summary["blocked_gate_count"] == 0, label
      assert summary["review_required_count"] == 0, label
      assert summary["manifest_review_required_count"] == 0, label
      assert summary["missing_import_count"] == 0, label
      assert summary["blocked_import_count"] == 0, label
      assert summary["invalid_cadence_import_count"] == 0, label
      refute summary["branch_local_resource_pressure"], label
      assert summary[expected_pressure], label
    end
  end
end
