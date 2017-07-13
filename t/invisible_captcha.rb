inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController', <<-CODE
  invisible_captcha only: [:create]
CODE

insert_into_file 'app/views/activities/_form.html.haml', before: /^(  ?)= f\.hidden_field/ do
  <<-CODE
\\1= invisible_captcha
  CODE
end
