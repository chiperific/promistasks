# frozen_string_literal: true

RailsAdmin.config do |config|
  config.main_app_name = ['Promise Tasks', 'Admin']
  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end

  config.current_user_method(&:current_user)

  # config.authorize_with do
  #   if current_user&.system_admin? == false
  #     flash[:warning] = 'Only System Admins can access this.'
  #     redirect_to main_app.root_path
  #   end
  # end

  config.compact_show_view = false

  config.browser_validations = false

  config.excluded_models = [Task, SkillTask, SkillUser]

  ## == Cancan ==
  # config.authorize_with :cancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  config.show_gravatar = false

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    # bulk_delete
    show
    edit
    clone
    # delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.model Connection do
    parent Property
    label 'Person <-> Property'
    label_plural 'People <-> Properties'
    weight 0
    list do
      scopes %i[active archived]
      field :property
      field :user
      field :relationship
    end

    edit do
      field :property
      field :user
      field :relationship

      field :stage do
        help 'make sure relationship is tennant when assigning'
      end

      field :stage_date do
        label 'Assigned stage on'
      end

      field :discarded_at do
        label 'Archived on'
        help 'If this was a mistake, archive it by setting a date'
      end
    end

    show do
      field :property
      field :user
      field :relationship
      field :stage

      field :stage_date do
        label 'Assigned stage on'
      end

      field :discarded_at do
        label 'Archived on'
      end

      field :created_at
      field :updated_at
    end
  end

  config.model Property do
    weight 1
    label 'Property (tasklist)'
    label_plural 'Properties (tasklists)'
    list do
      scopes %i[active needs_title archived]
      field :name
      field :address
      field :city
      field :postal_code
    end

    edit do
      group :basics do
        label 'Basic info'
      end

      group :tasklist do
        label 'Tasklist properties'
        active false
      end

      group :tasks do
        label 'Tasks'
        active false
      end

      group :connections do
        label 'People'
        active false
      end

      group :location do
        label 'Location'
        active false
      end

      group :data do
        label 'Technical info'
        active false
      end

      field :name do
        group :basics
      end

      field :description do
        group :basics
      end

      field :acquired_on do
        group :basics
      end

      field :budget do
        group :basics
      end

      field :budget_remaining do
        group :basics
        read_only true
        formatted_value{ bindings[:object].budget_remaining }
      end

      field :cost do
        group :basics
      end

      field :lot_rent do
        group :basics
      end

      field :discarded_at do
        label 'Archive as of'
        help 'archiving will hide this property from view'
        group :basics
      end

      field :private do
        label 'Private tasklist?'
        help 'Only visible to the creator if checked'
        group :tasklist
      end

      field :creator do
        help 'Only change this to allow another staff to mark private'
        group :tasklist
      end

      field :tasks do
        label 'Associated tasks:'
        group :tasks
      end

      field :connections do
        group :connections
      end

      field :address do
        group :location
      end

      field :city do
        group :location
      end

      field :state do
        group :location
      end

      field :postal_code do
        group :location
      end

      field :certificate_number do
        label 'Title (certificate number)'
        group :data
      end

      field :serial_number do
        group :data
      end

      field :year_manufacture do
        label 'Year manufactured'
        group :data
      end

      field :manufacturer do
        group :data
      end

      field :model do
        group :data
      end

      field :certification_label1 do
        group :data
      end

      field :certification_label2 do
        help 'double-wides have two labels'
        group :data
      end
    end

    show do
      group :basics do
        label 'Basic info'
      end

      group :tasklist do
        label 'Tasklist properties'
        active false
      end

      group :tasks do
        label 'Tasks'
        active false
      end

      group :connections do
        label 'People'
        active false
      end

      group :location do
        label 'Location'
        active false
      end

      group :data do
        label 'Technical info'
        active false
      end

      field :name do
        group :basics
      end

      field :description do
        group :basics
      end

      field :acquired_on do
        group :basics
      end

      field :budget do
        group :basics
      end

      field :budget_remaining do
        group :basics
        formatted_value{ bindings[:object].budget_remaining }
      end

      field :cost do
        group :basics
      end

      field :lot_rent do
        group :basics
      end

      field :discarded_at do
        label 'Archive as of'
        help 'archiving will hide this property from view'
        group :basics
      end

      field :private do
        label 'Private tasklist?'
        help 'Only visible to the creator if checked'
        group :tasklist
      end

      field :creator do
        help 'Only change this to allow another staff to mark private'
        group :tasklist
      end

      field :tasks do
        label 'Associated tasks:'
        group :tasks
      end

      field :connections do
        group :connections
      end

      field :address do
        group :location
      end

      field :city do
        group :location
      end

      field :state do
        group :location
      end

      field :postal_code do
        group :location
      end

      field :certificate_number do
        label 'Title (certificate number)'
        group :data
      end

      field :serial_number do
        group :data
      end

      field :year_manufacture do
        label 'Year manufactured'
        group :data
      end

      field :manufacturer do
        group :data
      end

      field :model do
        group :data
      end

      field :certification_label1 do
        group :data
      end

      field :certification_label2 do
        help 'double-wides have two labels'
        group :data
      end

      field :google_id do
        label 'Tasklist ID'
        group :data
      end

      field :selflink do
        label 'Tasklist link'
        group :data
      end

      field :created_at do
        group :data
      end

      field :updated_at do
        group :data
      end
    end
  end

  config.model Skill do
    parent User
    weight 0
    list do
      scopes %i[active archived]
      field :name
      field :license_required
      field :volunteerable do
        label 'volunteer-able'
      end
    end

    edit do
      include_all_fields
      exclude_fields :skill_tasks, :skill_users
    end

    show do
      include_all_fields
      exclude_fields :skill_tasks, :skill_users
    end
  end

  config.model User do
    weight 0
    list do
      scopes %i[staff not_staff all archived]
      field :name
      field :type
      field :system_admin do
        visible do
          bindings[:view].params['scope'] == 'staff' || nil
        end
      end
    end

    edit do
      group :basics do
        label 'Basic info'
      end

      group :login_info do
        label 'login info'
        active false
      end

      group :types do
        label 'Contact Types'
        active false
      end

      group :skills do
        label 'Skills'
        active false
      end

      group :associations do
        label 'Skills, Properties and Tasks'
        active false
      end

      group :contact_info do
        label 'Contact info'
        active false
      end

      field :name do
        group :basics
      end

      field :title do
        group :basics
      end

      field :discarded_at do
        group :basics
        label 'Archive as of'
        help '(You can\'t archive yourself)'
        read_only do
          bindings[:view]._current_user.id == bindings[:object].id
        end
      end

      field :program_staff do
        group :types
      end

      field :project_staff do
        group :types
      end

      field :admin_staff do
        group :types
      end

      field :system_admin do
        group :types
      end

      field :client do
        group :types
      end

      field :volunteer do
        group :types
      end

      field :contractor do
        group :types
      end

      field :rate do
        group :types
        label 'Contractor rate:'
      end

      field :skills do
        group :skills
      end

      field :connections do
        group :associations
        label 'Connected to properties:'
      end

      field :created_properties do
        group :associations
        label 'Created these properties:'
      end

      field :created_tasks do
        group :associations
        label 'Created these tasks:'
      end

      field :owned_tasks do
        group :associations
        label 'Owns these tasks:'
      end

      field :subject_tasks do
        group :associations
        label 'Subject of these tasks:'
      end

      field :email do
        group :login_info
      end

      field :password do
        group :login_info
      end

      field :password_confirmation do
        group :login_info
      end

      field :phone1 do
        group :contact_info
      end

      field :phone2 do
        group :contact_info
      end

      field :address1 do
        group :contact_info
      end

      field :address2 do
        group :contact_info
      end

      field :city do
        group :contact_info
      end

      field :state do
        group :contact_info
      end

      field :postal_code do
        group :contact_info
      end
    end

    show do
      group :basics do
        label 'Basic info'
      end

      group :login_info do
        label 'Login info'
        active false
      end

      group :contact_info do
        label 'Contact info'
        active false
      end

      group :skills do
        label 'Skills'
        active false
      end

      group :types do
        label 'Contact Types'
        active false
      end

      group :associations do
        label 'Properties and Tasks'
        active false
      end

      group :technical do
        label 'Technical stuff'
        active false
      end

      field :name do
        group :basics
      end

      field :title do
        group :basics
      end

      field :discarded_at do
        group :basics
        label 'Archived on date'
      end

      field :type do
        group :types
      end

      field :system_admin do
        group :types
      end

      field :rate do
        group :types
        visible do
          bindings[:object].contractor?
        end
      end

      field :email do
        group :login_info
      end

      field :oauth_provider do
        group :login_info
        read_only true
      end

      field :phone1 do
        group :contact_info
      end

      field :phone2 do
        group :contact_info
      end

      field :address1 do
        group :contact_info
      end

      field :address2 do
        group :contact_info
      end

      field :city do
        group :contact_info
      end

      field :state do
        group :contact_info
      end

      field :postal_code do
        group :contact_info
      end

      field :remember_created_at do
        group :technical
      end

      field :sign_in_count do
        group :technical
      end

      field :current_sign_in_at do
        group :technical
      end

      field :last_sign_in_at do
        group :technical
      end

      field :created_at do
        group :technical
      end

      field :updated_at do
        group :technical
      end

      field :oauth_id do
        group :login_info
        read_only true
      end

      field :oauth_image_link do
        group :login_info
        read_only true
      end

      field :oauth_token do
        group :login_info
        read_only true
      end

      field :oauth_refresh_token do
        group :login_info
        read_only true
      end

      field :oauth_expires_at do
        group :login_info
        read_only true
      end
    end
  end
end
