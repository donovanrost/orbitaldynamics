defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffStatusTransitionFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{RepairRealizedState, ValueEncoding}

  @realized_statuses ~w(completed executed partial missed failed canceled cancelled rejected delayed)

  def realized_status(row), do: realized_status(row, default_callbacks())

  def realized_status(row, callbacks) do
    [
      row["replacement_realized_status"],
      get_in(row, ["replacement_activity_context", "realized_status"]),
      row["realized_status"],
      row["replacement_status"],
      get_in(row, ["replacement_activity_context", "status"]),
      get_in(row, ["status_transition", "to"]),
      row["status"]
    ]
    |> Enum.map(&callback!(callbacks, :normalize_realized_status_value).(&1))
    |> Enum.find(&(&1 in callback!(callbacks, :realized_statuses).()))
  end

  def status_transition(row), do: status_transition(row, default_callbacks())

  def status_transition(row, callbacks) do
    case row["status_transition"] do
      %{} = transition -> callback!(callbacks, :stringify_keys).(transition)
      _transition -> nil
    end
  end

  def transition_field(row, field) do
    row[field] || get_in(row, ["status_transition", field])
  end

  def transition_reason(row) do
    transition_field(row, "transition_reason") ||
      transition_field(row, "reason")
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      normalize_realized_status_value: &RepairRealizedState.normalize_status_value/1,
      realized_statuses: fn -> @realized_statuses end,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end
end
