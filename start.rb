require './message_box.rb'
require './story_plot.rb'
require './story_board.rb'

begin
  story_board = StoryBoard.new
  story_board.run
rescue => e
  raise e
end