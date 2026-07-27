defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_allocation_source "campaign_repair.contact_allocation_report.rows"
  @repair_source_allocation "campaign_repair.source_contact_allocation_report.rows"
  @repair_source_summary_prefix "campaign_repair.source_contact_allocation_summary"
  @repair_source_summaries_prefix "campaign_repair.source_contact_allocation_summaries"
  @summary_context_fields [
    "model",
    "schema_contract",
    "source_artifact_type",
    "source",
    "input_contact_count",
    "allocated_contact_count",
    "returned_allocated_contact_count",
    "deferred_contact_count",
    "blocked_contact_count",
    "review_contact_ids",
    "station_pressure_review_contact_ids",
    "station_pressure_contact_ids_by_status",
    "station_pressure_contact_ids_by_direction",
    "station_pressure_contact_ids_by_direction_and_ground_station_id",
    "reservation_review_contact_ids",
    "reservation_conflict_contact_ids_by_direction",
    "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
    "capacity_pack_review_status",
    "reduced_capacity_pack_group_count",
    "assumptions"
  ]

  def validate(issues, artifact) do
    issues
    |> validate_report(
      artifact,
      "contact_allocation_report",
      @repair_allocation_source,
      "generated Repair"
    )
    |> validate_report(
      artifact,
      "source_contact_allocation_report",
      @repair_source_allocation,
      "Repair source"
    )
    |> validate_source_summary_handoffs(artifact)
  end

  defp validate_report(issues, artifact, report_field, source, source_label)
       when is_map(artifact) do
    case Map.get(artifact, report_field) do
      %{"rows" => allocation_rows} when is_list(allocation_rows) ->
        source_rows = Enum.filter(allocation_rows, &is_map/1)

        issues
        |> validate_operator_review_handoff(
          artifact,
          source_rows,
          source,
          source_label
        )
        |> validate_cadence_handoff(artifact, source_rows, source, source_label)

      _report ->
        issues
    end
  end

  defp validate_report(issues, _artifact, _report_field, _source, _source_label), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         allocation_rows,
         source,
         source_label
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_allocation_row?(&1, source))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(allocation_rows),
      "must contain one #{source_label} contact-allocation review row per enclosing report row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      List.duplicate(source, length(allocation_rows)),
      [["source"]],
      "must match the enclosing #{source_label} contact-allocation source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      allocation_rows,
      [["source_contact_allocation"]],
      "must match the corresponding enclosing #{source_label} contact-allocation report row"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _allocation_rows,
         _source,
         _source_label
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         allocation_rows,
         source,
         source_label
       ) do
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_allocation_row?(&1, source))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(allocation_rows),
      "must contain one #{source_label} contact-allocation import row per enclosing report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      List.duplicate(source, length(allocation_rows)),
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing #{source_label} contact-allocation source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      allocation_rows,
      [
        ["source_contact_allocation"],
        ["source_review_row", "source_contact_allocation"]
      ],
      "must match the corresponding enclosing #{source_label} contact-allocation report row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _allocation_rows,
         _source,
         _source_label
       ),
       do: issues

  defp validate_source_summary_handoffs(issues, artifact) when is_map(artifact) do
    {source_rows, expected_sources} = source_summary_rows(artifact)

    issues
    |> validate_source_summary_operator_handoff(artifact, source_rows, expected_sources)
    |> validate_source_summary_cadence_handoff(artifact, source_rows, expected_sources)
  end

  defp validate_source_summary_handoffs(issues, _artifact), do: issues

  defp validate_source_summary_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         expected_sources
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_summary_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source compact allocation-summary review row per producer review row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source compact allocation-summary source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_contact_allocation"]],
      "must match the corresponding enclosing Repair source compact allocation-summary review row"
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
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_summary_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source compact allocation-summary import row per producer review row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source compact allocation-summary source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [
        ["source_contact_allocation"],
        ["source_review_row", "source_contact_allocation"]
      ],
      "must match the corresponding enclosing Repair source compact allocation-summary review row"
    )
  end

  defp validate_source_summary_cadence_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources
       ),
       do: issues

  defp source_summary_rows(artifact) do
    artifact
    |> source_summaries()
    |> Enum.flat_map(fn {summary, source_prefix} ->
      case summary_review_rows(summary, source_prefix) do
        {rows, source} ->
          Enum.map(rows, &{summary_source_row(&1, summary), source})
      end
    end)
    |> Enum.unzip()
  end

  defp source_summaries(artifact) do
    case Map.get(artifact, "source_contact_allocation_summaries") do
      [_summary | _summaries] = summaries ->
        summaries
        |> Enum.with_index()
        |> Enum.flat_map(fn
          {%{} = summary, index} ->
            [{summary, "#{@repair_source_summaries_prefix}[#{index}]"}]

          {_summary, _index} ->
            []
        end)

      _summaries ->
        case Map.get(artifact, "source_contact_allocation_summary") do
          %{} = summary -> [{summary, @repair_source_summary_prefix}]
          _summary -> []
        end
    end
  end

  defp summary_review_rows(summary, source_prefix) do
    cond do
      is_list(summary["review_rows"]) and summary["review_rows"] != [] ->
        {Enum.filter(summary["review_rows"], &is_map/1), "#{source_prefix}.review_rows"}

      is_list(summary["rows"]) and summary["rows"] != [] ->
        {Enum.filter(summary["rows"], &is_map/1), "#{source_prefix}.rows"}

      true ->
        {[], "contact_allocation_summary.rows"}
    end
  end

  defp summary_source_row(row, summary) do
    row
    |> Map.put(
      "source_contact_allocation_summary",
      summary |> Map.take(@summary_context_fields) |> compact_map()
    )
    |> Map.put("source_summary_model", summary["model"])
    |> Map.put("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put("source_artifact_type", summary["source_artifact_type"])
    |> Map.put("source", summary["source"])
    |> Map.put("schema_contract", summary["schema_contract"])
    |> compact_map()
  end

  defp operator_allocation_row?(row, source) do
    Map.get(row, "review_type") == "contact_allocation_review" and
      allocation_source?(row_source(row), source)
  end

  defp cadence_allocation_row?(row, source) do
    (Map.get(row, "source_review_type") == "contact_allocation_review" or
       Map.get(row, "import_action") == "review_contact_allocation") and
      allocation_source?(row_source(row), source)
  end

  defp operator_summary_row?(row) do
    Map.get(row, "review_type") == "contact_allocation_review" and
      summary_source?(row_source(row))
  end

  defp cadence_summary_row?(row) do
    (Map.get(row, "source_review_type") == "contact_allocation_review" or
       Map.get(row, "import_action") == "review_contact_allocation") and
      summary_source?(row_source(row))
  end

  defp summary_source?(source) when is_binary(source) do
    String.starts_with?(source, @repair_source_summary_prefix <> ".") or
      String.starts_with?(source, @repair_source_summaries_prefix <> "[")
  end

  defp summary_source?(_source), do: false

  defp allocation_source?(actual, expected) when is_binary(actual),
    do: String.starts_with?(actual, expected)

  defp allocation_source?(_actual, _expected), do: false

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_field, value} -> is_nil(value) end)
    |> Map.new()
  end
end
