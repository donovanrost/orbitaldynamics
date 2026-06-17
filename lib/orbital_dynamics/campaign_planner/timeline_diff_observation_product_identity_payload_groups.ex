defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityPayloadGroups do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationIdentityFields

  def identity_group(row, field, callbacks) do
    id_field = "#{field}_id"

    %{
      id_field =>
        TimelineDiffObservationIdentityFields.observation_identity_id(
          row,
          "realized",
          field,
          callbacks
        ),
      "planned_#{id_field}" =>
        TimelineDiffObservationIdentityFields.observation_identity_id(
          row,
          "planned",
          field,
          callbacks
        ),
      "realized_#{id_field}" =>
        TimelineDiffObservationIdentityFields.observation_identity_id(
          row,
          "realized",
          field,
          callbacks
        ),
      "#{field}_match_status" =>
        TimelineDiffObservationIdentityFields.observation_product_identity_match_status(
          row,
          field,
          callbacks
        )
    }
  end

  def product_ids_group(row, callbacks) do
    %{
      "product_ids" =>
        TimelineDiffObservationIdentityFields.observation_identity_ids(
          row,
          "realized",
          "product",
          callbacks
        ),
      "planned_product_ids" =>
        TimelineDiffObservationIdentityFields.observation_identity_ids(
          row,
          "planned",
          "product",
          callbacks
        ),
      "realized_product_ids" =>
        TimelineDiffObservationIdentityFields.observation_identity_ids(
          row,
          "realized",
          "product",
          callbacks
        ),
      "product_ids_match_status" =>
        TimelineDiffObservationIdentityFields.observation_product_identity_match_status(
          row,
          "product_ids",
          callbacks
        )
    }
  end
end
