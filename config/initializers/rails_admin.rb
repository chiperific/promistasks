# frozen_string_literal: true

RailsAdmin.config do |config|
  config.main_app_name = ['Promise Tasks', 'Admin']
  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  config.compact_show_view = false

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
    visible false
  end

  config.model Property do
    visible false
  end

  config.model SkillTask do
    visible false
  end

  config.model SkillUser do
    visible false
  end

  config.model Skill do
    weight 1
    list do
      scopes %i[active discarded]
      field :name
      field :license_required
      field :volunteerable do
        label 'volunteer-able'
      end
      exclude_fields :skill_tasks, :skill_users
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

  config.model Task do
    visible false
  end

  config.model User do
    weight 0
    list do
      scopes %i[staff not_staff discarded]
      field :name
      field :title
      field :type
      field :system_admin
    end

    edit do
      group :basics do
        label 'Basic info'
      end

      group :login_info do
        label 'login info'
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
        label 'Skills, Properties and Tasks'
        active false
      end

      field :name do
        group :basics
      end

      field :title do
        group :basics
      end

      field :discarded_at do
        group :types
        label 'Archive as of'
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
        label 'login info'
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
        group :types
        label 'Archived on date'
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
      end

      field :email do
        group :login_info
      end

      field :oauth_provider do
        group :login_info
        read_only true
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
    end
  end
end
