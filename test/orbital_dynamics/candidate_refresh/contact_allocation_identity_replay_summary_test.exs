defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationIdentityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact allocation replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_allocation_contract")
    refute Map.has_key?(source_summary, "source_report_contact_allocation_count")
    refute Map.has_key?(source_summary, "source_report_contact_allocation_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_allocation_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "contact_allocation_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.contact_allocation_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.contact_allocation_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_allocation_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_contact_allocation_contract"] ==
                 "contact_allocation_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_contact_allocation_contract")
      end

      refute Map.has_key?(source_summary, "source_report_contact_allocation_count")
      refute Map.has_key?(source_summary, "source_report_contact_allocation_row_count")
      refute Map.has_key?(source_summary, "source_report_contact_allocation_paths")
    end
  end

  test "contact allocation source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.contact_allocation_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_allocation_contract"] ==
             "contact_allocation_report.v1"

    assert source_summary["source_report_contact_allocation_count"] == 0
    assert source_summary["source_report_contact_allocation_row_count"] == 0

    assert source_summary["source_report_contact_allocation_paths"] == [
             "provenance.source_reports.contact_allocation_report"
           ]
  end

  test "contact allocation source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "contact_allocation_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "contact_allocation_report.v1",
        "count" => 1,
        "row_count" => 2,
        "paths" => nil
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_allocation_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

      assert source_summary["source_report_contact_allocation_contract"] ==
               "contact_allocation_report.v1"

      assert source_summary["source_report_contact_allocation_count"] == 1
      assert source_summary["source_report_contact_allocation_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_contact_allocation_paths")

      assert replay_summary["contract"] == "contact_allocation_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "contact allocation source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_contract"] ==
             "contact_allocation_report.v1"

    assert source_summary["source_report_contact_allocation_count"] == 1
    assert source_summary["source_report_contact_allocation_row_count"] == 2
    assert Map.has_key?(source_summary, "source_report_contact_allocation_paths")
    assert source_summary["source_report_contact_allocation_paths"] == []

    assert replay_summary["contract"] == "contact_allocation_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 2
    assert replay_summary["source_report_paths"] == []
  end
end
