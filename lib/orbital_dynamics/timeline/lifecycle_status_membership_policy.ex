defmodule OrbitalDynamics.Timeline.LifecycleStatusMembershipPolicy do
  @moduledoc false

  def executed?(status, executed_statuses), do: status in executed_statuses

  def repairable?(status),
    do: status in ["missed", "failed", "delayed", "canceled", "cancelled", "rejected"]

  def unsupported_approval?(nil, _approval_statuses), do: false
  def unsupported_approval?(status, approval_statuses), do: status not in approval_statuses

  def unsupported_activity?(nil, _activity_statuses), do: false
  def unsupported_activity?(status, activity_statuses), do: status not in activity_statuses
end
