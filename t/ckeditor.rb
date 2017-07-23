inside('app/assets/javascripts') do
  insert_into_file 'application.js', before: '//= require rails-ujs' do
    <<-CODE
//= require ckeditor-jquery
    CODE
  end

  file 'ckeditor-config.coffee', <<-CODE
CKEDITOR.editorConfig = (config) ->
  config.toolbar_Mini = [
    { name: 'styles',      items: [ 'Font' ] },
    { name: 'basicstyles', items: [ 'Bold','Italic','Underline' ] },
    { name: 'paragraph',   items: [ 'NumberedList','BulletedList' ] },
    { name: 'insert',      items: [ 'Image','HorizontalRule','Smiley' ] },
    { name: 'clipboard',   items: [ 'Undo','Redo' ] },
    { name: 'tools',       items: [ 'Maximize' ] }
  ]
  config.toolbar = 'Mini'
  true
  CODE
end

inside('app/views/activities/') do
  file '_import_activity.html.haml', <<-CODE
= form_tag :import_new_activity, method: :get do
  = text_field_tag :url, nil, placeholder: t('activity.import')
  = submit_tag t('activity.import')
  CODE

  append_to_file 'index.html.haml', <<-CODE
= render 'import_activity'
  CODE
end

gsub_file 'config/routes.rb', /^(\s+?)resources :activities$/, <<-CODE
\\0 do
\\1  get 'import', on: :new
\\1end
CODE
