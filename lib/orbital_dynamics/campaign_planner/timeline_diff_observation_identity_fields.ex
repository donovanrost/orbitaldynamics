defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationIdentityFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationTargetIdentityFields

  def observation_target_match_status(row, callbacks) do
    TimelineDiffObservationTargetIdentityFields.observation_target_match_status(row, callbacks)
  end

  def explicit_observation_target_match_status(row, callbacks) do
    TimelineDiffObservationTargetIdentityFields.explicit_observation_target_match_status(
      row,
      callbacks
    )
  end

  def planned_observation_target_id(row, callbacks) do
    TimelineDiffObservationTargetIdentityFields.planned_observation_target_id(row, callbacks)
  end

  def realized_observation_target_id(row, callbacks) do
    TimelineDiffObservationTargetIdentityFields.realized_observation_target_id(row, callbacks)
  end

  def observation_product_identity_reasons(row, callbacks) do
    TimelineDiffObservationProductIdentityFields.observation_product_identity_reasons(
      row,
      callbacks
    )
  end

  def observation_product_identity_mismatch_fields(row, callbacks) do
    TimelineDiffObservationProductIdentityFields.observation_product_identity_mismatch_fields(
      row,
      callbacks
    )
  end

  def observation_product_identity_match_status(row, "product_ids", callbacks) do
    TimelineDiffObservationProductIdentityFields.observation_product_identity_match_status(
      row,
      "product_ids",
      callbacks
    )
  end

  def observation_product_identity_match_status(row, field, callbacks) do
    TimelineDiffObservationProductIdentityFields.observation_product_identity_match_status(
      row,
      field,
      callbacks
    )
  end

  def observation_identity_id(row, "planned", field, callbacks) do
    TimelineDiffObservationProductIdentityFields.observation_identity_id(
      row,
      "planned",
      field,
      callbacks
    )
  end

  def observation_identity_id(row, "realized", field, callbacks) do
    TimelineDiffObservationProductIdentityFields.observation_identity_id(
      row,
      "realized",
      field,
      callbacks
    )
  end

  def observation_identity_ids(row, side, "product", callbacks) do
    TimelineDiffObservationProductIdentityFields.observation_identity_ids(
      row,
      side,
      "product",
      callbacks
    )
  end
end
