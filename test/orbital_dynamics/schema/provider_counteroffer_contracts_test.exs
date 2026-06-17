defmodule OrbitalDynamics.Schema.ProviderCounterofferContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates standalone provider counteroffer report contracts" do
    report =
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
            counteroffer_starts_at_s: 130.0,
            counteroffer_ends_at_s: 170.0
          }
        ],
        source: :schema_test_provider_counteroffers
      )

    assert {:ok, %{"schema_contract" => "provider_counteroffer_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 125.5,
             "counteroffer_lock_deadline_count" => 1,
             "earliest_counteroffer_lock_deadline_s" => 150.0
           } = report

    invalid_count = Map.put(report, "counteroffer_count", 2)

    assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             invalid_count_report["errors"],
             &(&1["path"] == "$.counteroffer_count")
           )

    for field <- [
          "counteroffer_status_counts",
          "counteroffer_negotiation_state_counts",
          "required_operator_action_counts"
        ] do
      key =
        report
        |> Map.fetch!(field)
        |> Map.keys()
        |> List.first()

      stale_count_map =
        update_in(report, [field, key], &(&1 + 1))

      assert {:error, stale_count_map_report} = Schema.validate_artifact(stale_count_map)

      assert Enum.any?(
               stale_count_map_report["errors"],
               &(&1["path"] == "$.#{field}")
             )
    end

    invalid_action =
      put_in(report, ["rows", Access.at(0), "required_operator_action"], "accept_counteroffer")

    assert {:error, invalid_action_report} = Schema.validate_artifact(invalid_action)

    assert Enum.any?(
             invalid_action_report["errors"],
             &(&1["path"] == "$.rows[0].required_operator_action")
           )

    assert {:ok, schema} = Schema.json_schema("provider_counteroffer_report.v1")

    assert get_in(schema, ["properties", "counteroffer_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "counteroffer_cost_delta_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "counteroffer_cost_delta_total"]) == %{
             "type" => "number"
           }

    assert get_in(schema, ["properties", "counteroffer_lock_deadline_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "earliest_counteroffer_lock_deadline_s"]) == %{
             "type" => "number"
           }

    assert get_in(schema, [
             "properties",
             "required_operator_action_counts",
             "propertyNames",
             "enum"
           ]) ==
             OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_actions

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert get_in(row_schema, ["properties", "provider_counteroffer_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(row_schema, ["properties", "provider_counteroffer_cost_delta", "type"]) ==
             "number"
  end
end
