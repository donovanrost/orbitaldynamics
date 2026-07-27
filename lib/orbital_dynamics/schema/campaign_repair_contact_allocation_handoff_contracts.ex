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
  @source_summary_families [
    %{
      singular_field: "source_contact_allocation_summary",
      plural_field: "source_contact_allocation_summaries",
      singular_prefix: "campaign_repair.source_contact_allocation_summary",
      plural_prefix: "campaign_repair.source_contact_allocation_summaries",
      label: "compact allocation-summary",
      row_fields: ["review_rows", "rows"]
    },
    %{
      singular_field: "source_contact_allocation_station_pressure_summary",
      plural_field: "source_contact_allocation_station_pressure_summaries",
      singular_prefix: "campaign_repair.source_contact_allocation_station_pressure_summary",
      plural_prefix: "campaign_repair.source_contact_allocation_station_pressure_summaries",
      label: "station-pressure summary",
      row_fields: ["review_rows", "rows"]
    },
    %{
      singular_field: "source_contact_allocation_reservation_conflict_summary",
      plural_field: "source_contact_allocation_reservation_conflict_summaries",
      singular_prefix: "campaign_repair.source_contact_allocation_reservation_conflict_summary",
      plural_prefix: "campaign_repair.source_contact_allocation_reservation_conflict_summaries",
      label: "reservation-conflict summary",
      row_fields: [
        "reservation_review_rows",
        "reservation_conflict_rows",
        "review_rows",
        "rows"
      ]
    },
    %{
      singular_field: "source_contact_allocation_capacity_pack_summary",
      plural_field: "source_contact_allocation_capacity_pack_summaries",
      singular_prefix: "campaign_repair.source_contact_allocation_capacity_pack_summary",
      plural_prefix: "campaign_repair.source_contact_allocation_capacity_pack_summaries",
      label: "capacity-pack summary",
      row_fields: ["review_rows", "rows"],
      capacity_pack_groups: true
    },
    %{
      singular_field: "source_contact_allocation_provider_reservation_request_summary",
      plural_field: "source_contact_allocation_provider_reservation_request_summaries",
      singular_prefix:
        "campaign_repair.source_contact_allocation_provider_reservation_request_summary",
      plural_prefix:
        "campaign_repair.source_contact_allocation_provider_reservation_request_summaries",
      label: "provider-reservation-request summary",
      provider_reservation_requests: true
    }
  ]
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
  @provider_reservation_summary_context_fields [
    "model",
    "schema_contract",
    "source_artifact_type",
    "source",
    "provider_reservation_candidate_contact_count",
    "provider_reservation_request_contact_count",
    "provider_reservation_review_contact_count",
    "provider_reservation_no_request_contact_count",
    "provider_reservation_request_status",
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
    |> validate_source_summary_handoff_families(artifact)
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

  defp validate_source_summary_handoff_families(issues, artifact) when is_map(artifact) do
    Enum.reduce(@source_summary_families, issues, fn family, acc ->
      validate_source_summary_handoffs(acc, artifact, family)
    end)
  end

  defp validate_source_summary_handoff_families(issues, _artifact), do: issues

  defp validate_source_summary_handoffs(issues, artifact, family) do
    {source_rows, expected_sources} = source_summary_rows(artifact, family)

    issues
    |> validate_source_summary_operator_handoff(
      artifact,
      source_rows,
      expected_sources,
      family
    )
    |> validate_source_summary_cadence_handoff(
      artifact,
      source_rows,
      expected_sources,
      family
    )
    |> validate_source_summary_capacity_pack_handoffs(artifact, family)
  end

  defp validate_source_summary_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         expected_sources,
         family
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_summary_row?(&1, family))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source #{family.label} review row per producer review row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source #{family.label} source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_contact_allocation"]],
      "must match the corresponding enclosing Repair source #{family.label} review row"
    )
  end

  defp validate_source_summary_operator_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources,
         _family
       ),
       do: issues

  defp validate_source_summary_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         source_rows,
         expected_sources,
         family
       ) do
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_summary_row?(&1, family))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source #{family.label} import row per producer review row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source #{family.label} source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [
        ["source_contact_allocation"],
        ["source_review_row", "source_contact_allocation"]
      ],
      "must match the corresponding enclosing Repair source #{family.label} review row"
    )
  end

  defp validate_source_summary_cadence_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources,
         _family
       ),
       do: issues

  defp validate_source_summary_capacity_pack_handoffs(issues, artifact, family) do
    if Map.get(family, :capacity_pack_groups, false) do
      {source_rows, expected_sources} = source_summary_capacity_pack_rows(artifact, family)

      issues
      |> validate_source_summary_capacity_pack_operator_handoff(
        artifact,
        source_rows,
        expected_sources,
        family
      )
      |> validate_source_summary_capacity_pack_cadence_handoff(
        artifact,
        source_rows,
        expected_sources,
        family
      )
    else
      issues
    end
  end

  defp validate_source_summary_capacity_pack_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         expected_sources,
         family
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_capacity_pack_row?(&1, family))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source #{family.label} group review row per reduced-capacity group"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source #{family.label} group source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_contact_allocation_capacity_pack"]],
      "must match the corresponding enclosing Repair source #{family.label} group"
    )
  end

  defp validate_source_summary_capacity_pack_operator_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources,
         _family
       ),
       do: issues

  defp validate_source_summary_capacity_pack_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         source_rows,
         expected_sources,
         family
       ) do
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_capacity_pack_row?(&1, family))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source #{family.label} group import row per reduced-capacity group"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source #{family.label} group source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [
        ["source_contact_allocation_capacity_pack"],
        ["source_review_row", "source_contact_allocation_capacity_pack"]
      ],
      "must match the corresponding enclosing Repair source #{family.label} group"
    )
  end

  defp validate_source_summary_capacity_pack_cadence_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources,
         _family
       ),
       do: issues

  defp source_summary_rows(
         artifact,
         %{provider_reservation_requests: true} = family
       ) do
    artifact
    |> source_summaries(family)
    |> Enum.flat_map(fn {summary, source_prefix} ->
      source = "#{source_prefix}.provider_reservation_request_rows"

      request_rows =
        provider_reservation_summary_rows(
          summary["provider_reservation_request_rows"],
          "request_ready",
          summary
        )

      review_rows =
        provider_reservation_summary_rows(
          summary["provider_reservation_review_rows"],
          "review_required",
          summary
        )

      Enum.map(request_rows ++ review_rows, &{&1, source})
    end)
    |> Enum.unzip()
  end

  defp source_summary_rows(artifact, family) do
    artifact
    |> source_summaries(family)
    |> Enum.flat_map(fn {summary, source_prefix} ->
      case summary_review_rows(summary, source_prefix, family) do
        {rows, source} ->
          Enum.map(rows, &{summary_source_row(&1, summary), source})
      end
    end)
    |> Enum.unzip()
  end

  defp provider_reservation_summary_rows(rows, status, summary) do
    assumptions = Map.get(summary, "assumptions", %{})

    summary_context =
      summary
      |> Map.take(@provider_reservation_summary_context_fields)
      |> compact_map()

    rows
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn row ->
      row
      |> Map.put("provider_reservation_request_status", status)
      |> Map.put("provider_reservation_request_summary_model", summary["model"])
      |> Map.put(
        "provider_reservation_request_summary_schema_contract",
        summary["schema_contract"]
      )
      |> Map.put(
        "provider_reservation_request_source_artifact_type",
        summary["source_artifact_type"]
      )
      |> Map.put("provider_reservation_request_source", summary["source"])
      |> Map.put(
        "provider_reservation_request_execution_boundary",
        assumptions["execution_boundary"]
      )
      |> Map.put(
        "provider_reservation_execution",
        assumptions["provider_reservation_execution"]
      )
      |> Map.put("source_provider_reservation_request_summary", summary_context)
      |> compact_map()
    end)
  end

  defp source_summary_capacity_pack_rows(artifact, family) do
    artifact
    |> source_summaries(family)
    |> Enum.flat_map(fn {summary, source_prefix} ->
      summary
      |> Map.get("reduced_capacity_pack_groups", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(fn group ->
        source_row =
          group
          |> summary_source_row(summary)
          |> put_capacity_pack_direction_summary()

        {source_row, "#{source_prefix}.reduced_capacity_pack_groups"}
      end)
    end)
    |> Enum.unzip()
  end

  defp source_summaries(artifact, family) do
    case Map.get(artifact, family.plural_field) do
      [_summary | _summaries] = summaries ->
        summaries
        |> Enum.with_index()
        |> Enum.flat_map(fn
          {%{} = summary, index} ->
            [{summary, "#{family.plural_prefix}[#{index}]"}]

          {_summary, _index} ->
            []
        end)

      _summaries ->
        case Map.get(artifact, family.singular_field) do
          %{} = summary -> [{summary, family.singular_prefix}]
          _summary -> []
        end
    end
  end

  defp summary_review_rows(summary, source_prefix, family) do
    Enum.find_value(family.row_fields, {[], "contact_allocation_summary.rows"}, fn field ->
      case Map.get(summary, field) do
        rows when is_list(rows) and rows != [] ->
          {Enum.filter(rows, &is_map/1), "#{source_prefix}.#{field}"}

        _rows ->
          nil
      end
    end)
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

  defp put_capacity_pack_direction_summary(group) do
    rows =
      group
      |> Map.get("capacity_requirement_rows", [])
      |> Enum.filter(&is_map/1)

    contact_directions = capacity_pack_contact_directions(group, rows)

    routed_rows =
      rows
      |> Enum.map(fn row ->
        row
        |> Map.put("direction", row["direction"] || contact_directions[row["contact_id"]])
        |> compact_map()
      end)
      |> Enum.filter(&(is_binary(&1["contact_id"]) and is_binary(&1["direction"])))

    case routed_rows do
      [] ->
        group

      routed_rows ->
        selected_rows = Enum.filter(routed_rows, &(&1["allocation_status"] == "allocated"))
        deferred_rows = Enum.filter(routed_rows, &(&1["allocation_status"] == "deferred"))

        Map.merge(group, %{
          "capacity_pack_contact_ids_by_direction" => capacity_pack_ids(routed_rows),
          "capacity_pack_selected_contact_ids_by_direction" => capacity_pack_ids(selected_rows),
          "capacity_pack_deferred_contact_ids_by_direction" => capacity_pack_ids(deferred_rows),
          "capacity_pack_required_capacity_fraction_by_direction" =>
            capacity_pack_fractions(routed_rows),
          "capacity_pack_selected_required_capacity_fraction_by_direction" =>
            capacity_pack_fractions(selected_rows),
          "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
            capacity_pack_fractions(deferred_rows)
        })
    end
  end

  defp capacity_pack_contact_directions(group, rows) do
    fallback_direction =
      cond do
        is_binary(group["direction"]) ->
          group["direction"]

        match?([direction] when is_binary(direction), List.wrap(group["directions"])) ->
          List.first(group["directions"])

        true ->
          nil
      end

    fallback_directions =
      rows
      |> Enum.filter(&(is_binary(&1["contact_id"]) and is_binary(fallback_direction)))
      |> Map.new(&{&1["contact_id"], fallback_direction})

    fallback_directions
    |> Map.merge(capacity_pack_candidate_directions(group["source_contact_candidates"]))
    |> Map.merge(
      capacity_pack_candidate_directions(
        get_in(group, ["source_contention_recommendation", "source_contact_candidates"])
      )
    )
    |> Map.merge(
      rows
      |> Enum.filter(&(is_binary(&1["contact_id"]) and is_binary(&1["direction"])))
      |> Map.new(&{&1["contact_id"], &1["direction"]})
    )
  end

  defp capacity_pack_candidate_directions(candidates) do
    candidates
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.filter(&(is_binary(&1["id"]) and is_binary(&1["direction"])))
    |> Map.new(&{&1["id"], &1["direction"]})
  end

  defp capacity_pack_ids(rows) do
    rows
    |> Enum.group_by(& &1["direction"], & &1["contact_id"])
    |> Map.new(fn {direction, contact_ids} ->
      {direction, contact_ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp capacity_pack_fractions(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      case {row["direction"], row["required_capacity_fraction"]} do
        {direction, fraction} when is_binary(direction) and is_number(fraction) ->
          Map.update(acc, direction, fraction, &(&1 + fraction))

        _row_without_fraction ->
          acc
      end
    end)
    |> Map.new(fn {direction, fraction} -> {direction, Float.round(fraction, 10)} end)
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

  defp operator_summary_row?(row, family) do
    Map.get(row, "review_type") == "contact_allocation_review" and
      summary_source?(row_source(row), family)
  end

  defp cadence_summary_row?(row, family) do
    (Map.get(row, "source_review_type") == "contact_allocation_review" or
       Map.get(row, "import_action") == "review_contact_allocation") and
      summary_source?(row_source(row), family)
  end

  defp operator_capacity_pack_row?(row, family) do
    Map.get(row, "review_type") == "contact_allocation_capacity_pack_review" and
      summary_source?(row_source(row), family)
  end

  defp cadence_capacity_pack_row?(row, family) do
    (Map.get(row, "source_review_type") == "contact_allocation_capacity_pack_review" or
       Map.get(row, "import_action") == "review_contact_allocation_capacity_pack") and
      summary_source?(row_source(row), family)
  end

  defp summary_source?(source, family) when is_binary(source) do
    String.starts_with?(source, family.singular_prefix <> ".") or
      String.starts_with?(source, family.plural_prefix <> "[")
  end

  defp summary_source?(_source, _family), do: false

  defp allocation_source?(actual, expected) when is_binary(actual),
    do: String.starts_with?(actual, expected)

  defp allocation_source?(_actual, _expected), do: false

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_field, value} -> is_nil(value) end)
    |> Map.new()
  end
end
