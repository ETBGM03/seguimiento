# frozen_string_literal: true

module Ambientes
  class AnotacionesController < ApplicationController
    before_action :authenticate_user!
    respond_to :html
    before_action :set_ambiente
    before_action :set_anotacion, only: %i[show edit update destroy]
    before_action :set_operator, only: %i[create update]

    def index
      if params[:q].present?
        if params[:q].include? ':'
          @anotaciones = @ambiente.anotaciones.where('cast(id as text) ilike :q', q: "%#{params[:q].gsub(":","").to_i}%").order(id: :asc).page params[:page]
        else
          @anotaciones = @ambiente.anotaciones.where('cast(id as text) ilike :q or cast(created_at as text) ilike :q', q: "%#{params[:q]}%").or(@user.anotaciones.where('cast(created_by as text) ilike any (array[?])', User.where('nombres ilike :q or apellidos ilike :q', q:"%#{params[:q]}%").ids.map {|val| val.to_s})).order(id: :asc).page params[:page]
        end
      elsif current_user.has_role? :instructor
        @anotaciones = @ambiente.anotaciones.order(id: :asc).page params[:page]
      end
      respond_html_and_csv
    end

def respond_html_and_csv
  respond_to do |format|
    format.html
    format.xlsx do
      response.headers['Content-Disposition'] = 'attachment; filename="AmbientesAnotaciones.xlsx"'
    end
  end
end

    def show; end

    def new
      @anotacion = @ambiente.anotaciones.new
    end

    def create
      @anotacion = @ambiente.anotaciones.new(anotacion_params)
      if @anotacion.save
        flash[:success] = t('.success')
        respond_with @ambiente, @anotacion
      else
        flash[:alert] = t('.alert')
        render :new
      end
    end

    def edit; end

    def update
      if @anotacion.update(anotacion_params)
        flash[:success] = 'Anotacion Registrada'
        respond_with @ambiente, @anotacion
      else
        flash[:alert] = t('.alert')
        render 'edit'
      end
    end

    def destroy
      @anotacion.destroy
      flash[:success] = t('.success')
      respond_with @ambiente, :anotaciones
    end

    private

    def set_anotacion
      @anotacion = Anotacion.find(params[:id])
    end

    def set_ambiente
      @ambiente = Ambiente.find(params[:ambiente_id])
    end

    def set_operator
      OperatorRecordable.operator = current_user
    end

    def anotacion_params
      params.require(:anotacion).permit(:descripcion, :file)
    end
  end
end
