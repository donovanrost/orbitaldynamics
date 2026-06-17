defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      count_source_report_values: 1,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      numeric_report_count: 2,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1,
      sum_report_count: 2
    ]

  def summary_input_summary([]), do: nil

  def summary_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "validation_safety_case_summary.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &validation_safety_case_evidence_count/1),
      "status_counts" => count_report_field_values(reports, "status"),
      "evidence_status_counts" =>
        reports
        |> Enum.map(&validation_safety_case_evidence_status_counts/1)
        |> merge_count_maps(),
      "input_contract_counts" =>
        reports
        |> Enum.map(&validation_safety_case_input_contract_counts/1)
        |> merge_count_maps(),
      "evidence_refs_by_status" =>
        reports
        |> Enum.map(&validation_safety_case_evidence_refs_by(&1, "status"))
        |> merge_string_list_maps(),
      "evidence_refs_by_contract" =>
        reports
        |> Enum.map(&validation_safety_case_evidence_refs_by(&1, "schema_contract"))
        |> merge_string_list_maps(),
      "accepted_evidence_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_status_count(
            &1,
            "accepted_for_use",
            "accepted_evidence_count"
          )
        ),
      "review_required_evidence_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_status_count(
            &1,
            "review_required",
            "review_required_evidence_count"
          )
        ),
      "blocked_evidence_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_status_count(&1, "blocked", "blocked_evidence_count")
        ),
      "model_accepted_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "model_accepted_count")
        ),
      "model_review_required_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "model_review_required_count")
        ),
      "model_blocked_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "model_blocked_count")
        ),
      "unknown_model_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "unknown_model_count")
        ),
      "readiness_review_required_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "readiness_review_required_count")
        ),
      "readiness_blocked_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "readiness_blocked_count")
        ),
      "ready_for_import_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "ready_for_import_count")
        ),
      "quality_gate_review_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "quality_gate_review_count")
        ),
      "quality_gate_blocked_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "quality_gate_blocked_count")
        ),
      "schema_error_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "schema_error_count")
        ),
      "schema_warning_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "schema_warning_count")
        ),
      "schema_validation_report_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "schema_validation_report_count")
        ),
      "schema_validation_failed_report_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "schema_validation_failed_report_count")
        ),
      "fixture_passed_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "fixture_passed_count")
        ),
      "fixture_failed_count" =>
        sum_report_count(
          reports,
          &validation_safety_case_evidence_field_sum(&1, "fixture_failed_count")
        ),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
    |> compact_map()
  end

  defp validation_safety_case_evidence_count(report) do
    case validation_safety_case_evidence_rows(report) do
      [] ->
        validation_safety_case_summary_evidence_count(report, "evidence_count")

      rows ->
        length(rows)
    end
  end

  defp validation_safety_case_evidence_status_counts(report) do
    case validation_safety_case_evidence_rows(report) do
      [] ->
        Map.get(report, "evidence_status_counts")

      rows ->
        rows
        |> Enum.map(&validation_safety_case_evidence_status/1)
        |> count_source_report_values()
    end
  end

  defp validation_safety_case_input_contract_counts(report) do
    case validation_safety_case_evidence_rows(report) do
      [] ->
        case Map.get(report, "input_contract_counts") do
          %{} = counts ->
            counts

          _counts ->
            report
            |> Map.get("input_contracts")
            |> list_value()
            |> count_source_report_values()
        end

      rows ->
        rows
        |> Enum.map(&validation_safety_case_evidence_contract/1)
        |> count_source_report_values()
    end
  end

  defp validation_safety_case_evidence_refs_by(report, field) do
    case validation_safety_case_evidence_rows(report) do
      [] ->
        Map.get(report, validation_safety_case_evidence_refs_field(field))

      rows ->
        rows
        |> Enum.reduce(%{}, fn row, refs_by_field ->
          value = validation_safety_case_evidence_ref_group_value(row, field)
          evidence_ref = validation_safety_case_evidence_ref(row)

          if value in [nil, ""] or evidence_ref in [nil, ""] do
            refs_by_field
          else
            Map.update(refs_by_field, to_string(value), [to_string(evidence_ref)], fn refs ->
              [to_string(evidence_ref) | refs]
            end)
          end
        end)
        |> Map.new(fn {value, refs} -> {value, refs |> Enum.uniq() |> Enum.sort()} end)
        |> compact_map()
    end
  end

  defp validation_safety_case_evidence_refs_field("schema_contract"),
    do: "evidence_refs_by_contract"

  defp validation_safety_case_evidence_refs_field(field), do: "evidence_refs_by_#{field}"

  defp validation_safety_case_evidence_status_count(report, status, fallback_field) do
    case validation_safety_case_evidence_rows(report) do
      [] ->
        validation_safety_case_summary_evidence_status_count(report, status, fallback_field)

      rows ->
        Enum.count(rows, &(validation_safety_case_evidence_status(&1) == status))
    end
  end

  defp validation_safety_case_summary_evidence_count(summary, fallback_field) do
    case validation_safety_case_summary_evidence_map_count(summary) do
      {:ok, count} -> count
      :error -> summary_integer(summary, fallback_field)
    end
  end

  defp validation_safety_case_summary_evidence_status_count(summary, status, fallback_field) do
    cond do
      is_map(Map.get(summary, "evidence_status_counts")) ->
        summary
        |> Map.get("evidence_status_counts")
        |> summary_integer(status)

      is_map(Map.get(summary, "evidence_refs_by_status")) ->
        summary
        |> Map.get("evidence_refs_by_status")
        |> Map.get(status, [])
        |> list_value()
        |> length()

      true ->
        summary_integer(summary, fallback_field)
    end
  end

  defp validation_safety_case_summary_evidence_map_count(summary) do
    [
      "evidence_status_counts",
      "evidence_refs_by_status",
      "evidence_refs_by_contract",
      "input_contract_counts"
    ]
    |> Enum.find_value(:error, fn field ->
      case Map.get(summary, field) do
        %{} = map -> {:ok, validation_safety_case_summary_map_count(field, map)}
        _map -> false
      end
    end)
  end

  defp validation_safety_case_summary_map_count("evidence_status_counts", counts) do
    counts
    |> Map.values()
    |> Enum.map(&summary_integer(%{"count" => &1}, "count"))
    |> Enum.sum()
  end

  defp validation_safety_case_summary_map_count("input_contract_counts", counts) do
    validation_safety_case_summary_map_count("evidence_status_counts", counts)
  end

  defp validation_safety_case_summary_map_count(_field, refs_by_key) do
    refs_by_key
    |> Enum.flat_map(fn {_key, refs} -> list_value(refs) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp validation_safety_case_evidence_field_sum(report, field) do
    case validation_safety_case_evidence_rows(report) do
      [] ->
        numeric_report_count(report, field)

      rows ->
        sum_report_count(rows, &numeric_report_count(&1, field))
    end
  end

  defp validation_safety_case_evidence_rows(report) do
    report
    |> Map.get("evidence", [])
    |> Enum.map(&stringify_keys/1)
  end

  defp validation_safety_case_evidence_status(row) do
    Map.get(row, "status") || Map.get(row, "evidence_status")
  end

  defp validation_safety_case_evidence_contract(row) do
    Map.get(row, "schema_contract") || Map.get(row, "input_contract")
  end

  defp validation_safety_case_evidence_ref(row) do
    Map.get(row, "evidence_ref") || Map.get(row, "ref")
  end

  defp validation_safety_case_evidence_ref_group_value(row, "schema_contract") do
    validation_safety_case_evidence_contract(row)
  end

  defp validation_safety_case_evidence_ref_group_value(row, field), do: Map.get(row, field)

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(value) do
          {count, ""} -> count
          _error -> 0
        end

      _value ->
        0
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

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
