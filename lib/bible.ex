defmodule Bible do
  use Application

  @doc """
  Returns the number of chapters in the specified book of the Bible.

  ## Examples

      iex> Bible.chapters("Exodus")
      {:ok, 40}
      iex> Bible.chapters("Philippines")
      :error
  """
  @spec chapters(binary) :: { :ok, integer } | :error
  def chapters(book) do
    Bible.Server.get_chapter_count(book)
  end

  @doc """
  Returns the number of verses for the specified book and chapter in the Bible.

  ## Examples

      iex> Bible.versus("Psalms",119)
      {:ok, 176}
      iex> Bible.versus("Psalms", 155)
      :error
  """
  @spec verses(binary,integer) :: { :ok, integer }
  def verses(book,chapter) do
    Bible.Server.get_verse_count(book,chapter)
  end

  @spec is_book?(binary) :: boolean
  def is_book?(book) do
    Bible.Server.is_book?(book)
  end

  def reference_verses(pid,references) do
    Bible.ReadServer.reading_metrics(pid,references)
  end

  def start( _type, _args ) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Bible.Server, [Bible.Versions.ESV])
#      supervisor(Bible.ReadServer, [])
    ]

    opts = [strategy: :one_for_one, name: Bible.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
