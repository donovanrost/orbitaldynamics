defmodule OrbitalDynamics.OperatorReview.ProviderCounteroffer do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "provider_counteroffer_report.v1", source_artifact_id, provenance)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      source_report_rows(report, "provider_counteroffer_report"),
      Map.get(report, "id") || Map.get(report, "source") || "provider_counteroffer_report",
      Map.get(report, "provenance", %{})
    }
  end

  def rows(rows, source) do
    rows
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&review_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      counteroffer_id = row["provider_counteroffer_id"] || "provider_counteroffer:#{index}"
      action = row["required_operator_action"] || "review_provider_counteroffer"
      status = row["provider_counteroffer_status"] || "unknown"
      negotiation_state = row["provider_counteroffer_negotiation_state"] || "unknown"

      %{
        "id" => review_id(["provider_counteroffer_review", counteroffer_id, index]),
        "review_type" => "provider_counteroffer_review",
        "source" => source,
        "subject_id" => counteroffer_id,
        "provider_counteroffer_id" => counteroffer_id,
        "provider_counteroffer_status" => status,
        "provider_counteroffer_negotiation_state" => negotiation_state,
        "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" =>
          row["provider_counteroffer_start_delta_s"] ||
            numeric_delta(row["provider_counteroffer_starts_at_s"], row["starts_at_s"]),
        "provider_counteroffer_end_delta_s" =>
          row["provider_counteroffer_end_delta_s"] ||
            numeric_delta(row["provider_counteroffer_ends_at_s"], row["ends_at_s"]),
        "provider_counteroffer_duration_delta_s" =>
          row["provider_counteroffer_duration_delta_s"] ||
            provider_counteroffer_duration_delta(row),
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_availability" => row["station_availability"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => "operator_review_required",
        "cadence_import_status" => "present",
        "reason" => review_reason(counteroffer_id, status),
        "source_provider_counteroffer" => row
      }
      |> compact_map()
    end)
  end

  def plan_impact_summary_rows(summary_or_summaries, source) do
    source_summary_rows(summary_or_summaries, source, "impact_rows")
  end

  def import_readiness_summary_rows(summary_or_summaries, source) do
    source_summary_rows(summary_or_summaries, source, "import_readiness_rows")
  end

  defp review_row?(row) do
    row["reviewable"] == true and
      row["required_operator_action"] == "review_provider_counteroffer"
  end

  defp review_reason(counteroffer_id, status) do
    "provider counteroffer #{counteroffer_id} requires review with status #{status}"
  end

  def candidate_refresh_rows(artifact) do
    report_rows =
      [
        {"candidate_refresh.source_provider_counteroffer_report",
         artifact["source_provider_counteroffer_report"]},
        {"candidate_refresh.provider_counteroffer_report",
         artifact["provider_counteroffer_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    plan_impact_rows =
      [
        {"candidate_refresh.source_provider_counteroffer_review_summary",
         artifact["source_provider_counteroffer_review_summary"], "review_rows"},
        {"candidate_refresh.provider_counteroffer_review_summary",
         artifact["provider_counteroffer_review_summary"], "review_rows"},
        {"candidate_refresh.source_provider_counteroffer_import_readiness_summary",
         artifact["source_provider_counteroffer_import_readiness_summary"],
         "import_readiness_rows"},
        {"candidate_refresh.provider_counteroffer_import_readiness_summary",
         artifact["provider_counteroffer_import_readiness_summary"], "import_readiness_rows"},
        {"candidate_refresh.source_provider_counteroffer_plan_impact_summary",
         artifact["source_provider_counteroffer_plan_impact_summary"], "impact_rows"},
        {"candidate_refresh.provider_counteroffer_plan_impact_summary",
         artifact["provider_counteroffer_plan_impact_summary"], "impact_rows"}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries, row_key} ->
        source_summary_rows(summary_or_summaries, source, row_key)
      end)

    report_rows ++
      plan_impact_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  defp source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> rows("#{source}.rows")
  end

  defp source_report_rows(_report, _source), do: []

  defp source_summary_rows(summaries, source, row_key)
       when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_summary_rows(summary, "#{source}[#{index}]", row_key)
    end)
  end

  defp source_summary_rows(%{} = summary, source, row_key) do
    summary = stringify_keys(summary)

    summary
    |> Map.get(row_key, [])
    |> Enum.map(&summary_row(&1, summary))
    |> rows("#{source}.#{row_key}")
  end

  defp source_summary_rows(_summary, _source, _row_key), do: []

  defp summary_row(%{} = row, %{} = summary) do
    row
    |> stringify_keys()
    |> Map.put(
      "source_provider_counteroffer_summary",
      summary_context(summary)
    )
  end

  defp summary_row(row, _summary), do: row

  defp summary_context(%{} = summary) do
    summary
    |> Map.take([
      "model",
      "schema_contract",
      "source",
      "source_artifact_type",
      "source_artifact_id",
      "counteroffer_count",
      "reviewable_count",
      "review_counteroffer_ids",
      "counteroffer_review_status",
      "import_readiness_status",
      "import_classification",
      "provider_counteroffer_import_status_counts",
      "required_import_action_counts",
      "plan_impact_status",
      "counteroffer_lock_deadline_status_counts",
      "counteroffer_ids_by_lock_deadline_status",
      "assumptions"
    ])
    |> compact_map()
  end

  defp candidate_refresh_result_artifact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "provider_counteroffer_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {:report, "#{source}.source_provider_counteroffer_report",
       artifact["source_provider_counteroffer_report"]},
      {:report, "#{source}.provider_counteroffer_report",
       artifact["provider_counteroffer_report"]},
      {:summary, "#{source}.source_provider_counteroffer_review_summary",
       artifact["source_provider_counteroffer_review_summary"], "review_rows"},
      {:summary, "#{source}.provider_counteroffer_review_summary",
       artifact["provider_counteroffer_review_summary"], "review_rows"},
      {:summary, "#{source}.source_provider_counteroffer_import_readiness_summary",
       artifact["source_provider_counteroffer_import_readiness_summary"],
       "import_readiness_rows"},
      {:summary, "#{source}.provider_counteroffer_import_readiness_summary",
       artifact["provider_counteroffer_import_readiness_summary"], "import_readiness_rows"},
      {:summary, "#{source}.source_provider_counteroffer_plan_impact_summary",
       artifact["source_provider_counteroffer_plan_impact_summary"], "impact_rows"},
      {:summary, "#{source}.provider_counteroffer_plan_impact_summary",
       artifact["provider_counteroffer_plan_impact_summary"], "impact_rows"}
    ]
    |> Enum.flat_map(fn
      {:report, report_source, report_or_reports} ->
        source_report_rows(report_or_reports, report_source)

      {:summary, summary_source, summary_or_summaries, row_key} ->
        source_summary_rows(
          summary_or_summaries,
          summary_source,
          row_key
        )
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp provider_counteroffer_duration_delta(row) do
    with start when is_number(start) <- numeric_or_nil(row["starts_at_s"]),
         finish when is_number(finish) <- numeric_or_nil(row["ends_at_s"]),
         counter_start when is_number(counter_start) <-
           numeric_or_nil(row["provider_counteroffer_starts_at_s"]),
         counter_finish when is_number(counter_finish) <-
           numeric_or_nil(row["provider_counteroffer_ends_at_s"]) do
      counter_finish - counter_start - (finish - start)
    else
      _value -> nil
    end
  end

  defp numeric_delta(left, right) do
    with left when is_number(left) <- numeric_or_nil(left),
         right when is_number(right) <- numeric_or_nil(right) do
      left - right
    else
      _value -> nil
    end
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

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
