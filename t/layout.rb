file 'config/locales/menu.yml', <<-CODE
en:
  menu:
    languages:
      lang: "Language"
      en: English
      zh-CN: 中文

    home: Home
    places: Place
    activities: Activity
    profile: Profile

    sign_up: Sign Up
    login: Login
    logout: Logout
    edit_profile: Update Profile

zh-CN:
  menu:
    home: 首页
    places: 目的地
    activities: 行程拼伴
    profile: 个人帐户

    sign_up: 注册
    login: 登入
    logout: 登出
    edit_profile: 更改账户信息
CODE

file 'config/locales/action.yml', <<-CODE
en:
  action:
    show: Show
    edit: Edit
    back: Back
    more: More

zh-CN:
  action:
    show: 查看
    edit: 修改
    back: 返回
    more: 更多
CODE

#========== Layout Helpers ==========#
insert_into_file 'app/helpers/application_helper.rb', after: %/module ApplicationHelper\n/ do
  <<-CODE
  def active_class(link_path, base: '')
    append_class(link_path, append: 'active', base: base)
  end

  def append_class(link_path, append: '', base: '')
    current_page?(link_path) ? [append, base].join(' ') : base
  end

  def flash_class(level, default=[])
    cls = case level.to_sym
      when :notice then [:alert, :'alert-info']
      when :success then [:alert, :'alert-success']
      when :error then [:alert, :'alert-danger']
      when :alert then [:alert, :'alert-warning']
      else []
    end
    return cls + default
  end
  CODE
end

#========== Layout Views ==========#
inside 'app/views/layouts/' do
  insert_into_file 'application.html.erb',
    %^    <%= stylesheet_link_tag    '//huluren.github.io/material-design-icons/iconfont/material-icons.css', media: 'all', 'data-turbolinks-track': 'reload' %>\n^,
    after: %^<%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>\n^

  gsub_file 'application.html.erb', '= yield', %!= render 'layouts/body'!
  file '_body.html.haml', <<-CODE
= render 'layouts/header'
= render 'layouts/main'
= render 'layouts/footer'
  CODE

  file '_header.html.haml', <<-CODE
= render 'layouts/menu'
  CODE

  file '_main.html.haml', <<-CODE
%main{class: [controller_name, action_name]}
  .container<
    = render 'layouts/flash'
  .container<
    = content_for?(:content) ? yield(:content) : yield
  CODE

  file '_footer.html.haml', <<-CODE
%footer.footer.text-muted
  .container
    .list-inline
      %a.m-2{href: '/'}<>= t('menu.home')
      \|
      %a.m-2{href: '/'}<>= t('menu.support')

    %p<
      .small.m-2<
        = surround "由", "提供技术支持" do
          = link_to 'Lax', '', class: 'm-1'
  CODE

  file '_flash.html.haml', <<-CODE
- flash.each do |name, msg|
  %div{class: flash_class(name, [:flash, :'alert-dismissible']), role: :alert}
    %button.close{type: "button", "data-dismiss": "alert", "aria-label": "Close"}
      %span{"aria-hidden": true} &times;
    %strong= '[%s]' % name
    %span= msg
  CODE

  file '_menu.html.haml', <<-CODE
%nav#navbar.navbar.navbar-inverse.bg-primary.fixed-top.navbar-toggleable-sm
  %button.navbar-toggler.navbar-toggler-right{'aria-controls': 'navbarNavCollapse', 'aria-expanded': 'false', 'aria-label': 'Toggle navigation', 'data-target': '#navbarNavCollapse', 'data-toggle': 'collapse', type: 'button'}
    %span.navbar-toggler-icon

  = link_to :root, class: 'navbar-brand' do
    %img{alt: :🏝⛵️🍀🌿}

  #navbarNavCollapse.collapse.navbar-collapse
    .navbar-nav.mr-auto
      = link_to :root, class: active_class(root_path, base: 'nav-item nav-link') do
        %i.material-icons.md-18<> home
        = t('menu.home')
        %span.sr-only> (current)
      = link_to :places, class: active_class(places_path, base: 'nav-item nav-link') do
        %i.material-icons.md-18<> map
        = t('menu.places')
      = link_to :activities, class: active_class(activities_path, base: 'nav-item nav-link') do
        %i.material-icons.md-18<> person_pin_circle
        = t('menu.activities')
      = content_for?(:controller_menu) ? yield(:controller_menu) : ''

    .navbar-nav
      - if ! user_signed_in?
        = link_to t('menu.sign_up'), :new_user_registration, class: active_class(new_user_registration_path, base: 'nav-item nav-link')
        = link_to t('menu.login'), :new_user_session, class: active_class(new_user_session_path, base: 'nav-item nav-link')
      - else
        .nav-item.dropdown
          %a#navbarProfileMenuLink.nav-link.dropdown-toggle{"aria-expanded": "false", "aria-haspopup": "true", "data-toggle": "dropdown"}
            %i.material-icons.md-18<> person
            = t('menu.profile')
            %span.caret>
          .dropdown-menu.dropdown-menu-right{"aria-labelledby": "navbarProfileMenuLink"}
            %h6.dropdown-header<
              = current_user.email
              %br<
              = precede "@" do
                %b>= current_user.id
            .dropdown-divider
            = link_to t('menu.edit_profile'), :edit_user_registration, class: active_class(edit_user_registration_path, base: 'dropdown-item')
            .dropdown-divider
            = link_to t('menu.logout'), :destroy_user_session, method: :delete, class: active_class(destroy_user_session_path, base: 'dropdown-item')
  CODE
end
