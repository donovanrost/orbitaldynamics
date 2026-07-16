defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.ContactSources
  alias __MODULE__.Normalization

  defdelegate recommendation_station_contact_pairs(recommendation, status), to: ContactSources

  def recommendation_required_actions(recommendation) do
    [
      recommendation["required_operator_action"],
      recommendation["required_operator_actions"]
    ]
    |> List.flatten()
  end

  defdelegate direction_contact_pairs(report), to: ContactSources

  defdelegate deferred_contacts(recommendation), to: ContactSources

  def stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  def stringify_keys(value), do: Normalization.stringify_keys(value)

  def normalize_direction(direction), do: Normalization.normalize_direction(direction)
end
