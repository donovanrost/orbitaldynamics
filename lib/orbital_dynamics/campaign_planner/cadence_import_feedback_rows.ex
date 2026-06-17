defmodule OrbitalDynamics.CampaignPlanner.CadenceImportFeedbackRows do
  @moduledoc false

  def source_review_rows(rows) do
    rows
    |> Enum.flat_map(&source_review_row/1)
  end

  def all_operational_feedback_rows(rows) do
    rows
    |> Enum.flat_map(&source_operational_feedback_rows/1)
  end

  def source_operational_feedback_metadata(rows) do
    source_report_paths = source_paths(rows)

    %{
      "source_report_contract" => "cadence_import_manifest.v1",
      "source_report_count" => source_report_count(rows, source_report_paths),
      "source_report_paths" => if(source_report_paths == [], do: nil, else: source_report_paths),
      "source_report_row_count" => length(rows),
      "source_import_action_counts" => count_present_values(rows, "import_action"),
      "source_review_type_counts" => count_present_values(rows, "source_review_type"),
      "source_operational_feedback_provenance" => source_operational_feedback_provenance(rows),
      "trust_boundary_status" => trust_boundary_status(rows),
      "trust_boundaries" => trust_boundaries(rows)
    }
    |> compact_map()
  end

  def source_review_metadata(rows) do
    feedback_weight_rows = Enum.map(rows, &feedback_weight_evidence/1)
    weighted_feedback_row_count = weighted_feedback_row_count(feedback_weight_rows)
    feedback_weight_sources = feedback_weight_sources(feedback_weight_rows)
    invalid_sections = invalid_unit_interval_feedback_sections(rows)
    source_report_paths = source_paths(rows)

    %{
      "source_report_contract" => "cadence_import_manifest.v1",
      "source_report_count" => source_report_count(rows, source_report_paths),
      "source_report_paths" => if(source_report_paths == [], do: nil, else: source_report_paths),
      "source_report_row_count" => length(rows),
      "source_review_type_counts" => count_present_values(rows, "review_type"),
      "source_review_action_counts" =>
        count_present_values(rows, ["action", "required_operator_action"]),
      "source_review_queue_counts" =>
        count_present_values(rows, ["review_queue_key", "review_queue"]),
      "weighted_feedback_row_count" =>
        if(weighted_feedback_row_count > 0, do: weighted_feedback_row_count),
      "feedback_weight_sources" =>
        if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources),
      "invalid_operational_feedback_sections" =>
        if(invalid_sections == [], do: nil, else: invalid_sections),
      "trust_boundary_status" => review_trust_boundary_status(rows),
      "trust_boundaries" => review_trust_boundaries(rows)
    }
    |> compact_map()
  end

  defp source_review_row(row) do
    row = stringify_keys(row)

    case Map.get(row, "source_review_row") do
      %{} = source_review_row ->
        [
          source_review_row
          |> stringify_keys()
          |> Map.put_new("approval_status", row["approval_status"])
          |> Map.put_new("required_operator_action", row["required_operator_action"])
          |> Map.put_new("review_queue", row["review_queue"])
          |> Map.put_new("review_queue_key", row["review_queue_key"])
          |> Map.put_new("trust_boundary", cadence_import_trust_boundary(row))
          |> put_if_present(
            "_source_path",
            nested_source_path(row["_source_path"], "source_review_row")
          )
        ]

      _source_review_row ->
        row
        |> cadence_import_row_source_review_row(row["_source_report_trust_boundary"])
        |> source_review_row_with_path(row["_source_path"])
    end
  end

  defp source_review_row_with_path(%{} = source_review_row, source_path) do
    [
      source_review_row
      |> put_if_present("_source_path", nested_source_path(source_path, "source_review_row"))
    ]
  end

  defp source_review_row_with_path(_source_review_row, _source_path), do: []

  defp source_operational_feedback_rows(row) do
    row = stringify_keys(row)
    manifest_trust_boundary = row["_source_report_trust_boundary"]

    cond do
      Map.has_key?(row, "source_operational_feedback") ->
        [
          row
          |> put_if_absent("trust_boundary", manifest_trust_boundary)
        ]

      is_map(row["source_review_row"]) ->
        row["source_review_row"]
        |> stringify_keys()
        |> nested_source_operational_feedback_row(row, manifest_trust_boundary)

      true ->
        []
    end
  end

  defp nested_source_operational_feedback_row(
         source_review_row,
         row,
         manifest_trust_boundary
       ) do
    if Map.has_key?(source_review_row, "source_operational_feedback") do
      [
        source_review_row
        |> Map.put_new("id", row["source_review_row_id"] || row["id"])
        |> Map.put_new(
          "source_review_row_id",
          source_review_row["id"] || row["source_review_row_id"]
        )
        |> Map.put_new(
          "source_review_type",
          row["source_review_type"] || source_review_row["review_type"]
        )
        |> Map.put_new("import_action", row["import_action"])
        |> Map.put_new("approval_status", row["approval_status"])
        |> Map.put_new("required_operator_action", row["required_operator_action"])
        |> Map.put_new(
          "operational_feedback_trust_boundary",
          row["operational_feedback_trust_boundary"]
        )
        |> put_if_absent("trust_boundary", row["trust_boundary"])
        |> Map.put_new("provenance", row["provenance"])
        |> put_if_absent("trust_boundary", manifest_trust_boundary)
        |> Map.put_new(
          "source_operational_feedback_provenance",
          row["source_operational_feedback_provenance"]
        )
        |> put_if_present(
          "_source_path",
          nested_source_path(row["_source_path"], "source_review_row")
        )
      ]
    else
      []
    end
  end

  defp cadence_import_row_source_review_row(row, fallback_trust_boundary) do
    row = stringify_keys(row)

    case Map.get(row, "source_review_type") do
      review_type when is_binary(review_type) and review_type != "" ->
        row
        |> Map.put("review_type", review_type)
        |> put_if_present("id", row["source_review_row_id"] || row["id"])
        |> put_if_present("action", row["source_review_action"])
        |> put_if_present(
          "required_operator_action",
          row["required_operator_action"] || row["source_review_action"]
        )
        |> put_if_present("activity_type", row["activity_type"] || row["realized_type"])
        |> put_if_present("status", row["feedback_status"] || row["realized_status"])
        |> put_if_present(
          "trust_boundary",
          cadence_import_trust_boundary(row, fallback_trust_boundary)
        )

      _review_type ->
        nil
    end
  end

  defp cadence_import_trust_boundary(row, fallback \\ nil) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_review_row", "trust_boundary"]) ||
      get_in(row, ["source_review_row", "provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"] ||
      fallback
  end

  defp source_report_count([], _source_report_paths), do: 0

  defp source_report_count(_rows, source_report_paths) when source_report_paths != [],
    do: length(source_report_paths)

  defp source_report_count(_rows, _source_report_paths), do: 1

  defp source_paths(rows) do
    rows
    |> Enum.map(&Map.get(&1, "_source_path"))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp count_present_values(rows, fields) when is_list(fields) do
    rows
    |> Enum.map(fn row ->
      Enum.find_value(fields, fn field ->
        case Map.get(row, field) do
          value when value in [nil, ""] -> nil
          value -> value
        end
      end)
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp count_present_values(rows, field), do: count_present_values(rows, [field])

  defp feedback_weight_evidence(row) do
    row = stringify_keys(row)

    source =
      [
        "source_feedback",
        "source_operational_timeline",
        "source_command_window",
        "source_maneuver_review"
      ]
      |> Enum.find_value(fn field ->
        case Map.get(row, field) do
          %{} = source -> stringify_keys(source)
          _source -> nil
        end
      end)

    Map.merge(row, source || %{})
  end

  defp weighted_feedback_row_count(rows) do
    Enum.count(rows, fn row ->
      row
      |> stringify_keys()
      |> feedback_weight()
      |> is_number()
    end)
  end

  defp feedback_weight_sources(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row = stringify_keys(row)

      if is_number(feedback_weight(row)) do
        row
        |> feedback_weight_source()
        |> List.wrap()
      else
        []
      end
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp feedback_weight(%{} = row) do
    Enum.find_value(
      feedback_weight_fields(),
      fn key ->
        case numeric_or_nil(Map.get(row, key)) do
          weight when is_number(weight) and weight > 0.0 -> weight * 1.0
          _weight -> nil
        end
      end
    )
  end

  defp feedback_weight_fields do
    ["feedback_weight", "feedback_sample_weight", "sample_weight", "confidence_weight"]
  end

  defp feedback_weight_source(%{} = row) do
    Enum.find_value(
      [
        "feedback_weight_source",
        "feedback_sample_weight_source",
        "sample_weight_source",
        "confidence_weight_source"
      ],
      fn key ->
        case Map.get(row, key) do
          source when is_binary(source) and source != "" -> source
          _source -> nil
        end
      end
    )
  end

  defp invalid_unit_interval_feedback_sections(rows) do
    rows
    |> Enum.map(&feedback_weight_evidence/1)
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {row, row_index} ->
      row
      |> unit_interval_feedback_values()
      |> Enum.flat_map(fn {field, value} ->
        case unit_interval_number_status(value) do
          {:ok, _value} ->
            []

          :missing ->
            []

          {:invalid_number, number} ->
            [
              invalid_unit_interval_section(
                row,
                row_index,
                field,
                "value_must_be_between_0_and_1",
                "invalid_feedback_value",
                number
              )
            ]

          {:invalid_shape, shape} ->
            [
              invalid_unit_interval_section(
                row,
                row_index,
                field,
                "entry_must_be_unit_interval_number",
                "invalid_feedback_shape",
                stringify_keys(shape)
              )
            ]
        end
      end)
    end)
    |> Enum.uniq()
  end

  defp invalid_unit_interval_section(row, row_index, field, reason, invalid_key, invalid_value) do
    %{
      "field" => "operator_review.rows.#{field}",
      "reason" => reason,
      invalid_key => invalid_value,
      "row_id" => row["id"] || row["activity_id"] || row["timeline_id"],
      "row_index" => row_index
    }
    |> compact_map()
  end

  defp unit_interval_feedback_values(row) do
    [
      {"contact_success_factor", row["contact_success_factor"]},
      {"observation_success_factor", row["observation_success_factor"]},
      {"command_success_factor", row["command_success_factor"]},
      {"maneuver_success_factor", row["maneuver_success_factor"]},
      {"completed_fraction", row["completed_fraction"]},
      {"image_quality_score", row["image_quality_score"]},
      {"product_quality_score", row["product_quality_score"]},
      {"quality_score", row["quality_score"]},
      {"cloud_cover_fraction", row["cloud_cover_fraction"]},
      {"cloud_fraction", row["cloud_fraction"]},
      {"cloud_cover", row["cloud_cover"]},
      {"blur_score", row["blur_score"]},
      {"image_blur_score", row["image_blur_score"]},
      {"sharpness_loss_fraction", row["sharpness_loss_fraction"]},
      {"quality.image_quality_score", get_in(row, ["quality", "image_quality_score"])},
      {"quality.product_quality_score", get_in(row, ["quality", "product_quality_score"])},
      {"quality.score", get_in(row, ["quality", "score"])},
      {"quality.cloud_cover_fraction", get_in(row, ["quality", "cloud_cover_fraction"])},
      {"quality.cloud_fraction", get_in(row, ["quality", "cloud_fraction"])},
      {"quality.cloud_cover", get_in(row, ["quality", "cloud_cover"])},
      {"quality.blur_score", get_in(row, ["quality", "blur_score"])},
      {"quality.image_blur_score", get_in(row, ["quality", "image_blur_score"])},
      {"quality.sharpness_loss_fraction", get_in(row, ["quality", "sharpness_loss_fraction"])},
      {"metadata.image_quality_score", get_in(row, ["metadata", "image_quality_score"])},
      {"metadata.product_quality_score", get_in(row, ["metadata", "product_quality_score"])},
      {"metadata.quality_score", get_in(row, ["metadata", "quality_score"])},
      {"metadata.cloud_cover_fraction", get_in(row, ["metadata", "cloud_cover_fraction"])},
      {"metadata.cloud_fraction", get_in(row, ["metadata", "cloud_fraction"])},
      {"metadata.cloud_cover", get_in(row, ["metadata", "cloud_cover"])},
      {"metadata.blur_score", get_in(row, ["metadata", "blur_score"])},
      {"metadata.image_blur_score", get_in(row, ["metadata", "image_blur_score"])},
      {"metadata.sharpness_loss_fraction", get_in(row, ["metadata", "sharpness_loss_fraction"])}
    ]
    |> Enum.reject(fn {_field, value} -> feedback_value_missing?(value) end)
  end

  defp unit_interval_number_status(value) do
    case numeric_or_nil(value) do
      number when is_number(number) and number >= 0.0 and number <= 1.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        if feedback_value_missing?(value), do: :missing, else: {:invalid_shape, value}
    end
  end

  defp source_operational_feedback_provenance(rows) do
    rows
    |> Enum.map(&Map.get(&1, "source_operational_feedback_provenance"))
    |> Enum.filter(&is_map/1)
    |> case do
      [] -> nil
      [provenance] -> provenance
      provenances -> %{"sources" => provenances, "source_count" => length(provenances)}
    end
  end

  defp trust_boundary_status(rows) do
    case trust_boundaries(rows) do
      [] -> nil
      _boundaries -> "declared"
    end
  end

  defp trust_boundaries(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["operational_feedback_trust_boundary"],
        row["trust_boundary"],
        get_in(row, ["provenance", "trust_boundary"]),
        operational_feedback_provenance_trust_boundaries(
          row["source_operational_feedback_provenance"]
        )
      ]
      |> List.flatten()
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp review_trust_boundary_status(rows) do
    case review_trust_boundaries(rows) do
      boundaries when is_list(boundaries) and boundaries != [] -> "declared"
      _boundaries -> nil
    end
  end

  defp review_trust_boundaries(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["trust_boundary"],
        get_in(row, ["provenance", "trust_boundary"]),
        row["_source_report_trust_boundary"]
      ]
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp operational_feedback_provenance_trust_boundaries(%{} = provenance) do
    provenance = stringify_keys(provenance)

    direct_boundaries = [
      Map.get(provenance, "trust_boundary"),
      Map.get(provenance, "trust_boundaries")
    ]

    nested_boundaries =
      provenance
      |> Map.get("sources", [])
      |> List.wrap()
      |> Enum.flat_map(fn
        %{} = source ->
          source = stringify_keys(source)

          [
            source["trust_boundary"],
            source["trust_boundaries"]
          ]
          |> List.flatten()

        _source ->
          []
      end)

    (direct_boundaries ++ nested_boundaries)
    |> List.flatten()
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp operational_feedback_provenance_trust_boundaries(_provenance), do: []

  defp nested_source_path(source_path, suffix) when is_binary(source_path) and source_path != "",
    do: "#{source_path}.#{suffix}"

  defp nested_source_path(_source_path, _suffix), do: nil

  defp put_if_present(map, _key, value) when value in [nil, "", [], %{}], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp put_if_absent(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_if_absent(map, key, value) do
    Map.put_new(map, key, value)
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
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
