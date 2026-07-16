defmodule OrbitalDynamics.CandidateRefresh.QualityGatePressureReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "quality gate replay treats status and import maps as pressure" do
    base_summary = %{
      "contract" => "quality_gate_report.v1",
      "count" => 1,
      "row_count" => 1,
      "paths" => ["provenance.source_reports.quality_gate_report"],
      "review_gate_count" => 0,
      "blocked_gate_count" => 0,
      "manifest_review_required_count" => 0,
      "missing_import_count" => 0,
      "blocked_import_count" => 0,
      "invalid_cadence_import_count" => 0,
      "resource_availability_pressure_count" => 0,
      "readiness_level_counts" => %{},
      "import_classification_counts" => %{},
      "status_counts" => %{},
      "analysis_mode_counts" => %{},
      "gate_status_counts" => %{},
      "gate_classification_counts" => %{},
      "import_status_counts" => %{},
      "cadence_import_status_counts" => %{},
      "resource_availability_reason_counts" => %{},
      "resource_availability_reason_ids" => [],
      "station_availability_reason_ids" => [],
      "station_availability_reason_counts" => %{},
      "unavailable_resource_reason_ids" => [],
      "resource_blocking_dimension_counts" => %{}
    }

    cases = [
      {"readiness level", %{"readiness_level_counts" => %{"operator_review" => 1}},
       "branch_local_review_pressure"},
      {"import classification", %{"import_classification_counts" => %{"review_only" => 1}},
       "branch_local_review_pressure"},
      {"status", %{"status_counts" => %{"review_required" => 1}}, "branch_local_review_pressure"},
      {"analysis mode", %{"analysis_mode_counts" => %{"simulation" => 1}},
       "branch_local_review_pressure"},
      {"gate status", %{"gate_status_counts" => %{"review_required" => 1}},
       "branch_local_review_pressure"},
      {"gate classification", %{"gate_classification_counts" => %{"review_only" => 1}},
       "branch_local_review_pressure"},
      {"import status", %{"import_status_counts" => %{"review_required_before_import" => 1}},
       "branch_local_import_pressure"},
      {"cadence import status", %{"cadence_import_status_counts" => %{"missing" => 1}},
       "branch_local_import_pressure"}
    ]

    for {label, evidence, expected_pressure} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "quality_gate_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.quality_gate_replay_summary(artifact)

      assert summary["source_report_count"] == 1, label
      assert summary["source_report_row_count"] == 1, label
      assert summary["review_gate_count"] == 0, label
      assert summary["blocked_gate_count"] == 0, label
      assert summary["manifest_review_required_count"] == 0, label
      assert summary["missing_import_count"] == 0, label
      assert summary["blocked_import_count"] == 0, label
      assert summary["invalid_cadence_import_count"] == 0, label
      refute summary["branch_local_resource_pressure"], label
      assert summary[expected_pressure], label
    end
  end

  test "quality gate replay treats resource routing maps as resource pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.quality_gate_report"],
            "review_gate_count" => 0,
            "blocked_gate_count" => 0,
            "manifest_review_required_count" => 0,
            "missing_import_count" => 0,
            "blocked_import_count" => 0,
            "invalid_cadence_import_count" => 0,
            "resource_availability_pressure_count" => 0,
            "resource_availability_reason_counts" => %{"payload_unavailable" => 1},
            "resource_availability_reason_ids" => ["payload_unavailable"],
            "station_availability_reason_ids" => [],
            "station_availability_reason_counts" => %{},
            "unavailable_resource_reason_ids" => ["payload_unavailable"],
            "resource_blocking_dimension_counts" => %{"payload" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.quality_gate_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["source_report_paths"] == ["provenance.source_reports.quality_gate_report"]
    assert summary["resource_availability_pressure_count"] == 0
    assert summary["resource_availability_reason_counts"] == %{"payload_unavailable" => 1}
    assert summary["resource_availability_reason_ids"] == ["payload_unavailable"]
    assert summary["unavailable_resource_reason_ids"] == ["payload_unavailable"]
    assert summary["resource_blocking_dimension_counts"] == %{"payload" => 1}
    assert summary["branch_local_resource_pressure"]
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
  end
end
