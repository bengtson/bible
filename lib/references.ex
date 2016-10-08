defmodule Bible.References do

    @moduledoc """
    This module provides the necessary functionality to parse Bible references,
    lists of Bible references and also to generate properly formated references,
    or reference lists.

    The table defined in 'test_cases' provides all the possible variations for a Bible reference. In addition, an example is given for the variant. This table is used for testing this module and should be recreated in the 'test_cases' function if it is modified. Column 56 is the start of the test case.

    And of course, any combination of references can be chained by separating them by commas.

    Examples:

    John 7:3,2:9-11
    John 14:16-17,25-36
    Mark, Luke 5,6:12-15, Revelation 2

    21-Sep-2016 : Thoughts on parsing from the Polynesian Resort ...

    A reference is always a 6 entry tuple consisting of:
    { starting book name, starting chapter, starting verse,
      ending   book name,   ending chapter,   ending verse }

    This means that a single verse will still require that all the information will need to be provided. It also means that a reference with a single book will have the first first and last verse specified.

    Note that this might make the parsing much easier. If a reduced reference is required, it can be easily created and returned.

    A set of references is simply a list of references.

    Parsing:

      - split all references by commas. A comma signifies a new reference that is not continuous with the prior reference. Treat each one separately.

      - Set state 'level' to :new. This indicates start of a new reference.
      - Set state 'range' to :begin. This indicates we are searching for the beginining of a range.

      main
      - Get the first part of the reference.
      - If part type is book and level is :none ...
          - create a new reference with book name and all info filled out.
          - call main again with new state.
      - If part type is book and level is :book ...
          - set the ending book to the new book and set last verse.
          - set state 'range' to :end.
          - call main again with new state.
      - If part type is ':hyphen' ...
          - set state 'range' to :end.
          - call main with new state.
      - If part is number and level is book and range is start ...
          - set start chapter to chapter number.
          - set start verse to 1.
          - set end chapter to chapter number.
          - set end verse to last in chapter.
          - set level to :chapter.
          - call main with new state.
      - If part is number and level is book and range is end ...
          - set end chapter to chapter number.
          - set end verse to last in chapter.
          - set level to chapter.
          - call main with new state.
      - If part is number and level is chapter and range is start ...
          - set start verse to number.
          - set end verse to number.
          - set level to verse.
          - call main with new state.
      - If part is number and level is chapter and range is end ...
          - set end verse to number.
          - set level to verse.
          - call main with new state.
      - If part is verse and level is verse and range is end ...
          - set end verse to number.
          - call main with new state.
      -

    """

    @doc """
    Defines all possible variations for Bible references. This table is used to test all the cases.
    """
    def test_cases do
      #    Standard bible reference formats             Test
      "
      01 - book                                          Matthew
      02 - book chapter                                  Matthew 2
      03 - book chapter:verse                            Matthew 2:3
      04 - book               - book                     Matthew - Mark
      05 - book chapter       - book                     Matthew 2 - Mark
      06 - book chapter:verse - book                     Matthew 2:3 - Mark
      07 - book               - book chapter             Matthew - Mark 2
      08 - book chapter       - book chapter             Matthew 2 - Mark 3
      09 - book chapter:verse - book chapter             Matthew 2:3 - Mark 4
      10 - book               - book chapter:verse       Matthew - Mark 2:3
      11 - book chapter       - book chapter:verse       Matthew 2 - Mark 3:4
      12 - book chapter:verse - book chapter:verse       Matthew 2:3 - Mark 4:5
      13 - book chapter       - chapter                  Matthew 2-3
      14 - book chapter       - chapter:verse            Matthew 2-3:4
      15 - book chapter:verse - chapter:verse            Matthew 2:3-4:5
      16 - book chapter:verse - verse                    Matthew 2:3-4
      "
    end

    @doc """
    Given a list of reference strings, this returns a list of parsed references.
    """
    def exp_bible_references(ref_strings) do
      ref_strings
        |> String.split(",")
        |> Enum.map(&(exp_bible_reference(&1)))
#        |> IO.inspect
    end

    @doc """
    Given a bible reference string and the bible metadata, this returns a
    map with the starting book:chapter:verse and ending book:chapter:verse.
    """
    def exp_bible_reference(ref_string) do
      parts = ref_string
      |> String.replace("-", " - ")
      |> String.replace(":", " : ")
      |> String.replace("  ", " ")
      |> String.split([" "])
      |> Enum.map(&(String.trim(&1)))

      exp_bible_next_part({nil,nil,nil,nil,nil,nil},
                          {:none,:start},
                          {parts,ref_string})
    end

    # Fetches the next part in the bible reference and dispatches to the
    # function that can handle the part.
    defp exp_bible_next_part({a,b,c,d,e,f},_,{[],_}) do
      %{ "Start Book" => a,
         "Start Chapter" => b,
         "Start Verse" => c,
         "End Book" => d,
         "End Chapter" => e,
         "End Verse" => f }
    end
    defp exp_bible_next_part({a,b,c,d,e,f},{lev,ran},{parts,ref}) do
      { part, value, new_parts } = parts_type(parts)
      exp_bible_machine({a,b,c,d,e,f},{lev,ran},{part,value},{new_parts,ref})
    end

    # If the next part is a book and we have not set the level, then accept
    # the book name and create the reference.
    defp exp_bible_machine(_,{:none,_},{:book,value},state) do
      { :ok, chapter_count } = Bible.Server.get_chapter_count(value)
      { :ok, verse_count } = Bible.Server.get_verse_count(value,chapter_count)
      exp_bible_next_part({value,1,1,value,chapter_count,verse_count},
                          {:book,:start},state)
    end

    # If the next part is a book and the range is :end, set the end to the
    # end of the specified book.
    defp exp_bible_machine({a,b,c,_,_,_},{_,:end},{:book,value},state) do
      { :ok, chapter_count } = Bible.Server.get_chapter_count(value)
      { :ok, verse_count } = Bible.Server.get_verse_count(value,chapter_count)
      exp_bible_next_part({a,b,c,value,chapter_count,verse_count},
                          {:chapter,:end},state)
    end

    # If the next part is a number and level is :book, range is :start, then
    # set the chapter for the start and the end verse to the last verse in
    # the chapter.
    defp exp_bible_machine({a,_,_,_,_,_},{:book,:start},
                           {:number,value},state) do
      { :ok, verse_count } = Bible.Server.get_verse_count(a,value)
      exp_bible_next_part({a,value,1,a,value,verse_count},
                          {:chapter,:start},state)
    end

    # If the next part is a number and level is :book, range is :start, then
    # set the chapter for the start and the end verse to the last verse in
    # the chapter.
    defp exp_bible_machine({a,b,c,d,_,_},{:chapter,:end},
                           {:number,value},state) do
      { :ok, verse_count } = Bible.Server.get_verse_count(d,value)
      exp_bible_next_part({a,b,c,d,value,verse_count},{:chapter,:end},state)
    end

    # If the next part is a chapter and range is :end, then
    # set the chapter for the end and the end verse to the last verse in
    # the chapter.
    defp exp_bible_machine({a,b,c,d,_,_},{_,:end},{:chapter,value},state) do
      { :ok, verse_count } = Bible.Server.get_verse_count(d,value)
      exp_bible_next_part({a,b,c,d,value,verse_count},{:verse,:end},state)
    end

    # If the next part is a chapter and level is :book, range is :start, then
    # set the chapter for the start and the end verse to the last verse in
    # the chapter.
    defp exp_bible_machine({a,_,_,_,_,_},{:book,:start},
                           {:chapter,value},state) do
      { :ok, verse_count } = Bible.Server.get_verse_count(a,value)
      exp_bible_next_part({a,value,1,a,value,verse_count},{:verse,:start},state)
    end

    # If the next part is a number and level is :chapter, range is :start, then
    # set the verse for the start and the end verse to the verse specified.
    defp exp_bible_machine({a,b,_,_,_,_},{:verse,:start},
                           {:number,value},state) do
      exp_bible_next_part({a,b,value,a,b,value},{:verse,:start},state)
    end

    # If the next part is a number and level is :verse, range is :end, then
    # set the verse for the end verse to the verse specified.
    defp exp_bible_machine({a,b,c,d,e,_},{:verse,:end},{:number,value},state) do
      exp_bible_next_part({a,b,c,d,e,value},{:verse,:end},state)
    end

    # If the next part is a hyphen, then change the range.
    defp exp_bible_machine({a,b,c,d,e,f},{lev,:start},{:hyphen,_},state) do
      exp_bible_next_part({a,b,c,d,e,f},{lev,:end},state)
    end

    # If the next part is a colon, and we were at :chapter level then change
    # the level to verse.
    defp exp_bible_machine({a,b,c,d,e,f},{_,ran},{:colon,_},state) do
      exp_bible_next_part({a,b,c,d,e,f},{:verse,ran},state)
    end

    # Returns an atom indicating what type of part is at the start of the
    # parsing list. Options are:
    #
    #   :colon, remaining parts
    #   :comma, remaining parts
    #   :hyphen, remaining parts
    #   :number, number, remaining parts
    #   :chapter, number, remaining parts   # is a number followed by ":"
    #   :book, bookname, remaining parts
    #   :other, unknown part, remaining parts
    #

    def parts_type([":" | tail ]) do
      { :colon, nil, tail }
    end
    def parts_type(["," | tail ]) do
      { :comma, nil, tail }
    end
    def parts_type(["-" | tail ]) do
      { :hyphen, nil, tail }
    end

    # This needs to do some recursion for three part names.
    def parts_type(parts) do
      parts_type_book_look(1, "", parts, parts)
    end

    # When there are no more parts,
    defp parts_type_book_look(_, _, [], parts) do
      parts_type_number_look(parts)
    end

    # When no book found, end recursion and look for a number.
    defp parts_type_book_look(4, _, _, parts) do
      parts_type_number_look(parts)
    end

    # Appends next part to provided book name and checks. Some book names
    # are multiple parts so check up to 3 parts (Song of Solomon).
    defp parts_type_book_look(n, bookname, [ tail_head | new_tail ], parts) do
      bookname = bookname <> " " <> tail_head
      bookname = String.trim(bookname)
      case Bible.Server.is_book?(bookname) do
        true -> { :book, bookname, new_tail }
        false -> parts_type_book_look(n+1, bookname, new_tail, parts)
      end
    end

    # Matched only when there is one element in the tail.
    defp parts_type_book_look(_, bookname, tail, parts) do
      bookname = bookname <> " " <> tail
      case Bible.Server.is_book?(bookname) do
        true -> { :book, bookname, [] }
        false -> parts_type_number_look(parts)
      end
    end

    defp parts_type_number_look([ head | [ ":" | tail ]]) do
      case Integer.parse(head) do
        :error -> { :other, head, tail }
        { number, _ } -> { :chapter, number, tail }
      end
    end

    defp parts_type_number_look(parts) do
      [ head | tail ] = parts
      case Integer.parse(head) do
        :error -> { :other, head, tail }
        { number, _ } -> { :number, number, tail }
      end
    end

    def reduce_references(refs) do
      refs
        |> Enum.map(&(reduce_reference(&1)))
        |> Enum.join(",")
    end

    def reduce_reference({a,b,c,d,e,f}) do
      reduce_reference(%{  "Start Book" => a,
          "Start Chapter" => b,
          "Start Verse" => c,
          "End Book" => d,
          "End Chapter" => e,
          "End Verse" => f })
    end

    @doc """
    Given a fully qualified reference such as that returned by exp_bible_reference, this will return a string reduced to the minimum reference.
    """
    def reduce_reference(reference) do
#      reference = hd(reference)
      a = reference["Start Book"]
      b = reference["Start Chapter"]
      c = reference["Start Verse"]
      d = reference["End Book"]
      e = reference["End Chapter"]
      f = reference["End Verse"]

      # Calculate limits.
      bl = b == 1
      cl = c == 1
      { :ok, chapter_count } = Bible.Server.get_chapter_count(d)
      { :ok, verse_count } = Bible.Server.get_verse_count(d,e)
      el = e == chapter_count
      fl = f == verse_count

      # Calculate equality level.
      equal_level = cond do
        a == d and b == e and c == f -> :verse
        a == d and b == e -> :chapter
        a == d -> :book
        true -> :none
      end

      # Case statement parameters are as follows:
      #   a,b,c : Starting book, chapter, verse
      #   d,e,f : Ending book, chapter, verse
      #   bl : starting chapter is at limit -> :true
      #   cl : starting verse is at limit -> :true
      #   el : ending chapter is at limit -> :true
      #   fl : ending verse is at limit -> :true
      #   equal_level ->
      #     :verse -> equality to verse level.
      #     :chapter -> equality only to chapter level.
      #     :book -> equality only to book level.
      #     :none -> no equality.
      case {a,b,c,d,e,f,bl,cl,el,fl,equal_level} do
        {a,_,_,a,_,_,  :true,:true,:true,:true,  _} ->    # Variant 01
          "#{a}"
        {a,b,_,a,b,_,  _,:true,_,:true,  _} ->            # Variant 02
          "#{a} #{b}"
        {a,b,c,a,b,c,  _,_,_,_,  _} ->                    # Variant 03
          "#{a} #{b}:#{c}"
        {a,_,_,d,_,_,  :true,:true,:true,:true,  _} ->    # Variant 04
          "#{a} - #{d}"
        {a,b,_,a,e,_,  _,:true,_,:true,  :book} ->        # Variant 13 - Must Preceed Variant 07 for "John 1-3". Must preceed variant 5 for John 19-21.
          "#{a} #{b}-#{e}"
        {a,b,_,d,_,_,  _,:true,:true,:true,  _} ->        # Variant 05
          "#{a} #{b} - #{d}"
        {a,b,c,d,_,_,  _,_,:true,:true,  _} ->            # Variant 06
          "#{a} #{b}:#{c} - #{d}"
        {a,_,_,d,e,_,  :true,:true,_,:true, _} ->         # Variant 07
          "#{a} - #{d} #{e}"
        {a,b,_,d,e,_,  _,:true,_,:true,  :none} ->        # Variant 08
          "#{a} #{b} - #{d} #{e}"
        {a,b,c,d,e,_,  _,_,_,:true,  :none} ->            # Variant 09
          "#{a} #{b}:#{c} - #{d} #{e}"
        {a,_,_,d,e,f,  :true,:true,_,_,  _} ->            # Variant 10
          "#{a} - #{d} #{e}:#{f}"
        {a,b,_,d,e,f,  _,:true,_,_,  :none} ->            # Variant 11
          "#{a} #{b} - #{d} #{e}:#{f}"
        {a,b,c,d,e,f,  _,_,_,_,  :none} ->                # Variant 12
          "#{a} #{b}:#{c} - #{d} #{e}:#{f}"
        {a,b,_,a,e,f,  _,:true,_,_,  :book} ->            # Variant 14
          "#{a} #{b}-#{e}:#{f}"
        {a,b,c,a,e,f,  _,_,_,_,  :book} ->                # Variant 15
          "#{a} #{b}:#{c}-#{e}:#{f}"
        {a,b,c,a,b,f,  _,_,_,_,  :chapter} ->             # Variant 16
          "#{a} #{b}:#{c}-#{f}"
        _ ->
          { :error,
            "Could Not Generate Reference",
            %{ "Start Book" => a,
               "Start Chapter" => b,
               "Start Verse" => c,
               "End Book" => d,
               "End Chapter" => e,
               "End Verse" => f }
          }
      end
    end

    @doc """
    Takes a reference string, expands it then reduces it returning the reduced reference.
    """
    def cycle_reference(reference) do
      reduce_reference(exp_bible_reference(reference))
    end

    @doc """
    Tests reference and reference reduction by iterating through the test cases
    associated with each reference variant.
    """
    def references_test do
      test_cases
      |> String.split("\n")               # Get list of lines.
      |> Enum.filter(&(String.contains?(&1,"book")))
      |> Enum.map(&(String.slice(&1,57..-1)))
      |> Enum.filter(&(&1 != cycle_reference(&1)))
    end

end
