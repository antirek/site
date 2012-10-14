# coding: utf-8
require 'csv'

class Site < Sinatra::Base
  get '/company/register' do
    raise InviteRequired.new('Регистрация только по приглашениям') if session[:invite].nil?
    slim :'company/register'
  end

  post '/company/register' do
    raise InviteRequired.new('Регистрация только по приглашениям') if session[:invite].nil?
    invite = Invite.first(:code => session[:invite])
    raise InviteRequired.new('Приглашение уже было использовано ранее') unless invite.invitee.nil?

    identity = Identity.create email: params[:auth_key], password: params[:password], :role => 'customer', :name => params[:name]
    company = Company.create name: params[:company], :identity => identity

    invite.update(invitee: identity)
    session[:invite] = nil

    session[:user_id] = identity.id
    flash[:info] = "Добро пожаловать!"
    redirect '/company'
  end

  get '/company' do
    authorize! :view, Company
    company = current_identity.company
    slim :'company/index', locals: {company: company}
  end

  get '/company/instructions' do
    authorize! :view, Company
    company = current_identity.company
    slim :'company/instructions', locals: {company: company}
  end

  post '/company/instructions' do
    authorize! :edit, Company
    company = current_identity.company
    company.instructions = params[:text]
    company.save

    redirect '/company'
  end

  get '/company/targets' do
    authorize! :index, Target
    company = current_identity.company
    slim :'company/targets', locals: {company: company}
  end

  post '/company/target/create' do
    authorize! :create, Target
    company = current_identity.company

    Target.create name: params[:name], phone: params[:phone], company: company
    redirect '/company/targets'
  end

  post '/company/target/upload' do
    authorize! :create, Target
    company = current_identity.company

    puts params.inspect
    file = File.new params[:file]

    CSV.parse(file.read) do |row|
      target = Target.create name: row[0], phone: row[1], company: company
    end

    redirect '/company/targets'
  end
end
