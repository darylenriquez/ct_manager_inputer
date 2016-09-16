require './config/loader'

begin
  StoryBoard.initialize_story!
rescue => e
  raise e
end