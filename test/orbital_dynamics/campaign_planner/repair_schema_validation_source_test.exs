defmodule OrbitalDynamics.CampaignPlanner.RepairSchemaValidationSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical schema-validation reports" do
    report = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "fail",
      "errors" => [%{"path" => "$.plan_id", "message" => "is required"}]
    }

    assert RepairSourceReports.schema_validation(%{
             "source_schema_validation_report" => report
           }) == report

    assert RepairSourceReports.schema_validation(%{
             "source_schema_validation_report" => [report]
           }) == report

    assert RepairSourceReports.schema_validation(%{"schema_validation_report" => report}) ==
             report
  end

  test "returns nil when candidate refresh has no schema-validation report" do
    assert RepairSourceReports.schema_validation(%{}) == nil
    assert RepairSourceReports.schema_validation(nil) == nil
  end
end
