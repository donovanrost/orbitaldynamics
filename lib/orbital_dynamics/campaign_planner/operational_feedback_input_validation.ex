defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedbackInputValidation do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{FeedbackNumericValues, ValueEncoding}

  @unit_interval_map_fields [
    "contact_success_rate",
    "observation_success_rate",
    "image_quality_score",
    "cloud_cover_fraction",
    "blur_score",
    "maneuver_success_rate",
    "command_success_rate",
    "station_throughput_factor"
  ]

  @nonnegative_map_fields [
    "downlink_demand_mb",
    "target_priority_overrides"
  ]

  @string_list_map_fields ["downlink_demand_sources"]
  @string_map_fields ["image_quality_status", "image_quality_source"]

  @nested_map_fields [
    "maneuver_execution_uncertainty",
    "resource_margin_overrides",
    "resource_availability_overrides",
    "availability_overrides"
  ]

  def replay_sections(rows, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    rows
    |> Enum.map(&stringify_keys.(&1))
    |> Enum.flat_map(&replay_row_sections(&1, callbacks))
  end

  def put_sections(source, invalid_sections) do
    invalid_sections =
      (Map.get(source, "invalid_operational_feedback_sections", []) ++ invalid_sections)
      |> Enum.uniq()

    source_operational_feedback =
      source
      |> Map.get("source_operational_feedback", %{})
      |> Map.merge(%{"invalid_feedback_sections" => invalid_sections})

    source
    |> Map.put(
      "input_keys",
      (Map.get(source, "input_keys", []) ++ ["invalid_operational_feedback_input"])
      |> Enum.uniq()
    )
    |> Map.put("invalid_operational_feedback_input", true)
    |> Map.put(
      "invalid_operational_feedback_input_reason",
      "operational_feedback_sections_invalid"
    )
    |> Map.put("invalid_operational_feedback_sections", invalid_sections)
    |> Map.put("source_operational_feedback", source_operational_feedback)
  end

  def feedback_weight_evidence(row), do: feedback_weight_evidence(row, callbacks())

  def feedback_weight_evidence(row, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    row = stringify_keys.(row)

    source =
      [
        "source_feedback",
        "source_operational_timeline",
        "source_command_window",
        "source_maneuver_review"
      ]
      |> Enum.find_value(fn field ->
        case Map.get(row, field) do
          %{} = source -> stringify_keys.(source)
          _source -> nil
        end
      end)

    Map.merge(row, source || %{})
  end

  def operator_review_invalid_unit_interval_sections(rows),
    do: operator_review_invalid_unit_interval_sections(rows, callbacks())

  def operator_review_invalid_unit_interval_sections(rows, callbacks) do
    rows
    |> Enum.map(&feedback_weight_evidence(&1, callbacks))
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {row, row_index} ->
      row
      |> operator_review_unit_interval_values(callbacks)
      |> Enum.flat_map(&operator_review_unit_interval_section(&1, row, row_index, callbacks))
    end)
    |> Enum.uniq()
  end

  def sections(feedback, callbacks) when is_map(feedback) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    feedback = stringify_keys.(feedback)

    scalar_map_fields = @unit_interval_map_fields ++ @nonnegative_map_fields

    map_fields =
      scalar_map_fields ++ @string_list_map_fields ++ @string_map_fields ++ @nested_map_fields

    invalid_key_sections =
      map_fields
      |> Enum.flat_map(&invalid_key_sections(feedback, &1, callbacks))

    scalar_sections =
      scalar_map_fields
      |> Enum.flat_map(&invalid_field_sections(feedback, &1, callbacks))

    unit_interval_entry_sections =
      @unit_interval_map_fields
      |> Enum.flat_map(&invalid_unit_interval_sections(feedback, &1, callbacks))

    nonnegative_entry_sections =
      @nonnegative_map_fields
      |> Enum.flat_map(&invalid_nonnegative_sections(feedback, &1, callbacks))

    string_list_sections =
      @string_list_map_fields
      |> Enum.flat_map(&invalid_string_list_sections(feedback, &1, callbacks))

    string_sections =
      @string_map_fields
      |> Enum.flat_map(&invalid_string_sections(feedback, &1, callbacks))

    nested_sections =
      @nested_map_fields
      |> Enum.flat_map(&invalid_nested_sections(feedback, &1, callbacks))

    (invalid_key_sections ++
       scalar_sections ++
       unit_interval_entry_sections ++
       nonnegative_entry_sections ++
       string_list_sections ++
       string_sections ++
       nested_sections)
    |> Enum.sort_by(&{&1["field"], Map.get(&1, "key", ""), &1["reason"]})
  end

  def sections(_feedback, _callbacks), do: []

  defp replay_row_sections(row, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    feedback = Map.get(row, "source_operational_feedback")
    context = replay_row_context(row)

    case feedback do
      %{} = feedback ->
        feedback
        |> replay_source_sections(callbacks)
        |> Enum.map(&Map.merge(&1, context))

      feedback ->
        [
          %{
            "field" => "source_operational_feedback",
            "reason" => "strategy_operational_feedback_must_be_object",
            "invalid_feedback_shape" => stringify_keys.(feedback)
          }
          |> Map.merge(context)
        ]
    end
  end

  defp replay_source_sections(feedback, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    feedback = stringify_keys.(feedback)

    wrapped_sections =
      feedback
      |> Map.get("invalid_feedback_sections", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys.(&1))

    wrapped_shape_sections =
      case Map.get(feedback, "invalid_feedback_shape") do
        nil ->
          []

        invalid_feedback_shape ->
          [
            %{
              "field" => "source_operational_feedback",
              "reason" => "strategy_operational_feedback_must_be_object",
              "invalid_feedback_shape" => stringify_keys.(invalid_feedback_shape)
            }
          ]
      end

    (wrapped_sections ++ wrapped_shape_sections ++ sections(feedback, callbacks))
    |> Enum.uniq()
  end

  defp replay_row_context(row) do
    %{
      "row_id" => row["id"] || row["source_review_row_id"],
      "source_review_row_id" => row["source_review_row_id"],
      "review_type" => row["review_type"],
      "source_review_type" => row["source_review_type"],
      "action" => row["action"] || row["required_operator_action"],
      "import_action" => row["import_action"]
    }
    |> compact()
  end

  defp operator_review_unit_interval_section({field, value}, row, row_index, callbacks) do
    unit_interval_number_status = Keyword.fetch!(callbacks, :unit_interval_number_status)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    case unit_interval_number_status.(value) do
      {:ok, _value} ->
        []

      :missing ->
        []

      {:invalid_number, number} ->
        [
          invalid_operator_review_unit_interval_section(
            row,
            row_index,
            field,
            "value_must_be_between_0_and_1",
            "invalid_feedback_value",
            number,
            callbacks
          )
        ]

      {:invalid_shape, shape} ->
        [
          invalid_operator_review_unit_interval_section(
            row,
            row_index,
            field,
            "entry_must_be_unit_interval_number",
            "invalid_feedback_shape",
            stringify_keys.(shape),
            callbacks
          )
        ]
    end
  end

  defp invalid_operator_review_unit_interval_section(
         row,
         row_index,
         field,
         reason,
         invalid_key,
         invalid_value,
         callbacks
       ) do
    %{
      "field" => "operator_review.rows.#{field}",
      "reason" => reason,
      invalid_key => invalid_value,
      "row_id" => row["id"] || row["activity_id"] || row["timeline_id"],
      "row_index" => row_index
    }
    |> compact(callbacks)
  end

  defp operator_review_unit_interval_values(row, callbacks) do
    feedback_value_missing? = Keyword.fetch!(callbacks, :feedback_value_missing?)

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
    |> Enum.reject(fn {_field, value} -> feedback_value_missing?.(value) end)
  end

  defp invalid_key_sections(feedback, field, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    operational_feedback_key? = Keyword.fetch!(callbacks, :operational_feedback_key?)

    case Map.get(feedback, field) do
      %{} = entries ->
        entries
        |> stringify_keys.()
        |> Enum.flat_map(fn {key, _value} ->
          if operational_feedback_key?.(key) do
            []
          else
            [
              %{
                "field" => field,
                "key" => invalid_key_label(key),
                "reason" => "key_must_be_stable_id"
              }
            ]
          end
        end)

      _entries ->
        []
    end
  end

  defp invalid_key_label(key) when is_binary(key), do: key
  defp invalid_key_label(key), do: inspect(key)

  defp invalid_unit_interval_sections(feedback, field, callbacks) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        []

      true ->
        stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
        numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

        feedback
        |> Map.fetch!(field)
        |> stringify_keys.()
        |> Enum.flat_map(fn {key, value} ->
          case numeric_or_nil.(value) do
            number when is_number(number) and number >= 0.0 and number <= 1.0 ->
              []

            number when is_number(number) ->
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "value_must_be_between_0_and_1",
                  "invalid_feedback_value" => number
                }
              ]

            _value ->
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "entry_must_be_unit_interval_number",
                  "invalid_feedback_shape" => stringify_keys.(value)
                }
              ]
          end
        end)
    end
  end

  defp invalid_field_sections(feedback, field, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    if Map.has_key?(feedback, field) and not is_map(Map.get(feedback, field)) do
      [
        %{
          "field" => field,
          "reason" => "field_must_be_object",
          "invalid_feedback_shape" => stringify_keys.(Map.get(feedback, field))
        }
      ]
    else
      []
    end
  end

  defp invalid_nonnegative_sections(feedback, field, callbacks) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        []

      true ->
        stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
        numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

        feedback
        |> Map.fetch!(field)
        |> stringify_keys.()
        |> Enum.flat_map(fn {key, value} ->
          case numeric_or_nil.(value) do
            number when is_number(number) and number >= 0.0 ->
              []

            number when is_number(number) ->
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "entry_must_be_nonnegative_number",
                  "invalid_feedback_shape" => number
                }
              ]

            _value ->
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "entry_must_be_number",
                  "invalid_feedback_shape" => stringify_keys.(value)
                }
              ]
          end
        end)
    end
  end

  defp invalid_string_list_sections(feedback, field, callbacks) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        [
          %{
            "field" => field,
            "reason" => "field_must_be_object",
            "invalid_feedback_shape" => stringify(callbacks, Map.get(feedback, field))
          }
        ]

      true ->
        stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

        feedback
        |> Map.fetch!(field)
        |> stringify_keys.()
        |> Enum.flat_map(fn
          {key, values} when is_list(values) ->
            if Enum.all?(values, &valid_source_string?/1) do
              []
            else
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "entry_must_be_string_array",
                  "invalid_feedback_shape" => stringify_keys.(values)
                }
              ]
            end

          {key, value} ->
            [
              %{
                "field" => field,
                "key" => key,
                "reason" => "entry_must_be_string_array",
                "invalid_feedback_shape" => stringify_keys.(value)
              }
            ]
        end)
    end
  end

  defp invalid_string_sections(feedback, field, callbacks) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        [
          %{
            "field" => field,
            "reason" => "field_must_be_object",
            "invalid_feedback_shape" => stringify(callbacks, Map.get(feedback, field))
          }
        ]

      true ->
        stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

        feedback
        |> Map.fetch!(field)
        |> stringify_keys.()
        |> Enum.flat_map(fn
          {_key, value} when is_binary(value) and value != "" ->
            []

          {_key, value} when is_atom(value) and not is_nil(value) ->
            []

          {key, value} ->
            [
              %{
                "field" => field,
                "key" => key,
                "reason" => "entry_must_be_string",
                "invalid_feedback_shape" => stringify_keys.(value)
              }
            ]
        end)
    end
  end

  defp valid_source_string?(value) when is_binary(value), do: value != ""
  defp valid_source_string?(value) when is_atom(value), do: not is_nil(value)
  defp valid_source_string?(_value), do: false

  defp invalid_nested_sections(feedback, field, callbacks) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        [
          %{
            "field" => field,
            "reason" => "field_must_be_object",
            "invalid_feedback_shape" => stringify(callbacks, Map.get(feedback, field))
          }
        ]

      true ->
        stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

        feedback
        |> Map.fetch!(field)
        |> stringify_keys.()
        |> Enum.flat_map(fn
          {_key, %{}} ->
            []

          {key, value} ->
            [
              %{
                "field" => field,
                "key" => key,
                "reason" => "entry_must_be_object",
                "invalid_feedback_shape" => stringify_keys.(value)
              }
            ]
        end)
    end
  end

  defp stringify(callbacks, value) do
    callbacks
    |> Keyword.fetch!(:stringify_keys)
    |> then(& &1.(value))
  end

  defp compact(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, "", [], %{}] end)
    |> Map.new()
  end

  defp compact(map, callbacks) do
    callbacks
    |> Keyword.fetch!(:compact_map)
    |> then(& &1.(map))
  end

  defp callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      feedback_value_missing?: &feedback_value_missing?/1,
      unit_interval_number_status: &FeedbackNumericValues.unit_interval_number_status/1
    ]

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
