# frozen_string_literal: true

class SkillsController < ApplicationController
  def index
    authorize @skills = Skill.all.order(:name)
  end

  def show
    authorize @skill = Skill.find(params[:id])

    @skill_users = @skill.skill_users
    @skill_tasks = @skill.skill_tasks
  end

  def new
    authorize @skill = Skill.new
  end

  def create
    authorize @skill = Skill.new(skill_params)

    if @skill.save
      msg = 'Skill created'

      if params[:skill][:task].present?
        task = Task.find(params[:skill][:task])
        @skill.tasks << task
        msg += ', added to task'
      end

      if params[:skill][:user].present?
        user = User.find(params[:skill][:user])
        @skill.users << user
        msg += ', added to user'
      end

      redirect_to @return_path, notice: msg
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new', task: skill_params[:task]
    end
  end

  def edit
    authorize @skill = Skill.find(params[:id])
  end

  def update
    authorize @skill = Skill.find(params[:id])
    @skill.discard if params[:skill][:archive] == '1' && !@skill.discarded?
    @skill.undiscard if params[:skill][:archive] == '0' && @skill.discarded?

    if @skill.update(skill_params)
      redirect_to @return_path, notice: 'Update successful'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def users
    authorize @skill = Skill.find(params[:id])

    @users = User.not_clients.select(:id, :name).order(:name)
  end

  def update_users
    authorize @skill = Skill.find(params[:id])

    current = @skill.users.map(&:id)

    if skill_users_params[:add_users].present?
      add = JSON.parse(skill_users_params[:add_users]).map(&:to_i)
      existing = current & add
      add -= existing
      @skill.users << User.find(add)
    end

    if skill_users_params[:remove_users].present?
      remove = JSON.parse(skill_users_params[:remove_users]).map(&:to_i)
      remove = current & remove
      @skill.users.delete(User.find(remove))
    end

    redirect_to @return_path
    flash[:alert] = add.nil? && remove.nil? ? 'Nothing changed' : 'Skills updated!'
  end

  def tasks
    authorize @skill = Skill.find(params[:id])

    @properties = Property.except_default

    @tasks = Task.unscoped.in_process.order(:title)
  end

  def update_tasks
    authorize @skill = Skill.find(params[:id])

    badbad

    current = @skill.tasks.map(&:id)

    if skill_tasks_params[:add_tasks].present?
      add = JSON.parse(skill_tasks_params[:add_tasks]).map(&:to_i)
      existing = current & add
      add -= existing
      @skill.tasks << Task.find(add)
    end

    if skill_tasks_params[:remove_tasks].present?
      remove = JSON.parse(skill_tasks_params[:remove_tasks]).map(&:to_i)
      remove = current & remove
      @skill.tasks.delete(Task.find(remove))
    end

    redirect_to @return_path
  end

  private

  def skill_params
    params.require(:skill).permit(:name, :license_required, :volunteerable)
  end

  def skill_users_params
    params.require(:skill).permit(:add_users, :remove_users)
  end

  def skill_tasks_params
    params.require(:skill).permit(:add_tasks, :remove_tasks)
  end
end
