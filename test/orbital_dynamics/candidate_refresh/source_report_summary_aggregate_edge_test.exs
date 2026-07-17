defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummaryAggregateEdgeTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary treats non-map inputs as an empty artifact" do
    empty_summary = CandidateRefresh.source_report_summary(%{})

    for input <- [nil, [], "invalid"] do
      assert CandidateRefresh.source_report_summary(input) == empty_summary
    end
  end

  test "source report summary ignores malformed path and grouping values in aggregates" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "paths" => [42, "mission_state.source_quality_gate_report"],
            "contract" => 42,
            "count" => 1,
            "row_count" => 2,
            "trust_boundary_status" => 42
          }
        }
      }
    }

    summary = CandidateRefresh.source_report_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2
    assert summary["source_report_contracts"] == []
    assert summary["source_report_paths"] == ["mission_state.source_quality_gate_report"]

    assert summary["source_report_paths_by_family"] == %{
             "quality_gate_report" => ["mission_state.source_quality_gate_report"]
           }

    refute Map.has_key?(summary, "source_report_counts_by_contract")
    refute Map.has_key?(summary, "source_report_row_counts_by_contract")
    refute Map.has_key?(summary, "source_report_counts_by_trust_boundary_status")
    refute Map.has_key?(summary, "source_report_row_counts_by_trust_boundary_status")
    refute Map.has_key?(summary, "source_report_paths_by_contract")
    refute Map.has_key?(summary, "source_report_paths_by_trust_boundary_status")
    refute Map.has_key?(summary, "trust_boundary_status_counts")
  end

  test "source report summary preserves explicit zero aggregate counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => [],
            "trust_boundary_status" => "declared"
          },
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => nil,
            "row_count" => nil,
            "paths" => nil,
            "trust_boundary_status" => "declared"
          },
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1"
          }
        }
      }
    }

    summary = CandidateRefresh.source_report_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_counts_by_family"] == %{
             "contact_allocation_report" => 0
           }

    assert summary["source_report_row_counts_by_family"] == %{
             "contact_allocation_report" => 0
           }

    assert summary["source_report_counts_by_contract"] == %{
             "contact_allocation_report.v1" => 0
           }

    assert summary["source_report_row_counts_by_contract"] == %{
             "contact_allocation_report.v1" => 0
           }

    assert summary["source_report_counts_by_trust_boundary_status"] == %{"declared" => 0}
    assert summary["source_report_row_counts_by_trust_boundary_status"] == %{"declared" => 0}

    assert summary["source_report_families"] == [
             "contact_allocation_report",
             "link_capacity_report",
             "resource_projection_report"
           ]
  end
end
