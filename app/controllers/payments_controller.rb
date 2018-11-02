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

    @money_hsh = {
      'Bill amount': @payment.bill_amt.format,
      'Payment amount': @payment.payment_amt&.format,
      'Payment method': @payment.method
    }

    @date_hsh = {
      'Receved on': human_date(@payment.received),
      'Due on': human_date(@payment.due),
      'Paid on': human_date(@payment.paid)
    }

    @related_hsh = {
      'Paid to': @payment.to.is_a?(Organization) ? @payment.to.name : view_context.link_to(@payment.to.name, @payment.to),
      'On behalf of': view_context.link_to(@payment.for.name, @payment.for)
    }

    if @payment.to.is_a? Organization
      @related_hsh['Paid from'] = view_context.link_to(@payment.from.name, @payment.from)
    end

    @recurrence_hsh = {
      'Recurring': human_boolean(@payment.recurring?),
      'Recurrence': @payment.recurrence
    }

    @utility_hsh = {
      'Utility type': @payment.utility_type,
      'Utility account #': @payment.utility_account,
      'Utility started': human_date(@payment.utility_service_started)
    }

    @last_hsh = {
      'Created by': @payment.creator.name,
      'Send email reminders': human_boolean(@payment.send_email_reminders),
      'Suppress system alerts': human_boolean(@payment.suppress_system_alerts)
    }
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
