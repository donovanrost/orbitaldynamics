defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationSummaryPressureBranches do
  @moduledoc false

  def build(summaries, callbacks) do
    pressure_branch = Keyword.fetch!(callbacks, :pressure_branch)
    pressure_rows = Keyword.fetch!(callbacks, :pressure_rows)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    Enum.flat_map(summaries, fn {summary, source_path} ->
      trust_boundary =
        Map.get(summary, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])

      summary
      |> pressure_rows.()
      |> Enum.map(&stringify_keys.(&1))
      |> Enum.map(&Map.put(&1, "_source_report_trust_boundary", trust_boundary))
      |> Enum.flat_map(&pressure_branch.(&1, source_path))
    end)
  end
end
