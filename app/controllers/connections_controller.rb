# frozen_string_literal: true

class ConnectionsController < ApplicationController
  def index
    authorize @connections = Connection.all
  end

  def show
    authorize @connection = Connection.find(params[:id])
  end

  def new
    authorize @connection = Connection.new
  end

  def create
    modified_params = parse_datetimes(connection_params.except(:archive))
    authorize @connection = Connection.new(modified_params)

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

    @connection.discard if connection_params[:archive] == '1'
    @connection.undiscard if connection_params[:archive] == '0' && @connection.discarded?

    modified_params = parse_datetimes(connection_params.except(:archive))
    if @connection.update(modified_params)
      redirect_to @return_path, notice: 'Update successful'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
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
