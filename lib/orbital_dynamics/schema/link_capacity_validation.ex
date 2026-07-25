defmodule OrbitalDynamics.Schema.LinkCapacityValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  @report_contract "link_capacity_report.v1"
  @summary_contract "link_capacity_summary.v1"
  @relay_data_path_summary "relay_data_path_summary.v1"

  def validate_report(issues, path, report) do
    issues
    |> require_fields(path, report, required_fields(@report_contract))
    |> OrbitalDynamics.Schema.LinkCapacityReportContracts.validate(path, report)
  end

  def validate_summary(issues, path, summary) do
    issues
    |> require_fields(path, summary, required_fields(@summary_contract))
    |> OrbitalDynamics.Schema.LinkCapacitySummaryContracts.validate_summary(path, summary)
  end

  def validate_relay_data_path_summary(issues, path, summary) do
    issues
    |> require_fields(path, summary, required_fields(@relay_data_path_summary))
    |> OrbitalDynamics.Schema.RelayDataPathSummaryContracts.validate_summary(path, summary)
  end

  def validate_optional_report(issues, nil), do: issues

  def validate_optional_report(issues, %{} = report),
    do: validate_report([], "$", report) ++ issues

  def validate_optional_report(issues, _report),
    do: [error("$.link_capacity_report", "must be an object") | issues]

  def validate_optional_report_at(issues, _path, nil), do: issues

  def validate_optional_report_at(issues, path, %{} = report),
    do: validate_report(issues, path, report)

  def validate_optional_report_at(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_summary_at(issues, _path, nil), do: issues

  def validate_optional_summary_at(issues, path, %{} = summary),
    do: validate_summary(issues, path, summary)

  def validate_optional_summary_at(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_relay_data_path_summary_at(issues, _path, nil), do: issues

  def validate_optional_relay_data_path_summary_at(issues, path, %{} = summary),
    do: validate_relay_data_path_summary(issues, path, summary)

  def validate_optional_relay_data_path_summary_at(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp required_fields(contract_name) do
    [
      OrbitalDynamics.Schema.LinkCapacityRegistryContracts,
      OrbitalDynamics.Schema.RelayDataPathRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
