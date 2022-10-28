# TL;DR: YOU SHOULD DELETE THIS FILE
#
# This file is used by web_steps.rb, which you should also delete
#
# You have been warned
module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /^the user (.*) page$/ then
      user_index_path($1)
    when /^the welcome page$/ then
      root_path
    when /^the dashboard page"$/ then
      main_dashboard_path
    when /^the details page for "(.*)"$/ then
      record = Movie.find_by title: $1
      movie_path(record)
    when /^the Similar Movies page for "(.*)"$/ then
      record = Movie.find_by title: $1
      find_similar_movies_path(record.id)
    else
      begin
        page_name =~ /^the (.*) page$/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
                "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)