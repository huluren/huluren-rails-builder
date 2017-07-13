generate 'kaminari:views bootstrap4'

inside 'app/controllers/' do

  gsub_file 'activities_controller.rb', /(\n(\s*?)def index\n[^\n]*?Activity\.[^\n]*)\n/m, <<-CODE
\\1.page(params[:page])
  CODE

  gsub_file 'places_controller.rb', /(\n(\s*?)def index\n[^\n]*?Place\.[^\n]*)\n/m, <<-CODE
\\1.page(params[:page])
  CODE

end

inside 'app/views/' do

  insert_into_file 'activities/index.html.haml', before: /^%(table|br)/ do
    <<-CODE
= paginate @activities
    CODE
  end

  insert_into_file 'places/index.html.haml', before: /^%(table|br)/ do
    <<-CODE
= paginate @places
    CODE
  end

end
