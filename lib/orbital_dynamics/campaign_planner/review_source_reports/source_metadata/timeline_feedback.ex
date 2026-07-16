defmodule OrbitalDynamics.CampaignPlanner.ReviewSourceReports.SourceMetadata.TimelineFeedback do
  @moduledoc false

  def source_metadata(reports_with_sources, opts) do
    callbacks = metadata_callbacks!(opts)
    {reports, source_paths} = reports_and_source_paths(reports_with_sources)

    case reports do
      [] ->
        %{}

      [report] ->
        report
        |> source_report_metadata(callbacks)
        |> put_if_present("source_report_paths", source_paths)
        |> put_if_absent(
          "trust_boundary_status",
          report_trust_boundary_status(reports, callbacks)
        )
        |> put_if_absent("trust_boundaries", report_trust_boundaries(reports, callbacks))
        |> put_if_absent(
          "feedback_trust_boundaries",
          reports_feedback_trust_boundaries(reports, callbacks)
        )

      _reports ->
        %{
          "source_report_contract" => "timeline_feedback_report.v1",
          "source_report_count" => length(reports),
          "source_report_paths" => source_paths,
          "source_report_row_count" =>
            reports
            |> Enum.map(&report_row_count/1)
            |> Enum.sum(),
          "source_report_status_counts" =>
            merge_report_count_maps(reports, "status_counts", callbacks),
          "source_feedback_kind_counts" =>
            merge_report_count_maps(reports, "feedback_kind_counts", callbacks),
          "source_match_strategy_counts" =>
            merge_report_count_maps(reports, "match_strategy_counts", callbacks),
          "source_cadence_import_status_counts" =>
            merge_report_count_maps(reports, "cadence_import_status_counts", callbacks),
          "source_planned_protection_decision_counts" =>
            merge_report_count_maps(reports, "planned_protection_decision_counts", callbacks),
          "trust_boundary_status" => report_trust_boundary_status(reports, callbacks),
          "trust_boundaries" => report_trust_boundaries(reports, callbacks),
          "feedback_trust_boundaries" => reports_feedback_trust_boundaries(reports, callbacks)
        }
        |> compact_map()
    end
  end

  def report_row_count(report) do
    Map.get(report, "row_count") || length(Map.get(report, "rows", []))
  end

  defp metadata_callbacks!(opts) do
    %{
      operational_feedback_provenance_trust_boundaries:
        Keyword.fetch!(opts, :operational_feedback_provenance_trust_boundaries),
      numeric_or_nil: Keyword.fetch!(opts, :numeric_or_nil),
      merge_feedback_trust_boundary_maps:
        Keyword.fetch!(opts, :merge_feedback_trust_boundary_maps),
      normalize_operational_feedback: Keyword.fetch!(opts, :normalize_operational_feedback),
      operational_feedback_value_present:
        Keyword.fetch!(opts, :operational_feedback_value_present),
      put_feedback_trust_boundary: Keyword.fetch!(opts, :put_feedback_trust_boundary)
    }
  end

  defp reports_and_source_paths(reports_with_sources) do
    reports = Enum.map(reports_with_sources, fn {report, _source_path} -> report end)
    source_paths = Enum.map(reports_with_sources, fn {_report, source_path} -> source_path end)

    {reports, source_paths}
  end

  defp merge_report_count_maps(reports, field, callbacks) do
    reports
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn counts, merged ->
      counts
      |> stringify_keys()
      |> Enum.reduce(merged, fn {key, value}, merged ->
        case callbacks.numeric_or_nil.(value) do
          number when is_number(number) ->
            Map.update(merged, key, number, &(&1 + number))

          _value ->
            merged
        end
      end)
    end)
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp source_report_metadata(%{} = report, callbacks) when map_size(report) > 0 do
    compact_map(%{
      "source_report_contract" => Map.get(report, "schema_contract"),
      "source_report_count" => 1,
      "source_report_row_count" =>
        Map.get(report, "row_count") || length(Map.get(report, "rows", [])),
      "source_report_status_counts" => Map.get(report, "status_counts"),
      "source_feedback_kind_counts" => Map.get(report, "feedback_kind_counts"),
      "source_match_strategy_counts" => Map.get(report, "match_strategy_counts"),
      "source_cadence_import_status_counts" => Map.get(report, "cadence_import_status_counts"),
      "source_planned_protection_decision_counts" =>
        Map.get(report, "planned_protection_decision_counts"),
      "source_operational_feedback_provenance" =>
        source_report_operational_feedback_provenance(report),
      "trust_boundary_status" =>
        source_report_operational_feedback_trust_status(report, callbacks),
      "trust_boundaries" => source_report_operational_feedback_trust_boundaries(report, callbacks)
    })
  end

  defp source_report_metadata(_report, _callbacks), do: %{}

  defp source_report_operational_feedback_provenance(%{
         "operational_feedback_provenance" => %{} = provenance
       }),
       do: provenance

  defp source_report_operational_feedback_provenance(_report), do: nil

  defp source_report_operational_feedback_trust_status(report, callbacks) do
    case source_report_operational_feedback_trust_boundaries(report, callbacks) do
      boundaries when is_list(boundaries) and boundaries != [] -> "declared"
      _boundaries -> nil
    end
  end

  defp source_report_operational_feedback_trust_boundaries(report, callbacks) do
    case source_report_operational_feedback_provenance(report) do
      %{} = provenance ->
        case callbacks.operational_feedback_provenance_trust_boundaries.(provenance) do
          [] -> nil
          boundaries -> boundaries
        end

      _provenance ->
        nil
    end
  end

  defp report_trust_boundary_status(reports, callbacks) do
    case report_trust_boundaries(reports, callbacks) do
      boundaries when is_list(boundaries) and boundaries != [] -> "declared"
      _boundaries -> nil
    end
  end

  defp report_trust_boundaries(reports, callbacks) do
    reports
    |> Enum.flat_map(fn report ->
      [
        Map.get(report, "trust_boundary"),
        get_in(report, ["provenance", "trust_boundary"]),
        source_report_operational_feedback_trust_boundaries(report, callbacks)
      ]
    end)
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp reports_feedback_trust_boundaries(reports, callbacks) do
    reports
    |> Enum.reduce(%{}, fn report, boundaries ->
      report_boundaries =
        case source_report_operational_feedback_trust_boundaries(report, callbacks) do
          values when is_list(values) and values != [] ->
            %{
              "source_operational_feedback_provenance" =>
                source_report_operational_feedback_provenance(report)
            }
            |> source_feedback_trust_boundaries()
            |> callbacks.merge_feedback_trust_boundary_maps.()

          _values ->
            report_feedback_trust_boundaries(report, callbacks)
        end

      callbacks.merge_feedback_trust_boundary_maps.([boundaries, report_boundaries])
    end)
    |> case do
      boundaries when boundaries == %{} -> nil
      boundaries -> boundaries
    end
  end

  defp report_feedback_trust_boundaries(report, callbacks) do
    trust_boundary =
      Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

    if trust_boundary in [nil, ""] do
      %{}
    else
      report
      |> Map.get("operational_feedback", %{})
      |> callbacks.normalize_operational_feedback.()
      |> Enum.reduce(%{}, fn {field, values}, boundaries ->
        values
        |> Enum.reduce(boundaries, fn {key, value}, boundaries ->
          if callbacks.operational_feedback_value_present.(%{key => value}) do
            callbacks.put_feedback_trust_boundary.(boundaries, field, key, [trust_boundary])
          else
            boundaries
          end
        end)
      end)
    end
  end

  defp source_feedback_trust_boundaries(source) do
    direct =
      case Map.get(source, "feedback_trust_boundaries") do
        %{} = boundaries -> [boundaries]
        _boundaries -> []
      end

    provenance =
      source |> Map.get("source_operational_feedback_provenance", %{}) |> stringify_keys()

    provenance_direct =
      case Map.get(provenance, "feedback_trust_boundaries") do
        %{} = boundaries -> [boundaries]
        _boundaries -> []
      end

    nested =
      provenance
      |> Map.get("sources", [])
      |> Enum.flat_map(fn nested_source ->
        case nested_source |> stringify_keys() |> Map.get("feedback_trust_boundaries") do
          %{} = boundaries -> [boundaries]
          _boundaries -> []
        end
      end)

    direct ++ provenance_direct ++ nested
  end

  defp compact_map(map) do
    Map.reject(map, fn {_key, value} -> is_nil(value) end)
  end

  defp put_if_present(map, _key, value) when value in [nil, []], do: map

  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp put_if_absent(map, key, value) do
    if Map.has_key?(map, key) do
      map
    else
      put_if_present(map, key, value)
    end
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
