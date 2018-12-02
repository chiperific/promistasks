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

    if @payment.task.present?
      @related_hsh['Task'] = view_context.link_to(@payment.task.name, @payment.task)
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

    if params[:utility].present?
      @to_utility = true
      @payment.utility = Utility.find(params[:utility])
    end

    if params[:park].present?
      @to_park = true
      @payment.park = Park.find(params[:park])
    end

    if params[:contractor].present?
      @to_contractor = true
      @payment.contractor = User.find(params[:contractor])
    end

    if params[:pay_client].present?
      @to_client = true
      @payment.client = User.find(params[:pay_client])
    end

    if params[:for_client].present?
      @for_client = true
      @payment.client = User.find(params[:for_client])
    end

    if params[:property].present?
      @for_property = true
      @payment.property = Property.find(params[:property])
    end

    @to_organization = true if params[:organization].present?

    @utilities   = Utility.kept.order(:name).pluck(:name, :id)
    @parks       = Park.kept.order(:name).pluck(:name, :id)
    @users       = User.kept.order(:name)
    @contractors = @users.where(contractor: true).map { |u| [u.name, u.id] }
    @clients     = @users.where(client: true).map { |u| [u.name, u.id] }
    @properties  = Property.kept.order(:name).pluck(:name, :id)
    @tasks       = Task.kept.pluck(:title, :id)
  end

  def create
    authorize @payment = Payment.new(payment_params_wo_relations)
    @payment.creator = current_user

    @payment.manage_relationships(payment_params)

    if @payment.save
      redirect_to @return_path, notice: 'Payment created'
    else
      flash[:warning] = 'Oops, found some errors'
      @utilities   = Utility.kept.order(:name).pluck(:name, :id)
      @parks       = Park.kept.order(:name).pluck(:name, :id)
      @users       = User.kept.order(:name)
      @contractors = @users.where(contractor: true).map { |u| [u.name, u.id] }
      @clients     = @users.where(client: true).map { |u| [u.name, u.id] }
      @properties  = Property.kept.order(:name).pluck(:name, :id)
      @tasks       = Task.kept.pluck(:title, :id)
      render 'new'
    end
  end

  def edit
    authorize @payment

    @to_utility    = @payment.utility_id.present?
    @to_park       = @payment.park_id.present?
    @to_contractor = @payment.contractor_id.present?
    @to_client     = @payment.client_id.present? && @payment.paid_to == 'client'
    @for_client    = @payment.client_id.present? && @payment.on_behalf_of == 'client'
    @for_property  = @payment.property_id.present?

    @utilities   = Utility.kept.order(:name).pluck(:name, :id)
    @parks       = Park.kept.order(:name).pluck(:name, :id)
    @users       = User.kept.order(:name)
    @contractors = @users.where(contractor: true).map { |u| [u.name, u.id] }
    @clients     = @users.where(client: true).map { |u| [u.name, u.id] }
    @properties  = Property.kept.order(:name).pluck(:name, :id)
    @tasks       = Task.kept.pluck(:title, :id)
  end

  def update
    authorize @payment

    @payment.discard if params[:payment][:archive] == '1' && !@payment.discarded?
    @payment.undiscard if params[:payment][:archive] == '0' && @payment.discarded?

    @payment.manage_relationships(payment_params)

    if @payment.update(payment_params_wo_relations)
      redirect_to @return_path, notice: 'Payment updated'
    else
      flash[:warning] = 'Oops, found some errors'
      @utilities   = Utility.kept.order(:name).pluck(:name, :id)
      @parks       = Park.kept.order(:name).pluck(:name, :id)
      @users       = User.kept.order(:name)
      @contractors = @users.where(contractor: true).map { |u| [u.name, u.id] }
      @clients     = @users.where(client: true).map { |u| [u.name, u.id] }
      @properties  = Property.kept.order(:name).pluck(:name, :id)
      @tasks       = Task.kept.pluck(:title, :id)
      render 'edit'
    end
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:send_email_reminders, :suppress_system_alerts,
                                    :paid_to, :on_behalf_of,
                                    :contractor_id, :park_id, :utility_id, :client_id, :property_id,
                                    :client_id_obo, :task_id,
                                    :notes, :bill_amt, :payment_amt, :method,
                                    :received, :due, :paid,
                                    :utility_type, :utility_account, :utility_service_started,
                                    :recurring, :recurrence)
  end

  def payment_params_wo_relations
    params.require(:payment).permit(:send_email_reminders, :suppress_system_alerts,
                                    :paid_to, :on_behalf_of, :task_id,
                                    :notes, :bill_amt, :payment_amt, :method,
                                    :received, :due, :paid,
                                    :utility_type, :utility_account, :utility_service_started,
                                    :recurring, :recurrence)
  end
end
