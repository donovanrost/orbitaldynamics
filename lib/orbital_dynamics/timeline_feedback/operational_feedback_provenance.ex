defmodule OrbitalDynamics.TimelineFeedback.OperationalFeedbackProvenance do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.ArtifactValue

  def build(rows, operational_feedback, source_counts, schema_contract, trust_specs) do
    input_keys = operational_feedback_data_keys(operational_feedback)
    excluded_count = Map.get(source_counts, "source_operational_feedback_excluded_count", 0)

    if input_keys == [] and excluded_count == 0 do
      nil
    else
      trust_boundaries = operational_feedback_trust_boundaries(rows)
      weighted_feedback_row_count = weighted_feedback_row_count(rows)
      feedback_weight_sources = feedback_weight_sources(rows)
      source_quality_counts = count_by(rows, "realized_source_quality")

      feedback_trust_boundaries =
        operational_feedback_trust_boundaries_by_key(rows, operational_feedback, trust_specs)

      source =
        source_counts
        |> Map.merge(%{
          "source" => "timeline_feedback_report.rows",
          "source_report_contract" => schema_contract,
          "source_report_count" => 1,
          "source_report_row_count" => length(rows),
          "input_keys" => input_keys,
          "realized_activity_count" => timeline_feedback_realized_row_count(rows),
          "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
          "trust_boundaries" => trust_boundaries
        })
        |> ArtifactValue.maybe_put(
          "weighted_feedback_row_count",
          positive_integer_or_nil(weighted_feedback_row_count)
        )
        |> ArtifactValue.maybe_put(
          "feedback_weight_sources",
          if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources)
        )
        |> ArtifactValue.maybe_put(
          "source_realized_source_quality_counts",
          if(map_size(source_quality_counts) == 0, do: nil, else: source_quality_counts)
        )
        |> ArtifactValue.maybe_put(
          "feedback_trust_boundaries",
          if(map_size(feedback_trust_boundaries) == 0, do: nil, else: feedback_trust_boundaries)
        )
        |> ArtifactValue.compact_map()

      %{
        "model" => "timeline_feedback_report_rows_to_operational_feedback",
        "merge_order" => ["timeline_feedback_report.rows"],
        "input_keys" => input_keys,
        "source_count" => 1,
        "sources" => [source],
        "explicit_request_override" => false
      }
    end
  end

  defp operational_feedback_data_keys(feedback) when is_map(feedback) do
    feedback
    |> Enum.filter(fn {_key, value} -> is_map(value) and map_size(value) > 0 end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.sort()
  end

  defp timeline_feedback_realized_row_count(rows) do
    Enum.reduce(rows, 0, fn row, count ->
      case Map.get(row, "status") do
        "matched" -> count + Map.get(row, "realized_match_count", 1)
        "realized_only" -> count + Map.get(row, "realized_match_count", 1)
        _status -> count
      end
    end)
  end

  defp weighted_feedback_row_count(rows) do
    Enum.count(rows, fn row ->
      case Map.get(row, "feedback_weight") do
        weight when is_number(weight) and weight > 0.0 -> true
        _weight -> false
      end
    end)
  end

  defp positive_integer_or_nil(value) when is_integer(value) and value > 0, do: value
  defp positive_integer_or_nil(_value), do: nil

  defp feedback_weight_sources(rows) do
    rows
    |> Enum.filter(fn row ->
      case Map.get(row, "feedback_weight") do
        weight when is_number(weight) and weight > 0.0 -> true
        _weight -> false
      end
    end)
    |> Enum.map(& &1["feedback_weight_source"])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp operational_feedback_trust_boundaries(rows) do
    rows
    |> Enum.flat_map(&row_feedback_trust_boundaries/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp operational_feedback_trust_boundaries_by_key(
         rows,
         operational_feedback,
         trust_specs
       ) do
    Enum.reduce(trust_specs, %{}, fn {field, key_fun, value_fun}, boundaries ->
      feedback = Map.get(operational_feedback, field, %{})

      if is_map(feedback) and map_size(feedback) > 0 do
        field_boundaries =
          rows
          |> Enum.reduce(%{}, fn row, field_boundaries ->
            key = row |> key_fun.() |> ArtifactValue.stringify_scalar()

            if key in [nil, ""] or is_nil(value_fun.(row)) do
              field_boundaries
            else
              case row_feedback_trust_boundaries(row) do
                [] ->
                  field_boundaries

                trust_boundaries ->
                  Map.update(field_boundaries, key, trust_boundaries, fn existing ->
                    (existing ++ trust_boundaries)
                    |> Enum.uniq()
                    |> Enum.sort()
                  end)
              end
            end
          end)
          |> Enum.reject(fn {_key, trust_boundaries} -> trust_boundaries == [] end)
          |> Map.new()

        if map_size(field_boundaries) == 0 do
          boundaries
        else
          Map.put(boundaries, field, field_boundaries)
        end
      else
        boundaries
      end
    end)
  end

  defp row_feedback_trust_boundaries(row) do
    context = Map.get(row, "realized_activity_context", %{})
    provenance = Map.get(row, "realized_provenance", %{})
    context_provenance = Map.get(context, "provenance", %{})

    [
      Map.get(row, "realized_trust_boundary"),
      Map.get(provenance, "trust_boundary"),
      Map.get(context, "trust_boundary"),
      Map.get(context_provenance, "trust_boundary")
    ]
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end
end
