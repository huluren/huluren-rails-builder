generate 'kaminari:views bootstrap4'

inside 'app/controllers/' do
  gsub_file 'comments_controller.rb', /(\n(\s*?)def index\n\s+@comments = [^\n]*?)\n/m, <<-CODE
\\1.page(params[:page])
  CODE

  gsub_file 'places_controller.rb', /(\n(\s*?)def index\n\s+@places = [^\n]*?)\n/m, <<-CODE
\\1.page(params[:page])
  CODE

  gsub_file 'activities_controller.rb', /(\n(\s*?)def index\n\s+@activities = [^\n]*?)\n/m, <<-CODE
\\1.page(params[:page])
  CODE

end

inside 'app/views/' do

  insert_into_file 'comments/index.html.haml', before: /^%(table|br)/ do
    <<-CODE
= paginate @comments
    CODE
  end

  insert_into_file 'places/index.html.haml', before: /^%(table|br)/ do
    <<-CODE
= paginate @places
    CODE
  end

  insert_into_file 'activities/index.html.haml', before: /^%(table|br)/ do
    <<-CODE
= paginate @activities
    CODE
  end

end

inside 'spec/views/' do
  gsub_file 'comments/index.html.haml_spec.rb', /(@(comments) = assign\(:\2, )(create_list.+?)(\))\n/, <<-CODE
\\1Kaminari.paginate_array(\\3).page(1)\\4
CODE

  gsub_file 'places/index.html.haml_spec.rb', /(@(places) = assign\(:\2, )(create_list.+?)(\))\n/, <<-CODE
\\1Kaminari.paginate_array(\\3).page(1)\\4
CODE

  gsub_file 'activities/index.html.haml_spec.rb', /(@(activities) = assign\(:\2, )(create_list.+?)(\))\n/, <<-CODE
\\1Kaminari.paginate_array(\\3).page(1)\\4
CODE

end
