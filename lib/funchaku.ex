defmodule Funchaku do
  @moduledoc """
  Funchaku is an Elixir client for the Nu HTML Chcker.
  """

  @doc """
  Convenience method, this is just a shortcut for `Funchaku.Checker.check/2`.
  """
  def check(url, options \\ []) do
    Funchaku.Checker.check(url, options)
  end

  @doc """
  Convenience method, this is just a shortcut for `Funchaku.Checker.check_text/2`.
  """
  def check_text(html, options \\ []) do
    Funchaku.Checker.check_text(html, options)
  end
end
