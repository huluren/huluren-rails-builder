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

gsub_file 'spec/views/comments/index.html.haml_spec.rb', /(@(comments) = assign\(:\2, )(create_list.+?)(\))\n/, <<-CODE
\\1Kaminari.paginate_array(\\3).page(1)\\4
CODE
