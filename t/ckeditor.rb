inside('app/assets/javascripts') do
  insert_into_file 'application.js', after: "//= require rails-ujs\n" do
    <<-CODE
//= require ckeditor-jquery
    CODE
  end

  file 'ckeditor/config.coffee', <<-CODE
CKEDITOR.editorConfig = (config) ->
  config.toolbar_Mini = [
    { name: 'styles',      items: [ 'Font' ] },
    { name: 'basicstyles', items: [ 'Bold','Italic','Underline' ] },
    { name: 'paragraph',   items: [ 'NumberedList','BulletedList' ] },
    { name: 'insert',      items: [ 'Image','HorizontalRule','Smiley' ] },
    { name: 'links',       items: [ 'Link', 'Unlink' ] }
    { name: 'clipboard',   items: [ 'Undo','Redo' ] }
  ]
  config.toolbar = 'Mini'
  config.resize_dir = 'both'
  true
  CODE
end
