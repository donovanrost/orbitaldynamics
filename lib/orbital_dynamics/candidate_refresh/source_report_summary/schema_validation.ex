defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.SchemaValidation do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      count_source_report_values: 1,
      merge_count_maps: 1,
      numeric_report_count: 2,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1,
      sum_report_count: 2
    ]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "schema_validation_report.v1",
      "count" => length(sources),
      "row_count" => length(sources),
      "status_counts" => count_report_field_values(reports, "status"),
      "validated_contract_counts" => count_report_field_values(reports, "validated_contract"),
      "validation_mode_counts" => count_report_field_values(reports, "validation_mode"),
      "error_count" => sum_report_count(reports, &schema_validation_error_count/1),
      "warning_count" => sum_report_count(reports, &schema_validation_warning_count/1),
      "remediation_count" => sum_report_count(reports, &schema_validation_remediation_count/1),
      "remediation_action_counts" =>
        reports
        |> Enum.map(&schema_validation_remediation_field_counts(&1, "action"))
        |> merge_count_maps(),
      "remediation_category_counts" =>
        reports
        |> Enum.map(&schema_validation_remediation_field_counts(&1, "category"))
        |> merge_count_maps(),
      "remediation_path_counts" =>
        reports
        |> Enum.map(&schema_validation_remediation_field_counts(&1, "path"))
        |> merge_count_maps(),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
    |> compact_map()
  end

  defp schema_validation_error_count(report) do
    case numeric_report_count(report, "error_count") do
      0 -> length(Map.get(report, "errors", []))
      count -> count
    end
  end

  defp schema_validation_warning_count(report) do
    case numeric_report_count(report, "warning_count") do
      0 -> length(Map.get(report, "warnings", []))
      count -> count
    end
  end

  defp schema_validation_remediation_count(report) do
    case numeric_report_count(report, "remediation_count") do
      0 -> length(Map.get(report, "remediation", []))
      count -> count
    end
  end

  defp schema_validation_remediation_field_counts(report, field) do
    report
    |> Map.get("remediation", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&Map.get(&1, field))
    |> count_source_report_values()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
