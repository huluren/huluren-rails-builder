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
