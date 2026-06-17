defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityDataRateFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityDataRateLookupFields

  def planned_data_rate_mbps(row, callbacks) do
    TimelineDiffLinkQualityDataRateLookupFields.planned_data_rate_mbps(row, callbacks)
  end

  def realized_data_rate_mbps(row, callbacks) do
    TimelineDiffLinkQualityDataRateLookupFields.realized_data_rate_mbps(row, callbacks)
  end

  def link_profile_data_rate_mbps(row, callbacks) do
    realized_data_rate_mbps(row, callbacks) || planned_data_rate_mbps(row, callbacks)
  end

  def data_rate_delta_mbps(row, callbacks) do
    planned = planned_data_rate_mbps(row, callbacks)
    realized = realized_data_rate_mbps(row, callbacks)

    if is_number(planned) and is_number(realized), do: realized - planned
  end

  def data_rate_match_status(row, callbacks) do
    planned = planned_data_rate_mbps(row, callbacks)
    realized = realized_data_rate_mbps(row, callbacks)

    cond do
      not is_number(planned) and not is_number(realized) -> nil
      not is_number(planned) -> "realized_only"
      not is_number(realized) -> "planned_only"
      abs(realized - planned) <= 1.0e-9 -> "matched"
      true -> "mismatch"
    end
  end
end
