defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityLookupFields

  def observation_product_identity_reasons(row, callbacks) do
    [
      "timeline_diff_changed_activity",
      "timeline_diff_changed_observation_product_identity"
    ] ++
      Enum.map(
        observation_product_identity_mismatch_fields(row, callbacks),
        &"#{&1}_mismatch"
      )
  end

  def observation_product_identity_mismatch_fields(row, callbacks) do
    ["collection", "product", "product_ids", "payload", "instrument"]
    |> Enum.filter(
      &(explicit_observation_product_identity_match_status(row, &1, callbacks) == "mismatch")
    )
  end

  def observation_product_identity_match_status(row, "product_ids", callbacks) do
    explicit_observation_product_identity_match_status(row, "product_ids", callbacks) ||
      callback!(callbacks, :timeline_diff_match_status).(
        observation_identity_ids(row, "planned", "product", callbacks),
        observation_identity_ids(row, "realized", "product", callbacks)
      )
  end

  def observation_product_identity_match_status(row, field, callbacks) do
    explicit_observation_product_identity_match_status(row, field, callbacks) ||
      callback!(callbacks, :timeline_diff_match_status).(
        observation_identity_id(row, "planned", field, callbacks),
        observation_identity_id(row, "realized", field, callbacks)
      )
  end

  def observation_identity_id(row, "planned", field, callbacks) do
    TimelineDiffObservationProductIdentityLookupFields.observation_identity_id(
      row,
      "planned",
      field,
      callbacks
    )
  end

  def observation_identity_id(row, "realized", field, callbacks) do
    TimelineDiffObservationProductIdentityLookupFields.observation_identity_id(
      row,
      "realized",
      field,
      callbacks
    )
  end

  def observation_identity_ids(row, side, "product", callbacks) do
    TimelineDiffObservationProductIdentityLookupFields.observation_identity_ids(
      row,
      side,
      "product",
      callbacks
    )
  end

  defp explicit_observation_product_identity_match_status(row, field, callbacks) do
    status_field = "#{field}_match_status"

    callback!(callbacks, :timeline_diff_first_string).(row, [
      status_field,
      "replacement_#{status_field}",
      ["replacement_activity_context", status_field],
      "source_#{status_field}",
      ["source_activity_context", status_field]
    ])
    |> callback!(callbacks, :normalized_status_token).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
