defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityLookupFields do
  @moduledoc false

  def observation_identity_id(row, "planned", field, callbacks) do
    id_field = "#{field}_id"

    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "planned_#{id_field}",
      "source_planned_#{id_field}",
      "source_#{id_field}",
      ["source_activity_context", "planned_#{id_field}"],
      ["source_activity_context", id_field],
      ["source_activity_context", field, id_field],
      ["source_activity_context", field, "id"],
      ["source_#{field}", id_field],
      ["source_#{field}", "id"]
    ])
  end

  def observation_identity_id(row, "realized", field, callbacks) do
    id_field = "#{field}_id"

    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "realized_#{id_field}",
      "replacement_realized_#{id_field}",
      "replacement_#{id_field}",
      ["replacement_activity_context", "realized_#{id_field}"],
      ["replacement_activity_context", id_field],
      ["replacement_activity_context", field, id_field],
      ["replacement_activity_context", field, "id"],
      ["replacement_#{field}", id_field],
      ["replacement_#{field}", "id"]
    ])
  end

  def observation_identity_ids(row, side, "product", callbacks) do
    fields =
      case side do
        "planned" ->
          [
            "planned_product_ids",
            "planned_data_product_ids",
            "source_planned_product_ids",
            "source_planned_data_product_ids",
            "source_product_ids",
            "source_data_product_ids",
            "source_products",
            "source_data_products",
            ["source_activity_context", "planned_product_ids"],
            ["source_activity_context", "planned_data_product_ids"],
            ["source_activity_context", "product_ids"],
            ["source_activity_context", "data_product_ids"],
            ["source_activity_context", "products"],
            ["source_activity_context", "data_products"]
          ]

        "realized" ->
          [
            "realized_product_ids",
            "realized_data_product_ids",
            "replacement_realized_product_ids",
            "replacement_realized_data_product_ids",
            "replacement_product_ids",
            "replacement_data_product_ids",
            "replacement_products",
            "replacement_data_products",
            ["replacement_activity_context", "realized_product_ids"],
            ["replacement_activity_context", "realized_data_product_ids"],
            ["replacement_activity_context", "product_ids"],
            ["replacement_activity_context", "data_product_ids"],
            ["replacement_activity_context", "products"],
            ["replacement_activity_context", "data_products"]
          ]
      end

    fields
    |> Enum.map(&callback!(callbacks, :timeline_diff_field_value).(row, &1))
    |> Kernel.++([observation_identity_id(row, side, "product", callbacks)])
    |> Enum.flat_map(&callback!(callbacks, :score_term_product_id_values).(&1))
    |> Enum.filter(&callback!(callbacks, :stable_id_string?).(&1))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
