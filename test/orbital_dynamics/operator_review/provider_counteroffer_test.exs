defmodule OrbitalDynamics.OperatorReview.ProviderCounterofferTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "provider counteroffer report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "provider-counteroffer:report"} =
             OperatorReview.from_provider_counteroffer_report(%{
               id: :"provider-counteroffer:report"
             })

    assert %{"source_artifact_id" => "provider-counteroffer:source"} =
             OperatorReview.from_provider_counteroffer_report(%{
               source: :"provider-counteroffer:source"
             })

    assert %{"source_artifact_id" => "provider_counteroffer_report"} =
             OperatorReview.from_provider_counteroffer_report(%{})
  end

  test "builds review package from standalone provider counteroffer reports" do
    report = provider_counteroffer_report()

    package = OperatorReview.from_provider_counteroffer_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "source_artifact_id" => "cadence_supported_source_fixture",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1,
             "rows" => [row]
           } = package

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" => "provider_counteroffer_report.rows",
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
               "provider_counteroffer_id" => "provider_offer_1"
             }
           } = row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [put_in(row, ["source_provider_counteroffer", "id"], "provider source with spaces")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_provider_counteroffer.id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("provider_counteroffer_status", "accepted")
          |> Map.put("provider_counteroffer_lock_deadline_s", 151.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].provider_counteroffer_status" and
                 &1["message"] ==
                   "must match source_provider_counteroffer.provider_counteroffer_status")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].provider_counteroffer_lock_deadline_s" and
                 &1["message"] ==
                   "must match source_provider_counteroffer.provider_counteroffer_lock_deadline_s")
           )
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
