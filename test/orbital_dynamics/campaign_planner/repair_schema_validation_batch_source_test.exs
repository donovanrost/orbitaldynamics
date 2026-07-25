defmodule OrbitalDynamics.CampaignPlanner.RepairSchemaValidationBatchSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical schema-validation batches" do
    batch = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "reports" => [%{"path" => "artifact.json", "report" => %{}}]
    }

    assert RepairSourceReports.schema_validation_batch(%{
             "source_schema_validation_batch_report" => batch
           }) == batch

    assert RepairSourceReports.schema_validation_batch(%{
             "source_schema_validation_batch_report" => [batch]
           }) == batch

    assert RepairSourceReports.schema_validation_batch(%{
             "schema_validation_batch_report" => batch
           }) == batch
  end

  test "returns nil when candidate refresh has no schema-validation batch" do
    assert RepairSourceReports.schema_validation_batch(%{}) == nil
    assert RepairSourceReports.schema_validation_batch(nil) == nil
  end
end
