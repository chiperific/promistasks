# frozen_string_literal: true

class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[show edit update]

  def index
    authorize @payments = Payment.active.order(:due, :received, :paid)
  end

  def history
    authorize @payments = Payment.history.order(:due, :received, :paid)
  end

  def show
    authorize @payment
  end

  def new
    authorize @payment = Payment.new

    # handle params for everything
  end

  def create
    authorize @payment = Payment.new(payment_params)

    @payment.creator = current_user

    if @payment.save
      redirect_to @return_path, notice: 'Payment created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @payment
  end

  def update
    authorize @payment

    @payment.discard if params[:payment][:archive] == '1' && !@payment.discarded?
    @payment.undiscard if params[:payment][:archive] == '0' && @payment.discarded?

    if @payment.update(payment_params)
      redirect_to @return_path, notice: 'Payment updated'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:contractor_id, :park_id, :utility_id, :client_id, :property_id, :task_id,
                                    :paid_to, :on_behalf_of,
                                    :utility_type, :utility_account,
                                    :utility_service_started,
                                    :notes, :bill_amt, :payment_amt, :bill_amt_currency, :payment_amt_currency, :method,
                                    :received, :due, :paid,
                                    :recurrence, :recurring,
                                    :send_email_reminders, :suppress_system_alerts)
  end
end
