defmodule OrbitalDynamics.Timeline.ApprovalProtectionPolicy do
  @moduledoc false

  def preservation_sensitive_source?(source, protected_approval_statuses),
    do: source["locked"] || approval_protected?(source, protected_approval_statuses)

  def approval_protected?(source, protected_approval_statuses),
    do: source["approval_status"] in protected_approval_statuses
end
