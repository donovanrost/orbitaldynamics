defmodule OrbitalDynamics.Schema.CampaignRepairLinkCapacityHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_capacity_source "campaign_repair.link_capacity_report.rows"
  @repair_source_summary_prefix "campaign_repair.source_link_capacity_summary"
  @repair_source_summary @repair_source_summary_prefix <> ".rows"
  @summary_context_fields [
    "model",
    "schema_contract",
    "source_artifact_type",
    "source",
    "route_count",
    "relay_route_count",
    "direct_downlink_route_count",
    "route_ids",
    "route_ids_by_ground_station_id",
    "route_ids_by_latency_status",
    "route_ids_by_risk_status",
    "route_ids_by_custody_status",
    "source_spacecraft_ids",
    "relay_spacecraft_ids",
    "ground_downlink_contact_ids",
    "custody_status_counts",
    "latency_status_counts",
    "risk_status_counts",
    "station_count",
    "contact_count",
    "selected_contact_count",
    "selected_downlink_shortfall_mb",
    "actual_downlink_shortfall_mb",
    "capacity_adjusted_throughput_mb",
    "selected_capacity_adjusted_throughput_mb",
    "unused_capacity_adjusted_throughput_mb",
    "selected_contact_ids",
    "actual_throughput_contact_ids",
    "assumptions"
  ]

  def validate(issues, artifact) do
    issues
    |> validate_report(artifact)
    |> validate_source_summary(artifact)
  end

  defp validate_report(
         issues,
         %{"link_capacity_report" => %{"rows" => capacity_rows}} = artifact
       )
       when is_list(capacity_rows) do
    source_rows = Enum.filter(capacity_rows, &is_map/1)

    issues
    |> validate_operator_review_handoff(artifact, source_rows)
    |> validate_cadence_handoff(artifact, source_rows)
  end

  defp validate_report(issues, _artifact), do: issues

  defp validate_source_summary(
         issues,
         %{"source_link_capacity_summary" => %{} = summary} = artifact
       ) do
    source_rows = source_summary_rows(summary)
    expected_sources = List.duplicate(@repair_source_summary, length(source_rows))

    issues
    |> validate_source_summary_operator_handoff(artifact, source_rows, expected_sources)
    |> validate_source_summary_cadence_handoff(artifact, source_rows, expected_sources)
  end

  defp validate_source_summary(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         capacity_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_capacity_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(capacity_rows),
      "must contain one Repair link-capacity review row per enclosing report row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      capacity_rows,
      [["source_link_capacity"]],
      "must match the corresponding enclosing Repair link-capacity report row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _capacity_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         capacity_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_capacity_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(capacity_rows),
      "must contain one Repair link-capacity import row per enclosing report row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      capacity_rows,
      [
        ["source_link_capacity"],
        ["source_review_row", "source_link_capacity"]
      ],
      "must match the corresponding enclosing Repair link-capacity report row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _capacity_rows), do: issues

  defp validate_source_summary_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         expected_sources
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_source_summary_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source link-capacity-summary review row per producer review row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source link-capacity-summary source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_link_capacity"]],
      "must match the corresponding enclosing Repair source link-capacity-summary review row"
    )
  end

  defp validate_source_summary_operator_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources
       ),
       do: issues

  defp validate_source_summary_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         source_rows,
         expected_sources
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_source_summary_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source link-capacity-summary import row per producer review row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source link-capacity-summary source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [["source_link_capacity"], ["source_review_row", "source_link_capacity"]],
      "must match the corresponding enclosing Repair source link-capacity-summary review row"
    )
  end

  defp validate_source_summary_cadence_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources
       ),
       do: issues

  defp operator_capacity_row?(row) do
    Map.get(row, "review_type") == "link_capacity_review" and
      row_source(row) == @repair_capacity_source
  end

  defp cadence_capacity_row?(row) do
    (Map.get(row, "source_review_type") == "link_capacity_review" or
       Map.get(row, "import_action") == "review_link_capacity") and
      row_source(row) == @repair_capacity_source
  end

  defp operator_source_summary_row?(row) do
    Map.get(row, "review_type") == "link_capacity_review" and
      source_summary_source?(row_source(row))
  end

  defp cadence_source_summary_row?(row) do
    (Map.get(row, "source_review_type") == "link_capacity_review" or
       Map.get(row, "import_action") == "review_link_capacity") and
      source_summary_source?(row_source(row))
  end

  defp source_summary_source?(source) when is_binary(source),
    do: String.starts_with?(source, @repair_source_summary_prefix)

  defp source_summary_source?(_source), do: false

  defp source_summary_rows(summary) do
    context = summary_context(summary)

    summary
    |> summary_review_rows()
    |> Enum.map(fn row ->
      row
      |> Map.put("source_link_capacity_summary", context)
      |> Map.put("source_summary_model", Map.get(summary, "model"))
      |> Map.put("source_summary_schema_contract", Map.get(summary, "schema_contract"))
      |> Map.put("source_artifact_type", Map.get(summary, "source_artifact_type"))
      |> Map.put("schema_contract", Map.get(summary, "schema_contract"))
      |> compact_map()
    end)
  end

  defp summary_review_rows(%{"rows" => rows}) when is_list(rows) and rows != [],
    do: Enum.filter(rows, &is_map/1)

  defp summary_review_rows(summary) do
    summary
    |> Map.get("ground_station_ids", [])
    |> normalized_ids()
    |> Enum.map(&station_summary_row(summary, &1))
  end

  defp station_summary_row(summary, station_id) do
    selected_contact_ids = summary_station_ids(summary, station_id, "selected_contact_ids")

    actual_throughput_contact_ids =
      summary_station_ids(summary, station_id, "actual_throughput_contact_ids")

    required_downlink_contact_ids =
      summary_station_ids(summary, station_id, "required_downlink_contact_ids")

    contact_ids =
      [selected_contact_ids, actual_throughput_contact_ids, required_downlink_contact_ids]
      |> List.flatten()
      |> Enum.uniq()

    %{
      "ground_station_id" => station_id,
      "contact_count" => length(contact_ids),
      "contact_ids" => contact_ids,
      "selected_contact_count" => length(selected_contact_ids),
      "selected_contact_ids" => selected_contact_ids,
      "actual_throughput_contact_count" => length(actual_throughput_contact_ids),
      "actual_throughput_contact_ids" => actual_throughput_contact_ids,
      "required_downlink_contact_count" => length(required_downlink_contact_ids),
      "required_downlink_contact_ids" => required_downlink_contact_ids,
      "selected_downlink_shortfall_mb" =>
        summary_station_number(summary, station_id, "selected_downlink_shortfall_mb"),
      "actual_downlink_shortfall_mb" =>
        summary_station_number(summary, station_id, "actual_downlink_shortfall_mb"),
      "capacity_adjusted_throughput_mb" =>
        summary_station_number(summary, station_id, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb" =>
        summary_station_number(
          summary,
          station_id,
          "selected_capacity_adjusted_throughput_mb"
        ),
      "unused_capacity_adjusted_throughput_mb" =>
        summary_station_number(
          summary,
          station_id,
          "unused_capacity_adjusted_throughput_mb"
        ),
      "downlink_requirement_status" =>
        summary_shortfall_status(summary, station_id, "shortfall_ground_station_ids"),
      "actual_downlink_requirement_status" =>
        summary_shortfall_status(summary, station_id, "actual_shortfall_ground_station_ids"),
      "station_calendar_entry_ids" =>
        summary_station_ids(summary, station_id, "station_calendar_entry_ids"),
      "station_calendar_provider_entry_ids" =>
        summary_station_ids(summary, station_id, "station_calendar_provider_entry_ids"),
      "station_reservation_ids" =>
        summary_station_ids(summary, station_id, "station_reservation_ids")
    }
    |> compact_map()
  end

  defp summary_station_ids(summary, station_id, field) do
    case Map.get(summary, "#{field}_by_ground_station_id") do
      values when is_map(values) -> values |> Map.get(station_id, []) |> normalized_ids()
      _values -> []
    end
  end

  defp summary_station_number(summary, station_id, field) do
    case Map.get(summary, "#{field}_by_ground_station_id") do
      values when is_map(values) -> Map.get(values, station_id)
      _values -> nil
    end
  end

  defp summary_shortfall_status(summary, station_id, field) do
    case Map.get(summary, field) do
      station_ids when is_list(station_ids) ->
        if station_id in station_ids, do: "shortfall"

      _station_ids ->
        nil
    end
  end

  defp summary_context(summary) do
    summary
    |> Map.take(@summary_context_fields)
    |> compact_map()
  end

  defp normalized_ids(values) do
    values
    |> List.wrap()
    |> Enum.map(&normalized_id/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp normalized_id(value) when is_binary(value), do: value
  defp normalized_id(value) when is_atom(value) or is_number(value), do: to_string(value)
  defp normalized_id(_value), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_field, value} -> is_nil(value) end)
    |> Map.new()
  end
end
