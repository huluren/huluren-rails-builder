
#========== Title ==========#
inside 'app/views/layouts/' do
  gsub_file 'application.html.erb', /(<title>).*(<\/title>)/, %^\1<%= title %>\2^
end

inside 'config/locales/' do
  file 'title.en.yml', <<-CODE
en:
  titles:
    application: #{app_name.camelize}
  CODE

  file 'title.zh-CN.yml', <<-CODE
zh-CN:
  titles:
    application: #{app_name.camelize}
  CODE
end
