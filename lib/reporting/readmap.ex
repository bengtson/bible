defmodule Bible.Reporting.ReadMap do

  @doc """
  This generates an svg file showing what parts of the bible have been read.

  How would this work ...

  Using a state machine, initialize state as follows:
  cursor x =>
  cursor y =>
  book_map => %{ Genesis => %{ text_pos, << chapter grid pos binary >>}}


  """

  @font_size 10.0         # Font size for Bible books.
  @marker_size 8.0        # Point size for marker diameter.
  @line_height 10.0       # Line spacing.

  @doc """
  The read_map function generates an svg image that shows what the reader has read during the last year. Generation uses a state map with the following:

    "Output File" => name of the file to write the svg into.
    "svg" => the actual svg code.
    "Verse Map" => bit map of the verses that have been read in the Bible.
    "Draw Elements" => list of all the svg elements that need to be drawn for the chart. The element format is listed below.

  Element formats:

    :type => :book
    :name => book_name
    :width => width in points of the book name

    :type => :chapter
    :number => chapter_number
    :width => marker_size (define)
    :metrics => percent_read (0.00 to 1.00)
  """

  def read_map reading_list do
    Fonts.FontServer.load_font("/Library/Fonts/SourceSansPro-Light.otf");

    end_date = Timex.now
    start_date = Timex.shift(end_date, days: -365+1)


    verse_map = reading_list
    |> Bible.ReadServer.filter_by_date({start_date,end_date})
    |> Bible.ReadServer.to_verse_map

    %{"Output File" => "Chart.svg", "svg" => "", "Verse Map" => verse_map}
      |> svg_header
      |> draw_text("Bible Reading Map", 10, 15,"Open Sans", 14.0)
      |> draw_text("Genesis",10,35,"Open Sans",12.0)
      |> gen_draw_elements
#      |> calculate_element_positions   # adds the svg position for each element
#      |> generate_element_svg          # generates the svg
      |> svg_footer
      |> write_svg
#      |> IO.inspect

  end

  def gen_draw_elements state do
    verse_map = state["Verse Map"]
#    |> Bible.ReadServer.to_verse_map
    draw_elements = 1..Bible.Server.get_book_count
    |> Enum.map(&(Bible.Server.get_book_name/1))
    |> Enum.map(&(gen_book_draw_elements(&1,verse_map)))
    put_in state["Draw Elements"],draw_elements
  end

  def gen_book_draw_elements book_name, verse_map do
    {:ok, chapter_count} = Bible.Server.get_chapter_count book_name
    width = Fonts.string_width("SourceSansPro-Light",book_name, @font_size)
    chapter_elements =
    1..chapter_count
    |> Enum.map(fn chapter_number ->
                %{ :type => :chapter,
                   :number => chapter_number,
                   :width => @marker_size,
                   :metrics => get_chapter_metrics(book_name,chapter_number,verse_map)}
                end)
    [ %{ :type => :book, :name => book_name, :width => width } ] ++ chapter_elements
  end

  def get_chapter_metrics book_name, chapter, verse_map do
    ref = Bible.References.exp_bible_reference(book_name <> " " <> "#{chapter}")
    {first,last} = Bible.Server.get_ref_verse_range(ref)
    skip_count = first - 1
    verse_count = last - first + 1
    << _ :: bitstring-size(skip_count),
       chapter_map :: bitstring-size(verse_count),
       _ :: bitstring >> = verse_map
    read_count = for(<< bit::size(1) <- chapter_map >>, do: bit) |> Enum.sum
    read_count / verse_count
  end

  def plot_origin_circle state do
    svg = ~s(
    <!-- Origin -->
    <circle cx="20" cy="20" r="10.0" stroke="black" stroke-width="2.0" fill="none" />
    )
    Map.put(state,"svg",state["svg"] <> svg)
  end

  def draw_text(state, text, x, y, font, size) do
    svg = ~s(
    <text x="#{x}" y="#{y}" font-family="#{font}"  font-weight="lighter" font-style="regular" font-size="#{size}">
    #{text}
    </text>
    )
   Map.put(state,"svg",state["svg"] <> svg)
  end


  def svg_header state do
    svg = EEx.eval_file(Path.expand("./svgtemplates/svg_header.svg.eex"))
    Map.put(state,"svg",state["svg"] <> svg)
  end

  def svg_footer state do
    svg = EEx.eval_file(Path.expand("./svgtemplates/svg_footer.svg.eex"))
    Map.put(state,"svg",state["svg"] <> svg)
  end

  def write_svg state do
    filename = state["Output File"]
#    IO.inspect filename
    svg = state["svg"]
#    IO.inspect svg
    {:ok, file} = File.open "/Users/bengm0ra/Projects/FileliF/Elixir/bible/plotfiles/" <> filename, [:write]
    IO.binwrite file, svg
    File.close file
    state
  end


end
