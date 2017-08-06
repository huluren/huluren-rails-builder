file 'config/initializers/ckeditor.rb', <<-CODE
Ckeditor::Rails.configure do |config|
  # default is nil for all languages, or set as %w[en zh]
  config.assets_languages = %w{ zh-cn zh en }

  # default is nil for all plugins,
  # or set as white list: %w[image link liststyle table tabletools]
  # or set as black list: config.default_plugins - %w[about a11yhelp]
  config.assets_plugins = nil

  # default is nil for all skins, or set as %w[moono-lisa]
  config.assets_skins = nil
end

Rails.application.config.assets.precompile += %w(ckeditor/*)
NonStupidDigestAssets.whitelist += %w(ckeditor/config.js)
CODE

inside('app/assets/javascripts') do
  file 'ckeditor.coffee', <<-CODE
//= require ckeditor-jquery

$(document).on "turbolinks:load", ->

  $(".ckeditor").ckeditor()

  true
  CODE

  file 'ckeditor/config.coffee', <<-CODE
CKEDITOR.editorConfig = (config) ->
  config.toolbar_Mini = [
    { name: 'basicstyles', items: [ 'Bold','Italic','Underline' ] },
    { name: 'paragraph',   items: [ 'NumberedList','BulletedList' ] },
    { name: 'insert',      items: [ 'Image','HorizontalRule','Smiley' ] },
    { name: 'links',       items: [ 'Link', 'Unlink' ] }
    { name: 'clipboard',   items: [ 'Undo','Redo' ] }
  ]
  config.toolbar = 'Mini'
  config.resize_dir = 'both'
  config.enterMode = CKEDITOR.ENTER_BR
  config.shiftEnterMode = CKEDITOR.ENTER_P
  true
  CODE
end

inside 'app/assets/stylesheets/ckeditor/' do
  file 'contents.css.scss', <<-CODE
p > img {
  max-width: 360px;
  max-height: 360px;
}
  CODE
end
