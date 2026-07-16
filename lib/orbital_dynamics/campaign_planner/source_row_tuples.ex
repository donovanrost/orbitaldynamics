defmodule OrbitalDynamics.CampaignPlanner.SourceRowTuples do
  @moduledoc false

  def rows(rows_with_sources) when is_list(rows_with_sources) do
    Enum.map(rows_with_sources, fn {row, _source_path} -> row end)
  end
end
