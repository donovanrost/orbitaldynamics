defmodule OrbitalDynamics.OperatorReview.FilterReview do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.OperatorReview.Suppression

  @schema_contract "operator_review_package.v1"

  def contact_package(report) do
    {rows, source_artifact_id, provenance} = contact_package_input(report)

    build_package(rows, "contact_filter_report.v1", source_artifact_id, provenance)
  end

  def resource_package(report) do
    {rows, source_artifact_id, provenance} = resource_package_input(report)

    build_package(rows, "resource_filter_report.v1", source_artifact_id, provenance)
  end

  def contact_package_input(report) do
    report = stringify_keys(report || %{})

    {
      contact_rows(report),
      Map.get(report, "id") || Map.get(report, "source") || "contact_filter_report",
      Map.get(report, "provenance", %{})
    }
  end

  def resource_package_input(report) do
    report = stringify_keys(report || %{})

    {
      resource_rows(report),
      Map.get(report, "id") || Map.get(report, "source") || "resource_filter_report",
      Map.get(report, "provenance", %{})
    }
  end

  def contact_rows(report, source \\ "contact_filter_report") do
    source_contact_filter_report_rows(report, source)
  end

  def resource_rows(report, source \\ "resource_filter_report") do
    source_resource_filter_report_rows(report, source)
  end

  def candidate_refresh_rows(artifact) do
    candidate_refresh_contact_filter_rows(artifact) ++
      candidate_refresh_resource_filter_rows(artifact)
  end

  defp candidate_refresh_contact_filter_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_contact_filter_report",
         artifact["source_contact_filter_report"]},
        {"candidate_refresh.contact_filter_report", artifact["contact_filter_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_contact_filter_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_contact_filter_rows(artifact)
  end

  defp source_contact_filter_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_contact_filter_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_contact_filter_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("suppressed_candidates", [])
    |> Suppression.contact_rows("#{source}.suppressed_candidates")
  end

  defp source_contact_filter_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_contact_filter_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_contact_filter_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_contact_filter_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_contact_filter_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_contact_filter_rows(
         %{"schema_contract" => "contact_filter_report.v1"} = report,
         source
       ) do
    source_contact_filter_report_rows(report, source)
  end

  defp result_artifact_contact_filter_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_filter_report", artifact["source_contact_filter_report"]},
      {"#{source}.contact_filter_report", artifact["contact_filter_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_contact_filter_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_contact_filter_rows(_artifact, _source), do: []

  defp candidate_refresh_resource_filter_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_resource_filter_report",
         artifact["source_resource_filter_report"]},
        {"candidate_refresh.resource_filter_report", artifact["resource_filter_report"]},
        {"candidate_refresh.source_resource_filter_summary",
         artifact["source_resource_filter_summary"]},
        {"candidate_refresh.resource_filter_summary", artifact["resource_filter_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_resource_filter_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_resource_filter_rows(artifact)
  end

  defp source_resource_filter_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_resource_filter_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_resource_filter_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    if resource_filter_summary?(report) do
      source_resource_filter_summary_rows(report, source)
    else
      Suppression.invalid_resource_summary_rows(
        Map.get(report, "invalid_resource_summary_inputs", []),
        "#{source}.invalid_resource_summary_inputs"
      ) ++
        Suppression.resource_rows(
          Map.get(report, "suppressed_candidates", []),
          "#{source}.suppressed_candidates"
        )
    end
  end

  defp source_resource_filter_report_rows(_report, _source), do: []

  defp source_resource_filter_summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)
    summary_context = resource_filter_summary_context(summary)

    invalid_summary_rows =
      summary
      |> Map.get("invalid_resource_summary_inputs", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&put_resource_filter_summary_context(&1, summary, summary_context))
      |> Suppression.invalid_resource_summary_rows("#{source}.invalid_resource_summary_inputs")

    suppression_rows =
      summary
      |> Map.get("review_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&put_resource_filter_summary_context(&1, summary, summary_context))
      |> Suppression.resource_rows("#{source}.review_rows")

    invalid_summary_rows ++ suppression_rows
  end

  defp resource_filter_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "input_candidate_count" => summary["input_candidate_count"],
      "kept_candidate_count" => summary["kept_candidate_count"],
      "suppressed_candidate_count" => summary["suppressed_candidate_count"],
      "invalid_resource_summary_input_count" => summary["invalid_resource_summary_input_count"],
      "suppression_review_status" => summary["suppression_review_status"],
      "suppressed_candidate_ids" => summary["suppressed_candidate_ids"],
      "invalid_resource_summary_input_ids" => summary["invalid_resource_summary_input_ids"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp put_resource_filter_summary_context(row, summary, summary_context) do
    row
    |> Map.put("source_resource_filter_summary", summary_context)
    |> Map.put("source_summary_model", summary["model"])
    |> Map.put("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put("source_artifact_type", summary["source_artifact_type"])
    |> Map.put("schema_contract", summary["schema_contract"])
    |> compact_map()
  end

  defp resource_filter_summary?(%{"schema_contract" => "resource_filter_summary.v1"}),
    do: true

  defp resource_filter_summary?(_report), do: false

  defp candidate_refresh_result_artifact_resource_filter_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_resource_filter_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_resource_filter_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_resource_filter_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_resource_filter_rows(
         %{"schema_contract" => "resource_filter_report.v1"} = report,
         source
       ) do
    source_resource_filter_report_rows(report, source)
  end

  defp result_artifact_resource_filter_rows(
         %{"schema_contract" => "resource_filter_summary.v1"} = summary,
         source
       ) do
    source_resource_filter_report_rows(summary, source)
  end

  defp result_artifact_resource_filter_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_resource_filter_report", artifact["source_resource_filter_report"]},
      {"#{source}.resource_filter_report", artifact["resource_filter_report"]},
      {"#{source}.source_resource_filter_summary", artifact["source_resource_filter_summary"]},
      {"#{source}.resource_filter_summary", artifact["resource_filter_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_resource_filter_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_resource_filter_rows(_artifact, _source), do: []

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
