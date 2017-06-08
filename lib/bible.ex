defmodule Bible do
#  use Application

  @doc """
  Returns the number of chapters in the specified book of the Bible.

  ## Examples

      iex> Bible.chapters("Exodus")
      {:ok, 40}
      iex> Bible.chapters("Philippines")
      :error
  """
  @spec chapters(binary, map) :: { :ok, integer } | :error
  def chapters(book, info) do
    Bible.Info.get_chapter_count(info, book)
  end

  @doc """
  Returns the number of verses for the specified book and chapter in the Bible.

  ## Examples

      iex> Bible.versus("Psalms",119)
      {:ok, 176}
      iex> Bible.versus("Psalms", 155)
      :error
  """
  @spec verses(map,binary,integer) :: { :ok, integer }
  def verses(info,book,chapter) do
    Bible.Info.get_verse_count(info,book,chapter)
  end

  @spec is_book?(binary,map) :: boolean
  def is_book?(book, info) do
    Bible.Info.is_book?(book, info)
  end

#  def reference_verses(pid,references) do
#    Bible.ReadServer.reading_metrics(pid,references)
#  end


end
