defmodule Funchaku do
  def check(url, options \\ []) do
    Funchaku.Checker.check(url, options)
  end

  def check_text(html, options \\ []) do
    Funchaku.Checker.check_text(html, options)
  end
end
