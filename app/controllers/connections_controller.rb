# frozen_string_literal: true

class ConnectionsController < ApplicationController
  def index
    authorize Connection.first

    @connection_properties = Property.kept.left_outer_joins(:connections).where.not( connections: { id: nil } ).where.not( connections: { relationship: 'tennant' } ).uniq
    @occupancy_properties =  Property.kept.left_outer_joins(:connections).where.not( connections: { id: nil } ).where( connections: { relationship: 'tennant' } ).uniq
    @connection_users =      User.kept.left_outer_joins(:connections).where.not( connections: { id: nil } ).where.not( connections: { relationship: 'tennant' } ).uniq
    @occupancy_users =       User.kept.left_outer_joins(:connections).where.not( connections: { id: nil } ).where( connections: { relationship: 'tennant' } ).uniq
  end

  def new
    authorize @connection = Connection.new

    @connection.user = User.find(params[:user]) if params[:user].present?
    @connection.property = Property.find(params[:property]) if params[:property].present?
    @connection.relationship = params[:relationship] if params[:relationship].present?
  end

  def create
    authorize @connection = Connection.new(connection_params)

    if @connection.save
      redirect_to @return_path, notice: 'Connection created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @connection = Connection.find(params[:id])
  end

  def update
    authorize @connection = Connection.find(params[:id])

    @connection.discard unless params[:connection][:archive] == '0' || @connection.discarded?
    @connection.undiscard if params[:connection][:archive] == '0' && @connection.discarded?

    if @connection.update(connection_params)
      redirect_to @return_path, notice: 'Update successful'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  private

  def connection_params
    params.require(:connection).permit(:property_id, :user_id,
                                       :relationship, :stage,
                                       :stage_date)
  end
end
