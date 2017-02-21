if @message
  json.message @message
end

json.session do
  json.locale Kor.config['app.default_locale']
  json.csrfToken form_authenticity_token

  if current_user
    json.locale current_user.locale || Kor.config['app.default_locale']

    json.user do
      json.id current_user.id
      json.name current_user.name
      json.display_name current_user.display_name

      json.guest current_user.guest?
      json.permissions current_user.full_auth
      
      unless current_user.guest?
        json.email current_user.email
        json.history current_user.history
        json.clipboard current_user.clipboard
        json.terms_accepted current_user.terms_accepted?
      end
    end
  end
end