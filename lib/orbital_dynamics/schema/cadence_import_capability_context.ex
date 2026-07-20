defmodule OrbitalDynamics.Schema.CadenceImportCapabilityContext do
  @moduledoc false

  def cadence_import_capability do
    OrbitalDynamics.CadenceImport.capability()
  end

  def cadence_import_manifest_model_limits do
    cadence_import_capability()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def cadence_import_supported_sources do
    cadence_import_capability().supported_sources
  end
end
