defmodule OrbitalDynamics.OperatorReview.CandidateRefreshProviderCounterofferTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source provider counteroffer reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:provider_counteroffer_review:001",
      "source_provider_counteroffer_report" => provider_counteroffer_report()
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:provider_counteroffer_review:001",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "provider_counteroffer_review",
               "source" => "candidate_refresh.source_provider_counteroffer_report.rows",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_negotiation_state" => "proposed",
               "provider_counteroffer_cost_delta" => 125.5,
               "provider_counteroffer_lock_deadline_s" => 150.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 40.0,
               "provider_counteroffer_duration_delta_s" => 10.0,
               "required_operator_action" => "review_provider_counteroffer",
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_status" => "proposed"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact provider counteroffer reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_provider_counteroffer_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provider_counteroffer_report" => provider_counteroffer_report()
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_provider_counteroffer_review:001",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "provider_counteroffer_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.provider_counteroffer_report.rows",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "required_operator_action" => "review_provider_counteroffer",
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "provider_offer_1"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh provider counteroffer review and import summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:provider_counteroffer_summaries:001",
      "source_provider_counteroffer_review_summary" =>
        study_result_fixture("provider_counteroffer_review_summary_v1.json"),
      "source_provider_counteroffer_import_readiness_summary" =>
        study_result_fixture("provider_counteroffer_import_readiness_summary_v1.json")
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:provider_counteroffer_summaries:001",
             "review_count" => 2,
             "provider_counteroffer_review_count" => 2
           } = package

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "candidate_refresh.source_provider_counteroffer_review_summary.review_rows",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "source_provider_counteroffer" => %{
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_review_summary.v1",
                 "counteroffer_review_status" => "review_required"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_provider_counteroffer_review_summary.review_rows")
             )

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "candidate_refresh.source_provider_counteroffer_import_readiness_summary.import_readiness_rows",
             "provider_counteroffer_id" => "provider_offer_1",
             "source_provider_counteroffer" => %{
               "provider_counteroffer_import_status" => "review_required_before_import",
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
                 "import_readiness_status" => "review_required",
                 "provider_counteroffer_import_status_counts" => %{
                   "review_required_before_import" => 1
                 }
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_provider_counteroffer_import_readiness_summary.import_readiness_rows")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact provider counteroffer summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_provider_counteroffer_summaries:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_provider_counteroffer_review_summary" =>
            study_result_fixture("provider_counteroffer_review_summary_v1.json"),
          "provider_counteroffer_import_readiness_summary" =>
            study_result_fixture("provider_counteroffer_import_readiness_summary_v1.json")
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_provider_counteroffer_summaries:001",
             "review_count" => 2,
             "provider_counteroffer_review_count" => 2
           } = package

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_provider_counteroffer_review_summary.review_rows",
             "source_provider_counteroffer" => %{
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_review_summary.v1"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_provider_counteroffer_review_summary.review_rows")
             )

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].provider_counteroffer_import_readiness_summary.import_readiness_rows",
             "source_provider_counteroffer" => %{
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_import_readiness_summary.v1"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].provider_counteroffer_import_readiness_summary.import_readiness_rows")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source provider counteroffer plan-impact summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:provider_counteroffer_plan_impact_review:001",
      "source_provider_counteroffer_plan_impact_summary" => [
        %{
          "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
          "plan_impact_status" => "review_required",
          "affected_station_calendar_entry_ids" => ["contact_original"],
          "affected_provider_entry_ids" => ["provider_offer_2"],
          "impact_counteroffer_ids" => ["offer_2"],
          "impact_rows" => [
            %{
              "id" => "provider_counteroffer:offer_2",
              "provider_counteroffer_id" => "offer_2",
              "provider_counteroffer_status" => "proposed",
              "provider_counteroffer_cost_delta" => 60.0,
              "provider_counteroffer_lock_deadline_s" => 120.0,
              "provider_counteroffer_start_delta_s" => 30.0,
              "provider_counteroffer_end_delta_s" => 30.0,
              "provider_counteroffer_duration_delta_s" => 0.0,
              "reviewable" => true,
              "required_operator_action" => "review_provider_counteroffer",
              "trust_boundary" => "provider_calendar_feed"
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:provider_counteroffer_plan_impact_review:001",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "provider_counteroffer_review",
               "source" =>
                 "candidate_refresh.source_provider_counteroffer_plan_impact_summary[0].impact_rows",
               "provider_counteroffer_id" => "offer_2",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_cost_delta" => 60.0,
               "provider_counteroffer_lock_deadline_s" => 120.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 30.0,
               "required_operator_action" => "review_provider_counteroffer",
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "offer_2",
                 "trust_boundary" => "provider_calendar_feed"
               }
             } = row
           ] = package["rows"]

    assert row["provider_counteroffer_duration_delta_s"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact provider counteroffer plan-impact summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_provider_counteroffer_plan_impact_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provider_counteroffer_plan_impact_summary" => %{
          "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
          "plan_impact_status" => "review_required",
          "impact_rows" => [
            %{
              "id" => "provider_counteroffer:offer_2",
              "provider_counteroffer_id" => "offer_2",
              "provider_counteroffer_status" => "proposed",
              "provider_counteroffer_cost_delta" => 60.0,
              "provider_counteroffer_lock_deadline_s" => 120.0,
              "provider_counteroffer_start_delta_s" => 30.0,
              "provider_counteroffer_end_delta_s" => 30.0,
              "provider_counteroffer_duration_delta_s" => 0.0,
              "reviewable" => true,
              "required_operator_action" => "review_provider_counteroffer",
              "trust_boundary" => "provider_calendar_feed"
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_provider_counteroffer_plan_impact_review:001",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "provider_counteroffer_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.provider_counteroffer_plan_impact_summary.impact_rows",
               "provider_counteroffer_id" => "offer_2",
               "provider_counteroffer_status" => "proposed",
               "required_operator_action" => "review_provider_counteroffer",
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "offer_2",
                 "trust_boundary" => "provider_calendar_feed"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  defp provider_counteroffer_report do
    OrbitalDynamics.provider_counteroffer_report(
      [
        %{
          id: :provider_counteroffer_window,
          provider_id: :ops_calendar,
          ground_station_id: :dss_14,
          starts_at_s: 130.0,
          ends_at_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          counteroffer_cost_delta: 125.5,
          counteroffer_lock_deadline_s: 150.0,
          counteroffer_starts_at_s: 160.0,
          counteroffer_ends_at_s: 210.0
        }
      ],
      source: :cadence_supported_source_fixture
    )
  end

  defp study_result_fixture(filename) do
    ["study_results", filename]
    |> Path.join()
    |> File.read!()
    |> :json.decode()
  end
end
