defmodule OrbitalDynamics.OperatorReview.StationReservation do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.OperatorReview.StationCalendar

  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    build_package(rows, "station_reservation_report.v1", source_artifact_id, provenance)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      report_rows(report),
      Map.get(report, "id") || Map.get(report, "source") || "station_reservation_report",
      Map.get(report, "provenance", %{})
    }
  end

  def report_rows(report, source \\ "station_reservation_report") do
    report = stringify_keys(report)

    rows(Map.get(report, "affected_contacts", []), "#{source}.affected_contacts") ++
      provider_contention_rows(
        Map.get(report, "provider_calendar_contention_groups", []),
        "#{source}.provider_calendar_contention_groups"
      )
  end

  def rows(
        rows,
        source \\ "station_reservation_report.affected_contacts"
      ) do
    rows
    |> StationCalendar.rows(source)
    |> Enum.map(fn row ->
      row
      |> Map.put(
        "id",
        review_id([
          "station_reservation",
          row["contact_id"] || row["subject_id"],
          row["station_reservation_id"]
        ])
      )
      |> Map.put("review_type", "station_reservation_review")
      |> Map.put("source", source)
      |> Map.put_new("required_operator_action", "review_station_reservation_overlap")
      |> Map.put_new("action", "review_station_reservation_overlap")
      |> Map.put("source_station_reservation", row["source_station_calendar_review"])
    end)
  end

  def provider_contention_rows(
        groups,
        source \\ "station_reservation_report.provider_calendar_contention_groups"
      ) do
    groups
    |> StationCalendar.provider_contention_rows(source)
    |> Enum.map(fn row ->
      row
      |> Map.put(
        "id",
        review_id(["station_reservation_provider_contention", row["subject_id"]])
      )
      |> Map.put("review_type", "station_reservation_review")
      |> Map.put("source", source)
      |> Map.put_new("required_operator_action", "review_station_provider_contention")
      |> Map.put_new("action", "review_station_provider_contention")
      |> Map.put("source_station_reservation", row["source_station_calendar_provider_contention"])
    end)
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_station_reservation_report",
         artifact["source_station_reservation_report"]},
        {"candidate_refresh.station_reservation_report", artifact["station_reservation_report"]},
        {"candidate_refresh.source_station_reservation_review_summary",
         artifact["source_station_reservation_review_summary"]},
        {"candidate_refresh.station_reservation_review_summary",
         artifact["station_reservation_review_summary"]},
        {"candidate_refresh.source_station_reservation_hold_summary",
         artifact["source_station_reservation_hold_summary"]},
        {"candidate_refresh.station_reservation_hold_summary",
         artifact["station_reservation_hold_summary"]},
        {"candidate_refresh.source_station_reservation_hold_import_readiness_summary",
         artifact["source_station_reservation_hold_import_readiness_summary"]},
        {"candidate_refresh.station_reservation_hold_import_readiness_summary",
         artifact["station_reservation_hold_import_readiness_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_station_reservation_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def source_report_rows(reports, source),
    do: source_station_reservation_report_rows(reports, source)

  defp source_station_reservation_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_station_reservation_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_station_reservation_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    cond do
      station_reservation_review_summary?(report) ->
        source_station_reservation_report_rows_from_summary(report, source)

      station_reservation_hold_summary?(report) ->
        source_station_reservation_report_rows_from_summary(report, source)

      station_reservation_hold_import_readiness_summary?(report) ->
        source_station_reservation_report_rows_from_hold_import_readiness_summary(report, source)

      station_reservation_report?(report) ->
        rows(
          Map.get(report, "affected_contacts", []),
          "#{source}.affected_contacts"
        ) ++
          provider_contention_rows(
            Map.get(report, "provider_calendar_contention_groups", []),
            "#{source}.provider_calendar_contention_groups"
          )

      true ->
        []
    end
  end

  defp source_station_reservation_report_rows(_report, _source), do: []

  defp source_station_reservation_report_rows_from_summary(%{} = summary, source) do
    summary = stringify_keys(summary)

    {affected_rows, provider_rows} =
      summary
      |> Map.get("review_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&station_reservation_summary_row(&1, summary))
      |> Enum.split_with(fn row ->
        row["reservation_review_row_type"] != "provider_calendar_contention_group"
      end)

    rows(
      affected_rows,
      "#{source}.review_rows.affected_contacts"
    ) ++
      provider_contention_rows(
        provider_rows,
        "#{source}.review_rows.provider_calendar_contention_groups"
      )
  end

  defp station_reservation_summary_row(%{} = row, %{} = summary) do
    reservation_ids = Map.get(row, "reservation_ids", [])
    reservation_statuses = Map.get(row, "reservation_statuses", [])
    reserved_by = Map.get(row, "reserved_by", [])
    reservation_expires_at_s = Map.get(row, "reservation_expires_at_s", [])

    summary_context =
      %{
        "model" => summary["model"],
        "schema_contract" => summary["schema_contract"],
        "source_artifact_type" => summary["source_artifact_type"],
        "source" => summary["source"],
        "reservation_review_status" => summary["reservation_review_status"],
        "reservation_hold_count" => summary["reservation_hold_count"],
        "reservation_hold_review_status" => summary["reservation_hold_review_status"],
        "reservation_hold_expiration_count" => summary["reservation_hold_expiration_count"],
        "earliest_reservation_hold_expires_at_s" =>
          summary["earliest_reservation_hold_expires_at_s"],
        "reservation_hold_expiration_status_counts" =>
          summary["reservation_hold_expiration_status_counts"],
        "reservation_hold_status_counts" => summary["reservation_hold_status_counts"],
        "reservation_hold_ids" => summary["reservation_hold_ids"],
        "reservation_hold_ids_by_expiration_status" =>
          summary["reservation_hold_ids_by_expiration_status"],
        "reservation_hold_ids_by_status" => summary["reservation_hold_ids_by_status"],
        "reservation_hold_ids_by_reserved_by" => summary["reservation_hold_ids_by_reserved_by"],
        "reservation_hold_ids_by_row_type" => summary["reservation_hold_ids_by_row_type"],
        "reservation_hold_contact_ids_by_expiration_status" =>
          summary["reservation_hold_contact_ids_by_expiration_status"],
        "review_contact_ids" => summary["review_contact_ids"],
        "assumptions" => summary["assumptions"]
      }
      |> compact_map()

    row
    |> Map.put_new("id", station_reservation_summary_row_id(row))
    |> Map.put_new("station_calendar_reservation_ids", reservation_ids)
    |> Map.put_new("station_calendar_reservation_statuses", reservation_statuses)
    |> Map.put_new("station_calendar_reserved_by", reserved_by)
    |> Map.put_new("station_calendar_reservation_expires_at_s", reservation_expires_at_s)
    |> Map.put_new("station_calendar_reservation_overlap_count", length(reservation_ids))
    |> Map.put_new("station_reservation_id", List.first(reservation_ids))
    |> Map.put_new("station_reserved_by", List.first(reserved_by))
    |> Map.put_new("station_reservation_status", List.first(reservation_statuses))
    |> Map.put_new("station_reservation_expires_at_s", List.first(reservation_expires_at_s))
    |> Map.put("station_reservation_summary_model", summary["model"])
    |> Map.put("station_reservation_summary_schema_contract", summary["schema_contract"])
    |> Map.put("station_reservation_summary_source", summary["source"])
    |> Map.put(
      "station_reservation_summary_source_artifact_type",
      summary["source_artifact_type"]
    )
    |> Map.put("station_reservation_hold_count", summary["reservation_hold_count"])
    |> Map.put("station_reservation_hold_ids", summary["reservation_hold_ids"])
    |> Map.put(
      "station_reservation_hold_contact_ids_by_expiration_status",
      summary["reservation_hold_contact_ids_by_expiration_status"]
    )
    |> Map.put("source_station_reservation_summary", summary_context)
    |> compact_map()
  end

  defp station_reservation_summary_row_id(%{} = row) do
    review_id([
      "station_reservation_summary",
      row["reservation_review_row_type"],
      row["contact_id"] || row["ground_station_id"],
      List.first(List.wrap(row["reservation_ids"]))
    ])
  end

  defp source_station_reservation_report_rows_from_hold_import_readiness_summary(
         %{} = summary,
         source
       ) do
    summary = stringify_keys(summary)

    {affected_rows, provider_rows} =
      summary
      |> Map.get("import_readiness_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&station_reservation_hold_import_readiness_row(&1, summary))
      |> Enum.split_with(fn row ->
        row["reservation_review_row_type"] != "provider_calendar_contention_group"
      end)

    rows(
      affected_rows,
      "#{source}.import_readiness_rows.affected_contacts"
    ) ++
      provider_contention_rows(
        provider_rows,
        "#{source}.import_readiness_rows.provider_calendar_contention_groups"
      )
  end

  defp station_reservation_hold_import_readiness_row(%{} = row, %{} = summary) do
    assumptions = stringify_keys(Map.get(summary, "assumptions", %{}))
    reservation_ids = Map.get(row, "reservation_ids", [])
    reservation_statuses = Map.get(row, "reservation_statuses", [])
    reserved_by = Map.get(row, "reserved_by", [])

    summary_context =
      %{
        "model" => summary["model"],
        "source_artifact_type" => summary["source_artifact_type"],
        "source" => summary["source"],
        "reservation_hold_count" => summary["reservation_hold_count"],
        "import_readiness_status" => summary["import_readiness_status"],
        "import_classification" => summary["import_classification"],
        "ready_for_import_count" => summary["ready_for_import_count"],
        "review_required_before_import_count" => summary["review_required_before_import_count"],
        "no_import_required_count" => summary["no_import_required_count"],
        "reservation_hold_import_status_counts" =>
          summary["reservation_hold_import_status_counts"],
        "required_import_action_counts" => summary["required_import_action_counts"],
        "reservation_hold_ids" => summary["reservation_hold_ids"],
        "reservation_hold_ids_by_import_status" =>
          summary["reservation_hold_ids_by_import_status"],
        "reservation_hold_ids_by_required_import_action" =>
          summary["reservation_hold_ids_by_required_import_action"],
        "reservation_hold_ids_by_direction" => summary["reservation_hold_ids_by_direction"],
        "reservation_hold_ids_by_direction_and_ground_station_id" =>
          summary["reservation_hold_ids_by_direction_and_ground_station_id"],
        "reservation_hold_contact_ids_by_import_status" =>
          summary["reservation_hold_contact_ids_by_import_status"],
        "reservation_hold_contact_ids_by_expiration_status" =>
          summary["reservation_hold_contact_ids_by_expiration_status"],
        "reservation_hold_contact_ids_by_direction" =>
          summary["reservation_hold_contact_ids_by_direction"],
        "reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
          summary["reservation_hold_contact_ids_by_direction_and_ground_station_id"],
        "model_limits" => summary["model_limits"],
        "assumptions" => summary["assumptions"]
      }
      |> compact_map()

    row
    |> Map.put_new("id", station_reservation_hold_import_readiness_row_id(row))
    |> Map.put_new("station_calendar_reservation_ids", reservation_ids)
    |> Map.put_new("station_calendar_reservation_statuses", reservation_statuses)
    |> Map.put_new("station_calendar_reserved_by", reserved_by)
    |> Map.put_new("station_calendar_reservation_overlap_count", length(reservation_ids))
    |> Map.put_new("station_reservation_id", List.first(reservation_ids))
    |> Map.put_new("station_reserved_by", List.first(reserved_by))
    |> Map.put_new("station_reservation_status", List.first(reservation_statuses))
    |> Map.put("station_reservation_hold_import_readiness_summary_model", summary["model"])
    |> Map.put("station_reservation_hold_import_readiness_source", summary["source"])
    |> Map.put(
      "station_reservation_hold_import_readiness_source_artifact_type",
      summary["source_artifact_type"]
    )
    |> Map.put(
      "station_reservation_hold_import_readiness_status",
      summary["import_readiness_status"]
    )
    |> Map.put(
      "station_reservation_hold_import_classification",
      summary["import_classification"]
    )
    |> Map.put("station_reservation_hold_count", summary["reservation_hold_count"])
    |> Map.put("station_reservation_hold_ids", summary["reservation_hold_ids"])
    |> Map.put(
      "station_reservation_hold_ids_by_import_status",
      summary["reservation_hold_ids_by_import_status"]
    )
    |> Map.put(
      "station_reservation_hold_ids_by_required_import_action",
      summary["reservation_hold_ids_by_required_import_action"]
    )
    |> Map.put(
      "station_reservation_hold_ids_by_direction",
      summary["reservation_hold_ids_by_direction"]
    )
    |> Map.put(
      "station_reservation_hold_ids_by_direction_and_ground_station_id",
      summary["reservation_hold_ids_by_direction_and_ground_station_id"]
    )
    |> Map.put(
      "station_reservation_hold_contact_ids_by_import_status",
      summary["reservation_hold_contact_ids_by_import_status"]
    )
    |> Map.put(
      "station_reservation_hold_contact_ids_by_expiration_status",
      summary["reservation_hold_contact_ids_by_expiration_status"]
    )
    |> Map.put(
      "station_reservation_hold_contact_ids_by_direction",
      summary["reservation_hold_contact_ids_by_direction"]
    )
    |> Map.put(
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
      summary["reservation_hold_contact_ids_by_direction_and_ground_station_id"]
    )
    |> Map.put(
      "station_reservation_hold_import_status_counts",
      summary["reservation_hold_import_status_counts"]
    )
    |> Map.put(
      "station_reservation_hold_required_import_action_counts",
      summary["required_import_action_counts"]
    )
    |> Map.put(
      "station_reservation_hold_import_execution_boundary",
      assumptions["execution_boundary"]
    )
    |> Map.put("station_reservation_hold_provider_write", assumptions["provider_write"])
    |> Map.put("station_reservation_hold_cadence_write", assumptions["cadence_write"])
    |> Map.put(
      "station_reservation_hold_reservation_acceptance",
      assumptions["reservation_acceptance"]
    )
    |> Map.put("source_station_reservation_hold_import_readiness_summary", summary_context)
    |> compact_map()
  end

  defp station_reservation_hold_import_readiness_row_id(%{} = row) do
    review_id([
      "station_reservation_hold_import_readiness",
      row["reservation_review_row_type"],
      row["contact_id"],
      List.first(List.wrap(row["reservation_ids"]))
    ])
  end

  defp station_reservation_hold_import_readiness_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_hold_import_readiness_summary" and
      is_list(summary["import_readiness_rows"])
  end

  defp station_reservation_hold_import_readiness_summary?(_summary), do: false

  defp station_reservation_report?(%{} = report) do
    report = stringify_keys(report)

    report["schema_contract"] in [nil, "station_reservation_report.v1"] and
      (is_list(report["affected_contacts"]) or
         is_list(report["provider_calendar_contention_groups"]))
  end

  defp station_reservation_review_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_review_summary" and
      summary["schema_contract"] in [nil, "station_reservation_review_summary.v1"] and
      is_list(summary["review_rows"])
  end

  defp station_reservation_review_summary?(_summary), do: false

  defp station_reservation_hold_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_hold_summary" and
      summary["schema_contract"] in [nil, "station_reservation_hold_summary.v1"] and
      is_list(summary["review_rows"])
  end

  defp station_reservation_hold_summary?(_summary), do: false

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
         %{"schema_contract" => "station_reservation_report.v1"} = report,
         source
       ) do
    source_station_reservation_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_station_reservation_report",
       artifact["source_station_reservation_report"]},
      {"#{source}.station_reservation_report", artifact["station_reservation_report"]},
      {"#{source}.source_station_reservation_review_summary",
       artifact["source_station_reservation_review_summary"]},
      {"#{source}.station_reservation_review_summary",
       artifact["station_reservation_review_summary"]},
      {"#{source}.source_station_reservation_hold_summary",
       artifact["source_station_reservation_hold_summary"]},
      {"#{source}.station_reservation_hold_summary",
       artifact["station_reservation_hold_summary"]},
      {"#{source}.source_station_reservation_hold_import_readiness_summary",
       artifact["source_station_reservation_hold_import_readiness_summary"]},
      {"#{source}.station_reservation_hold_import_readiness_summary",
       artifact["station_reservation_hold_import_readiness_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_station_reservation_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

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
