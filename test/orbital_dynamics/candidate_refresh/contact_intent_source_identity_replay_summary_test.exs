defmodule OrbitalDynamics.CandidateRefresh.ContactIntentSourceIdentityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact intent replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_intent_contract")
    refute Map.has_key?(source_summary, "source_report_contact_intent_count")
    refute Map.has_key?(source_summary, "source_report_contact_intent_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_intent_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_contact_intent_pressure"]
  end

  test "contact intent source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "contact_intent.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.contact_intent"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.contact_intent"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_intent" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_contact_intent_contract"] ==
                 "contact_intent.v1"
      else
        refute Map.has_key?(source_summary, "source_report_contact_intent_contract")
      end

      refute Map.has_key?(source_summary, "source_report_contact_intent_count")
      refute Map.has_key?(source_summary, "source_report_contact_intent_row_count")
      refute Map.has_key?(source_summary, "source_report_contact_intent_paths")
    end
  end

  test "contact intent source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.contact_intent"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_intent_contract"] == "contact_intent.v1"
    assert source_summary["source_report_contact_intent_count"] == 0
    assert source_summary["source_report_contact_intent_row_count"] == 0

    assert source_summary["source_report_contact_intent_paths"] == [
             "provenance.source_reports.contact_intent"
           ]
  end

  test "contact intent source summary omits missing identity paths after preserving counts" do
    summaries = [
      {"missing paths",
       %{
         "contract" => "contact_intent.v1",
         "count" => 1,
         "row_count" => 2
       }},
      {"nil paths",
       %{
         "contract" => "contact_intent.v1",
         "count" => 1,
         "row_count" => 2,
         "paths" => nil
       }}
    ]

    for {label, contact_intent_summary} <- summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_intent" => contact_intent_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_contact_intent_contract"] == "contact_intent.v1",
             label

      assert source_summary["source_report_contact_intent_count"] == 1, label
      assert source_summary["source_report_contact_intent_row_count"] == 2, label
      refute Map.has_key?(source_summary, "source_report_contact_intent_paths"), label
    end
  end

  test "contact intent source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_intent_contract"] == "contact_intent.v1"
    assert source_summary["source_report_contact_intent_count"] == 1
    assert source_summary["source_report_contact_intent_row_count"] == 2
    assert source_summary["source_report_contact_intent_paths"] == []
  end

  test "contact intent replay preserves direction routing pressure with partial identity" do
    direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["contact_downlink"],
        "capacity_pack_required_capacity_fraction" => 0.35,
        "capacity_pack_contact_ids" => ["contact_downlink"],
        "ground_station_ids" => ["equator_prime"],
        "contact_ids_by_ground_station" => %{
          "equator_prime" => ["contact_downlink"]
        },
        "capacity_pack_required_capacity_fraction_by_ground_station" => %{
          "equator_prime" => 0.35
        },
        "capacity_pack_contact_ids_by_ground_station" => %{
          "equator_prime" => ["contact_downlink"]
        }
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 1,
            "directions" => ["downlink"],
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["contact_downlink"]},
            "direction_routing" => direction_routing
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_intent_count")
    refute Map.has_key?(source_summary, "source_report_contact_intent_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_intent_paths")

    assert source_summary["source_report_contact_intent_directions"] == ["downlink"]
    assert source_summary["source_report_contact_intent_direction_counts"] == %{"downlink" => 1}

    assert source_summary["source_report_contact_intent_contact_ids_by_direction"] == %{
             "downlink" => ["contact_downlink"]
           }

    assert source_summary["source_report_contact_intent_direction_routing"] ==
             direction_routing

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source_report_row_count"] == 1
    assert summary["capacity_pack_required_contact_count"] == 1
    assert summary["directions"] == ["downlink"]
    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["contact_downlink"]}
    assert summary["direction_routing"] == direction_routing
    assert summary["branch_local_contact_intent_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
  end

  test "contact intent replay counts nested direction station contact maps" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent_summary.v1",
            "count" => 1,
            "row_count" => 99,
            "capacity_pack_required_contact_count" => 99,
            "contact_ids_by_direction_and_ground_station" => %{
              "downlink" => %{"equator_prime" => ["nested_contact_a"]},
              "tracking" => %{"dss_43" => ["nested_contact_b"]}
            },
            "capacity_pack_contact_ids_by_direction_and_ground_station" => %{
              "downlink" => %{"equator_prime" => ["nested_contact_a"]}
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source_report_row_count"] == 2
    assert summary["capacity_pack_required_contact_count"] == 1

    assert summary["contact_ids_by_direction_and_ground_station"] == %{
             "downlink" => %{"equator_prime" => ["nested_contact_a"]},
             "tracking" => %{"dss_43" => ["nested_contact_b"]}
           }

    assert summary["capacity_pack_contact_ids_by_direction_and_ground_station"] == %{
             "downlink" => %{"equator_prime" => ["nested_contact_a"]}
           }

    assert summary["branch_local_contact_intent_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
  end

  test "contact intent replay treats explicit empty contact maps as zero counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent_summary.v1",
            "count" => 1,
            "row_count" => 99,
            "capacity_pack_required_contact_count" => 99,
            "contact_ids_by_direction" => %{},
            "contact_ids_by_ground_station" => %{},
            "capacity_pack_contact_ids_by_direction" => %{},
            "capacity_pack_contact_ids_by_ground_station" => %{},
            "required_capacity_fraction_contact_ids_by_source" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source_report_row_count"] == 0
    assert summary["capacity_pack_required_contact_count"] == 0
    assert summary["contact_ids_by_direction"] == %{}
    refute summary["branch_local_contact_intent_pressure"]
    refute summary["branch_local_capacity_pack_pressure"]
  end

  test "contact intent replay does not count stale routing when empty maps are present" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent_summary.v1",
            "row_count" => 99,
            "capacity_pack_required_contact_count" => 99,
            "contact_ids_by_direction" => %{},
            "capacity_pack_contact_ids_by_direction" => %{},
            "direction_routing" => %{
              "downlink" => %{
                "contact_ids" => ["stale_route_contact"],
                "capacity_pack_contact_ids" => ["stale_route_contact"]
              }
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source_report_row_count"] == 0
    assert summary["capacity_pack_required_contact_count"] == 0
    assert summary["direction_routing"]["downlink"]["contact_ids"] == ["stale_route_contact"]
  end
end
