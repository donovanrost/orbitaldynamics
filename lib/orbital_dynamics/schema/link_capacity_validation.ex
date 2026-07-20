defmodule OrbitalDynamics.Schema.LinkCapacityValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  @report_contract "link_capacity_report.v1"

  def validate_report(issues, path, report) do
    required_fields =
      OrbitalDynamics.Schema.LinkCapacityRegistryContracts.contracts()
      |> OrbitalDynamics.Schema.Registry.fetch!(@report_contract)
      |> Map.fetch!("required_fields")

    issues
    |> require_fields(path, report, required_fields)
    |> OrbitalDynamics.Schema.LinkCapacityReportContracts.validate(path, report)
  end

  def validate_optional_report(issues, nil), do: issues

  def validate_optional_report(issues, %{} = report),
    do: validate_report([], "$", report) ++ issues

  def validate_optional_report(issues, _report),
    do: [error("$.link_capacity_report", "must be an object") | issues]
end
