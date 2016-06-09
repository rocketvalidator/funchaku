defmodule Funchaku do
  def check(url, options \\ []) do
    Funchaku.Checker.check(url, options)
  end
end
