defmodule OrbitalDynamics.CampaignPlanner.RepairValidationRecordsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every validation record in source order" do
    first = %{
      schema_contract: "validation_record.v1",
      id: "propagator.two_body",
      nested: %{evidence_kind: "unit_test"}
    }

    second = %{
      "schema_contract" => "validation_record.v1",
      "id" => "event.access_windows"
    }

    assert RepairSourceReports.validation_records(%{
             validation_records: [first, "invalid", second]
           }) == [
             %{
               "schema_contract" => "validation_record.v1",
               "id" => "propagator.two_body",
               "nested" => %{"evidence_kind" => "unit_test"}
             },
             second
           ]
  end

  test "returns an empty list without validation records" do
    assert RepairSourceReports.validation_records(%{}) == []
    assert RepairSourceReports.validation_records(nil) == []
  end
end
