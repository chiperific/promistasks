# frozen_string_literal: true

class ConnectionsController < ApplicationController
  def new
    authorize @connection = Connection.new
  end

  def create
    authorize @connection = Connection.find(params[:id])
  end

  def edit
    authorize @connection = Connection.find(params[:id])
  end

  def update
    authorize @connection = Connection.find(params[:id])
  end

  def destroy
    authorize @connection = Connection.find(params[:id])
  end

  def discarded
    authorize @connection = Connection.discarded
  end

  private

  def connection_params
    params.require(:connection).permit(:property_id, :user_id,
                                       :relationship, :stage,
                                       :stage_date, :archive)
  end
end
