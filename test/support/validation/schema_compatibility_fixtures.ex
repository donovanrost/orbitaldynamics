defmodule OrbitalDynamics.Validation.SchemaCompatibilityFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def schema_validation_report_fixture_observations do
    "schema_validation_report.v1"
    |> Validation.artifact_observations(schema_validation_report_fixture())
  end

  def schema_validation_report_fixture do
    read_json!("study_results/schema_validation_report_v1.json")
  end

  def schema_validation_batch_report_fixture_observations do
    "schema_validation_batch_report.v1"
    |> Validation.artifact_observations(schema_validation_batch_report_fixture())
  end

  def schema_validation_batch_report_fixture do
    read_json!("study_results/schema_validation_batch_report_v1.json")
  end

  def schema_migration_report_fixture_observations do
    "schema_migration_report.v1"
    |> Validation.artifact_observations(schema_migration_report_fixture())
  end

  def schema_migration_report_fixture do
    read_json!("study_results/schema_migration_report_v1.json")
  end

  def schema_migration_future_contract_fixture_observations do
    "schema_migration_report.v1"
    |> Validation.artifact_observations(schema_migration_future_contract_fixture())
  end

  def schema_migration_future_contract_fixture do
    Validation.schema_migration_report(
      future_contracts: [
        %{
          "schema_contract" => "campaign_plan.v2",
          "artifact_family" => "campaign_plan",
          "schema_version" => 2,
          "required_field_count" => 4,
          "optional_field_count" => 2,
          "nested_contract_count" => 1
        }
      ]
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
