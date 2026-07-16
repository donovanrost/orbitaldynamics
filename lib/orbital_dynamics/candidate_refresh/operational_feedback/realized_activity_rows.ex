defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.RealizedActivityRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues
  alias OrbitalDynamics.TimelineFeedback

  def sanitize_realized_activity_rows(rows) do
    Enum.map(rows, &sanitize_realized_activity_row/1)
  end

  def sanitize_realized_activity_row(%{} = row) do
    row = RowValues.stringify_keys(row)

    realized_activity_unit_interval_paths()
    |> Enum.reduce(row, fn {_field, path}, sanitized ->
      case unit_interval_number_status(get_in(sanitized, path)) do
        {:invalid_number, _number} -> delete_feedback_path(sanitized, path)
        {:invalid_shape, _shape} -> delete_feedback_path(sanitized, path)
        _status -> sanitized
      end
    end)
  end

  def sanitize_realized_activity_row(row), do: row

  def realized_activity_feedback(feedback, prior_candidates) when is_map(feedback) do
    case realized_activity_report(feedback, prior_candidates) do
      %{} = report -> TimelineFeedback.operational_feedback(report)
      _report -> %{}
    end
  end

  def realized_activity_feedback(_feedback, _prior_candidates), do: %{}

  def realized_activity_report(feedback, prior_candidates) when is_map(feedback) do
    case Map.get(feedback, "realized_activities") do
      rows when is_list(rows) and rows != [] ->
        realized_activity_report_for_rows(rows, prior_candidates)

      _rows ->
        nil
    end
  end

  def realized_activity_report(_feedback, _prior_candidates), do: nil

  def realized_activity_report_for_rows([], _prior_candidates), do: nil

  def realized_activity_report_for_rows(rows, prior_candidates) when is_list(rows) do
    realized_rows = sanitize_realized_activity_rows(rows)

    TimelineFeedback.reconcile(prior_candidates, realized_rows)
  end

  def realized_activity_source(%{
        "operational_feedback_provenance" => %{"sources" => sources}
      })
      when is_list(sources) do
    Enum.find(sources, &(&1["source"] == "timeline_feedback_report.rows")) || %{}
  end

  def realized_activity_source(_report), do: %{}

  def put_source_realized_activity_summary(provenance, rows) when is_list(rows) do
    provenance
    |> maybe_put(
      "source_realized_activity_type_counts",
      realized_activity_source_counts(rows, &realized_activity_type/1)
    )
    |> maybe_put(
      "source_realized_direction_counts",
      realized_activity_source_counts(rows, &realized_activity_direction/1)
    )
    |> maybe_put(
      "source_realized_status_counts",
      realized_activity_source_counts(rows, &realized_activity_status/1)
    )
    |> maybe_put(
      "source_realized_feedback_weight_source_counts",
      realized_activity_source_counts(rows, &realized_activity_feedback_weight_source/1)
    )
    |> maybe_put(
      "source_realized_trust_boundary_status",
      source_realized_activity_trust_boundary_status(rows)
    )
    |> maybe_put(
      "source_realized_trust_boundaries",
      source_realized_activity_trust_boundaries(rows)
    )
  end

  def put_source_realized_activity_summary(provenance, _rows), do: provenance

  def realized_activity_unit_interval_values(row) do
    realized_activity_unit_interval_paths()
    |> Enum.map(fn {field, path} -> {field, get_in(row, path)} end)
    |> Enum.reject(fn {_field, value} -> value_missing?(value) end)
  end

  def realized_activity_nonnegative_number_values(row) do
    realized_activity_nonnegative_number_paths()
    |> Enum.map(fn {field, path} -> {field, get_in(row, path)} end)
    |> Enum.reject(fn {_field, value} -> value_missing?(value) end)
  end

  def value_missing?(nil), do: true
  def value_missing?(""), do: true
  def value_missing?(_value), do: false

  def unit_interval_number_status(value) do
    case RowValues.numeric_value(value) do
      number when is_number(number) and number >= 0.0 and number <= 1.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        if value_missing?(value), do: :missing, else: {:invalid_shape, value}
    end
  end

  def nonnegative_number_status(value) do
    case RowValues.numeric_value(value) do
      number when is_number(number) and number >= 0.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        if value_missing?(value), do: :missing, else: {:invalid_shape, value}
    end
  end

  def row_id(row) do
    raw_identifier(row["id"]) ||
      raw_identifier(row["realized_activity_id"]) ||
      raw_identifier(row["activity_id"])
  end

  def nested_identifier(row, object_key, identity_keys) do
    case Map.get(row, object_key) do
      %{} = object -> Enum.find_value(identity_keys, &Map.get(object, &1))
      _value -> nil
    end
  end

  def raw_identifier(nil), do: nil
  def raw_identifier(value) when is_binary(value) and value != "", do: value
  def raw_identifier(value) when is_atom(value), do: Atom.to_string(value)
  def raw_identifier(value) when is_integer(value), do: Integer.to_string(value)
  def raw_identifier(_value), do: nil

  def invalid_sections(%{"realized_activities" => rows}) when is_list(rows) do
    rows
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {row, index} ->
      case RowValues.stringify_keys(row) do
        %{} = row ->
          (invalid_realized_activity_identity_sections(row) ++
             invalid_realized_activity_unit_interval_sections(row) ++
             invalid_realized_activity_nonnegative_number_sections(row))
          |> Enum.map(&Map.put(&1, "row_index", index))

        invalid_shape ->
          [
            %{
              "field" => "realized_activities",
              "reason" => "entry_must_be_object",
              "row_index" => index,
              "invalid_feedback_shape" => RowValues.encode_value(invalid_shape)
            }
          ]
      end
    end)
  end

  def invalid_sections(_feedback), do: []

  defp realized_activity_source_counts(rows, value_fun) do
    rows
    |> Enum.map(value_fun)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> non_empty_map()
  end

  defp realized_activity_type(row) do
    row
    |> RowValues.stringify_keys()
    |> Map.get("type")
    |> RowValues.encode_value()
  end

  defp realized_activity_direction(row) do
    row
    |> RowValues.stringify_keys()
    |> Map.get("direction")
    |> RowValues.encode_value()
  end

  defp realized_activity_status(row) do
    row
    |> RowValues.stringify_keys()
    |> Map.get("status")
    |> RowValues.encode_value()
  end

  defp realized_activity_feedback_weight_source(row) do
    row = RowValues.stringify_keys(row)

    Enum.find_value(
      [
        "feedback_weight_source",
        "feedback_sample_weight_source",
        "sample_weight_source",
        "confidence_weight_source"
      ],
      &Map.get(row, &1)
    )
    |> RowValues.encode_value()
  end

  defp source_realized_activity_trust_boundary_status(rows) do
    if source_realized_activity_trust_boundaries(rows) == [] do
      "missing"
    else
      "declared"
    end
  end

  defp source_realized_activity_trust_boundaries(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row = RowValues.stringify_keys(row)

      [
        Map.get(row, "trust_boundary"),
        Map.get(row, "_source_report_trust_boundary"),
        get_in(row, ["provenance", "trust_boundary"]),
        get_in(row, ["metadata", "trust_boundary"])
      ]
    end)
    |> normalize_trust_boundaries()
  end

  defp invalid_realized_activity_identity_sections(row) do
    row
    |> realized_activity_identity_values()
    |> Enum.flat_map(fn {field, value} ->
      case raw_identifier(value) do
        nil ->
          []

        identifier ->
          if RowValues.stable_id_or_nil(identifier) do
            []
          else
            [
              %{
                "field" => "realized_activities.#{field}",
                "key" => identifier,
                "reason" => "key_must_be_stable_id",
                "row_id" => row_id(row)
              }
              |> RowValues.compact_nil_values()
            ]
          end
      end
    end)
  end

  defp realized_activity_identity_values(row) do
    [
      {"id", row["id"]},
      {"realized_activity_id", row["realized_activity_id"]},
      {"planned_activity_id", row["planned_activity_id"]},
      {"activity_id", row["activity_id"]},
      {"timeline_id", row["timeline_id"]},
      {"metadata.timeline_id", get_in(row, ["metadata", "timeline_id"])},
      {"scenario_id", row["scenario_id"]},
      {"metadata.scenario_id", get_in(row, ["metadata", "scenario_id"])},
      {"ground_station_id", row["ground_station_id"]},
      {"station_id", row["station_id"]},
      {"metadata.ground_station_id", get_in(row, ["metadata", "ground_station_id"])},
      {"metadata.station_id", get_in(row, ["metadata", "station_id"])},
      {"target_id", row["target_id"]},
      {"metadata.target_id", get_in(row, ["metadata", "target_id"])},
      {"spacecraft_id", row["spacecraft_id"]},
      {"satellite_id", row["satellite_id"]},
      {"metadata.spacecraft_id", get_in(row, ["metadata", "spacecraft_id"])},
      {"resource_id", row["resource_id"]},
      {"source_window_id", row["source_window_id"]},
      {"metadata.source_window_id", get_in(row, ["metadata", "source_window_id"])},
      {"target.id", nested_identifier(row, "target", ["target_id", "id"])},
      {"station.id", nested_identifier(row, "station", ["station_id", "id"])},
      {"ground_station.id",
       nested_identifier(row, "ground_station", ["ground_station_id", "station_id", "id"])},
      {"spacecraft.id", nested_identifier(row, "spacecraft", ["spacecraft_id", "id"])},
      {"satellite.id", nested_identifier(row, "satellite", ["satellite_id", "id"])},
      {"source_window.id", nested_identifier(row, "source_window", ["source_window_id", "id"])}
    ]
  end

  defp invalid_realized_activity_unit_interval_sections(row) do
    row
    |> realized_activity_unit_interval_values()
    |> Enum.flat_map(fn {field, value} ->
      case unit_interval_number_status(value) do
        {:ok, _value} ->
          []

        :missing ->
          []

        {:invalid_number, number} ->
          [
            %{
              "field" => "realized_activities.#{field}",
              "reason" => "entry_must_be_unit_interval_number",
              "invalid_feedback_shape" => number,
              "row_id" => row_id(row)
            }
            |> RowValues.compact_nil_values()
          ]

        {:invalid_shape, shape} ->
          [
            %{
              "field" => "realized_activities.#{field}",
              "reason" => "entry_must_be_unit_interval_number",
              "invalid_feedback_shape" => RowValues.encode_value(shape),
              "row_id" => row_id(row)
            }
            |> RowValues.compact_nil_values()
          ]
      end
    end)
  end

  defp invalid_realized_activity_nonnegative_number_sections(row) do
    row
    |> realized_activity_nonnegative_number_values()
    |> Enum.flat_map(fn {field, value} ->
      case nonnegative_number_status(value) do
        {:ok, _value} ->
          []

        :missing ->
          []

        {:invalid_number, number} ->
          [
            %{
              "field" => "realized_activities.#{field}",
              "reason" => "entry_must_be_nonnegative_number",
              "invalid_feedback_shape" => number,
              "row_id" => row_id(row)
            }
            |> RowValues.compact_nil_values()
          ]

        {:invalid_shape, shape} ->
          [
            %{
              "field" => "realized_activities.#{field}",
              "reason" => "entry_must_be_nonnegative_number",
              "invalid_feedback_shape" => RowValues.encode_value(shape),
              "row_id" => row_id(row)
            }
            |> RowValues.compact_nil_values()
          ]
      end
    end)
  end

  defp delete_feedback_path(row, [field]), do: Map.delete(row, field)

  defp delete_feedback_path(row, [section, field]) do
    case Map.get(row, section) do
      %{} = section_map ->
        section_map = Map.delete(section_map, field)

        if map_size(section_map) == 0 do
          Map.delete(row, section)
        else
          Map.put(row, section, section_map)
        end

      _section ->
        row
    end
  end

  defp realized_activity_nonnegative_number_paths do
    [
      {"feedback_weight", ["feedback_weight"]},
      {"feedback_sample_weight", ["feedback_sample_weight"]},
      {"sample_weight", ["sample_weight"]},
      {"confidence_weight", ["confidence_weight"]}
    ]
  end

  defp realized_activity_unit_interval_paths do
    [
      {"completed_fraction", ["completed_fraction"]},
      {"image_quality_score", ["image_quality_score"]},
      {"product_quality_score", ["product_quality_score"]},
      {"quality_score", ["quality_score"]},
      {"cloud_cover_fraction", ["cloud_cover_fraction"]},
      {"cloud_fraction", ["cloud_fraction"]},
      {"cloud_cover", ["cloud_cover"]},
      {"blur_score", ["blur_score"]},
      {"image_blur_score", ["image_blur_score"]},
      {"sharpness_loss_fraction", ["sharpness_loss_fraction"]},
      {"quality.image_quality_score", ["quality", "image_quality_score"]},
      {"quality.product_quality_score", ["quality", "product_quality_score"]},
      {"quality.score", ["quality", "score"]},
      {"quality.cloud_cover_fraction", ["quality", "cloud_cover_fraction"]},
      {"quality.cloud_fraction", ["quality", "cloud_fraction"]},
      {"quality.cloud_cover", ["quality", "cloud_cover"]},
      {"quality.blur_score", ["quality", "blur_score"]},
      {"quality.image_blur_score", ["quality", "image_blur_score"]},
      {"quality.sharpness_loss_fraction", ["quality", "sharpness_loss_fraction"]},
      {"metadata.image_quality_score", ["metadata", "image_quality_score"]},
      {"metadata.product_quality_score", ["metadata", "product_quality_score"]},
      {"metadata.quality_score", ["metadata", "quality_score"]},
      {"metadata.cloud_cover_fraction", ["metadata", "cloud_cover_fraction"]},
      {"metadata.cloud_fraction", ["metadata", "cloud_fraction"]},
      {"metadata.cloud_cover", ["metadata", "cloud_cover"]},
      {"metadata.blur_score", ["metadata", "blur_score"]},
      {"metadata.image_blur_score", ["metadata", "image_blur_score"]},
      {"metadata.sharpness_loss_fraction", ["metadata", "sharpness_loss_fraction"]}
    ]
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp normalize_trust_boundaries(values) do
    values
    |> Enum.map(&RowValues.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
