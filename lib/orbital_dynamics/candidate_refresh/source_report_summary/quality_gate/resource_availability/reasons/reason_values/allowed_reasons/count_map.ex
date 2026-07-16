defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues.AllowedReasons.CountMap do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def values(%{} = counts, allowed_reasons) do
    counts
    |> Enum.reduce(%{}, fn {reason, count}, acc ->
      reason = NormalizedToken.value(reason)

      if reason in allowed_reasons and is_integer(count) and count > 0 do
        Map.update(acc, reason, count, &(&1 + count))
      else
        acc
      end
    end)
  end
end
