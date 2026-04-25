defmodule VerisiteBe.Storage.Providers.GoogleDrive do
  @moduledoc false

  @behaviour VerisiteBe.Storage.Provider

  @impl true
  def store(_upload, _settings), do: {:error, :provider_not_implemented}
end
