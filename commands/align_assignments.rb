require 'ruble'

command 'Align Assignments' do |cmd|
  cmd.key_binding = 'OPTION+COMMAND+]'
  cmd.output = :replace_selection
  cmd.input = :selection, :document
  cmd.invoke do
    #
    # Assignment block tidier, version 0.1.
    #
    # Copyright Chris Poirier 2006.
    # Licensed under the Academic Free License version 3.0.
    #
    # This script can be used as a command for TextMate to align all 
    # of the equal signs within a block of text.  When using it with
    # TextMate, set the command input to "Selected Text" or "Document",
    # and the output to "Replace Selected Text".  Map it to a key 
    # equivalent, and any time you want to tidy up a block, either 
    # select it, or put your cursor somewhere within it; then hit the
    # key equivalent.  Voila.
    #
    # Note that this is the first version of the script, and it hasn't
    # been heavily tested.  You might encounter a bug or two. 
    #
    # Per the license, use of this script is ENTIRELY at your own risk.
    # See the license for full details (they override anything I've 
    # said here).
    
    lines = $stdin.readlines
    selected_text = ENV.member?("TM_SELECTED_TEXT")
    
    relevant_line_pattern = /^[^=]+[^-+<>=!%\/|&*^]=(?!=|~)/
    column_search_pattern = /[\t ]*=/
    
    
    #
    # If called on a selection, every assignment statement
    # is in the block.  If called on the document, we start on the 
    # current line and look up and down for the start and end of the
    # block.
    if selected_text
       block_top    = 1
       block_bottom = lines.length
    else
     
       #
       # We start looking on the current line.  However, if the
       # current line doesn't match the pattern, we may be just
       # after or just before a block, and we should check.  If
       # neither, we are done.
    
       start_on      = ENV["TM_LINE_NUMBER"].to_i
       block_top     = lines.length + 1
       block_bottom  = 0
       search_top    = 1
       search_bottom = lines.length
       search_failed = false
    
       if lines[start_on - 1] !~ relevant_line_pattern
          if lines[start_on - 2] =~ relevant_line_pattern
             search_bottom = start_on = start_on - 1
          elsif lines[start_on] =~ relevant_line_pattern
             search_top = start_on = start_on
          else
             search_failed = true
          end 
       end
    
       #
       # Now with the search boundaries set, start looking for
       # the block top and bottom.
       unless search_failed
          start_on.downto(search_top) do |number|
             if lines[number-1] =~ relevant_line_pattern
                block_top = number
             else
                break
             end
          end
          
          start_on.upto(search_bottom) do |number|
             if lines[number-1] =~ relevant_line_pattern
                block_bottom = number
             else
                break
             end
          end
       end
    end
    
    
    #
    # Now, iterate over the block and find the best column number
    # for the = sign.  The pattern will tell us the position of the
    # first bit of whitespace before the equal sign.  We put the
    # equals sign to the right of the furthest-right one.  Note that
    # we cannot assume every line in the block is relevant.
    best_column = 0
    block_top.upto(block_bottom) do |number|
       line = lines[number - 1]
       if line =~ relevant_line_pattern
          m = column_search_pattern.match(line)
          best_column = m.begin(0) if m.begin(0) > best_column
       end
    end
    
       
    #
    # Reformat the block.  Again, we cannot assume all lines in the 
    # block are relevant.
    block_top.upto(block_bottom) do |number|
       if lines[number-1] =~ relevant_line_pattern
          before, after = lines[number-1].split(/[\t ]*=[\t ]*/, 2)
          lines[number-1] = [before.ljust(best_column), after].join(after[0,1] == '>' ? " =" : " = ")
       end
    end
    
    #
    # Output the replacement text
    lines.each {|line| puts line }
    nil
  end
end
