defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityPayloadFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationIdentityFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityPayloadGroups

  def payload(row, callbacks) do
    row
    |> TimelineDiffObservationProductIdentityPayloadGroups.identity_group("collection", callbacks)
    |> Map.merge(
      TimelineDiffObservationProductIdentityPayloadGroups.identity_group(
        row,
        "product",
        callbacks
      )
    )
    |> Map.merge(
      TimelineDiffObservationProductIdentityPayloadGroups.product_ids_group(row, callbacks)
    )
    |> Map.merge(
      TimelineDiffObservationProductIdentityPayloadGroups.identity_group(
        row,
        "payload",
        callbacks
      )
    )
    |> Map.merge(
      TimelineDiffObservationProductIdentityPayloadGroups.identity_group(
        row,
        "instrument",
        callbacks
      )
    )
    |> Map.put(
      "observation_identity_mismatch_fields",
      TimelineDiffObservationIdentityFields.observation_product_identity_mismatch_fields(
        row,
        callbacks
      )
    )
  end
end
