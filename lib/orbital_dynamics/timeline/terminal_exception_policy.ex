defmodule OrbitalDynamics.Timeline.TerminalExceptionPolicy do
  @moduledoc false

  def terminal?(row, terminal_exception_statuses, provider_result_failure?) do
    row["status"] in terminal_exception_statuses or
      row["operator_action_reason"] in [
        "contact_success_false_requires_review",
        "command_success_false_requires_review"
      ] or
      provider_result_failure?.(Map.get(row, "contact_result")) or
      provider_result_failure?.(Map.get(row, "command_result"))
  end
end
