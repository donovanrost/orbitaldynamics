defmodule OrbitalDynamics.Timeline.ApprovalProtectionPolicy do
  @moduledoc false

  def protected_by_lock_or_approval?(activity, activity_locked?, activity_approved?),
    do: activity_locked?.(activity) or activity_approved?.(activity)

  def preservation_sensitive_source?(source, protected_approval_statuses),
    do: source["locked"] || approval_protected?(source, protected_approval_statuses)

  def approval_protected?(source, protected_approval_statuses),
    do: source["approval_status"] in protected_approval_statuses
end
