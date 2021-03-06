# frozen_string_literal: true

# Controlador para los Users
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only:
  %i[edit show change_password update_password update]
  before_action :setiar_user, only: [:ver_user]

  def index
    authorize User
    if params[:q].present?
      if params[:q].include? ':'
        # @users = User.with_role :"#{params[:q].gsub(':', '')}"
        @users = User.with_role(:aprendiz).where('cast(ndocumento as text) ilike :q', q: "%#{params[:q].gsub(":","").to_i}%").order(id: :asc).page params[:page]
      else
        @users = User.includes(:ficha).with_role(:aprendiz).where('cast(numero as text) ilike
        :q', q: "%#{params[:q]}%").references(:ficha).or(User.includes(
          :ficha).with_role(:aprendiz).where('ndocumento ilike :q or nombres
          ilike :q or apellidos ilike :q', q: "%#{params[:q]}%").references(:ficha)).page params[:page]
      end
    elsif current_user.has_role? :instructor
      @users = User.with_role(:aprendiz).page params[:page]
    end
    respond_html_and_csv
  end

  def respond_html_and_csv
    respond_to do |format|
      format.html
      format.xlsx do
        response.headers['Content-Disposition'] =
          'attachment; filename="Aprendices.xlsx"'
      end
    end
  end

  def show
    @user = if current_user.has_role? :admin
              User.find(params[:id])
            else
              User.find(current_user.id)
            end
  end

  def ver_user
    render template: 'users/show'
  end

  def edit; end

  def change_password; end

  def update_password
    if @user.update_with_password(user_params)
      # Sign in the user by passing validation in case their password changed
      bypass_sign_in(@user)
      # flash[:success] = 'Contraseña Actualizada'
      flash[:success] = t('.success')
      redirect_to '/'
    else
      # flash[:alert] = 'Error al Actualizar'
      flash[:alert] = t('.alert')
      render 'change_password'
    end
  end

  def update
    if current_user.update(user_params)
      # flash[:success] = 'Registro Actualizado'
      flash[:success] = t('.success')
      redirect_to edit_user_registration_path
    else
      # flash[:alert] = 'Error al Actualizar'
      flash[:alert] = t('.alert')
      redirect_to edit_user_registration_path
    end
  end

  private

  def set_user
    @user = current_user
  end

  def setiar_user
    @user = User.find(current_user.id)
  end

  def buscar
    @user = User.find_by(user.ndocumento)
  end

  def user_params
    params.require(:user).permit(
                                 :email,
                                 :password,
                                 :current_password, :password_confirmation,
                                 :nombres, :apellidos,
                                 :ndocumento, :telefono,
                                 :direccion, :avatar,
                                 :tipodocumento_id, :ficha_id)
  end
end
