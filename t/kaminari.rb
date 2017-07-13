generate 'kaminari:views bootstrap4'

inside 'app/controllers/' do

  gsub_file 'activities_controller.rb', /(\n(\s*?)def index\n[^\n]*?Activity\..*)\n/m, <<-CODE
\\1.page(params[:page])
  CODE

  gsub_file 'places_controller.rb', /(\n(\s*?)def index\n[^\n]*?Place\..*)\n/m, <<-CODE
\\1.page(params[:page])
  CODE

end
