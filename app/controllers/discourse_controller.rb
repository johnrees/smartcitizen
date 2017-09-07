class DiscourseController < ApplicationController

  before_action :check_if_authorized!

  def check_if_authorized!
    if current_user.nil?
      if params[:access_token]
        raise Smartcitizen::Unauthorized.new("Invalid OAuth2 Params")
      else
        raise Smartcitizen::Unauthorized.new("Authorization required")
      end
    end
  end



  def sso
    secret = Figaro.env.discourse_sso_secret
    sso = SingleSignOn.parse(request.query_string, secret)
    sso.email = current_user.email # from devise
    sso.name = current_user.full_name # this is a custom method on the User class
    sso.username = current_user.email # from devise
    #sso.username = current_user.username
    sso.external_id = current_user.id # from devise
    sso.sso_secret = secret

    redirect_to sso.to_url("#{Figaro.env.discourse_endpoint}session/sso_login")
  rescue => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace)
    #flash[:error] = 'SSO error'
    render inline: "Error, check logs"

    #redirect_to "/"
    #redirect_to root
  end

end
