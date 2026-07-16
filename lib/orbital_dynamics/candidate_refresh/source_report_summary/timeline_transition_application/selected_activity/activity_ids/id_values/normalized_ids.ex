defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.ActivityIds.IdValues.NormalizedIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def values_or_nil(ids) do
    case values(ids) do
      [] -> nil
      ids -> ids
    end
  end

  def values(ids) do
    ids
    |> List.flatten()
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def activity_id_value(%{} = activity) do
    activity = EncodedValue.stringify_keys(activity)

    StableIds.stable_id_or_nil(
      activity["activity_id"] ||
        activity["id"] ||
        get_in(activity, ["timeline_identity", "activity_id"]) ||
        get_in(activity, ["timeline_identity", "id"])
    )
  end

  def activity_id_value(_activity), do: nil
end
