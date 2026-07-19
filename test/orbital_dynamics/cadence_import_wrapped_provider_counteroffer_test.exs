defmodule OrbitalDynamics.CadenceImportWrappedProviderCounterofferTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema}

  test "candidate refresh import preserves wrapped provider counteroffer reports" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_provider_counteroffer_import:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provider_counteroffer_report" => provider_counteroffer_report()
      }
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_provider_counteroffer_import:001",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_provider_counteroffer" => 1},
             "source_review_type_counts" => %{"provider_counteroffer_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_provider_counteroffer",
               "source_review_type" => "provider_counteroffer_review",
               "source_review_action" => "review_provider_counteroffer",
               "import_status" => "review_required_before_import",
               "approval_status" => "operator_review_required",
               "subject_id" => "provider_offer_1",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_negotiation_state" => "proposed",
               "provider_counteroffer_reason_code" => "provider_shifted_window",
               "provider_counteroffer_cost_delta" => 125.5,
               "provider_counteroffer_lock_deadline_s" => 150.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 40.0,
               "provider_counteroffer_duration_delta_s" => 10.0,
               "required_operator_action" => "review_provider_counteroffer",
               "has_cadence_import" => false,
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_status" => "proposed"
               },
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact.provider_counteroffer_report.rows",
                 "review_type" => "provider_counteroffer_review",
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_lock_deadline_s" => 150.0,
                 "source_provider_counteroffer" => %{
                   "provider_counteroffer_id" => "provider_offer_1"
                 }
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves list-wrapped provider counteroffer reports" do
    report = provider_counteroffer_report()
    source_counteroffer = hd(report["rows"])

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:list_wrapped_provider_counteroffer_import:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "provider_counteroffer_report" => report
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:list_wrapped_provider_counteroffer_import:001",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_provider_counteroffer" => 1},
             "source_review_type_counts" => %{"provider_counteroffer_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_provider_counteroffer",
               "source_review_type" => "provider_counteroffer_review",
               "source_review_action" => "review_provider_counteroffer",
               "import_status" => "review_required_before_import",
               "approval_status" => "operator_review_required",
               "subject_id" => "provider_offer_1",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_negotiation_state" => "proposed",
               "provider_counteroffer_reason_code" => "provider_shifted_window",
               "provider_counteroffer_cost_delta" => 125.5,
               "provider_counteroffer_lock_deadline_s" => 150.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 40.0,
               "provider_counteroffer_duration_delta_s" => 10.0,
               "required_operator_action" => "review_provider_counteroffer",
               "has_cadence_import" => false,
               "source" =>
                 "candidate_refresh.source_result_artifact[0].provider_counteroffer_report.rows",
               "source_provider_counteroffer" => ^source_counteroffer,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].provider_counteroffer_report.rows",
                 "review_type" => "provider_counteroffer_review",
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_lock_deadline_s" => 150.0,
                 "provider_counteroffer_start_delta_s" => 30.0,
                 "provider_counteroffer_end_delta_s" => 40.0,
                 "provider_counteroffer_duration_delta_s" => 10.0,
                 "source_provider_counteroffer" => ^source_counteroffer
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
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
end
