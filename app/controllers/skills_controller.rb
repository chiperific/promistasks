# frozen_string_literal: true

class SkillsController < ApplicationController
  def index
    authorize @skills = Skill.all.order(:name)
  end

  def show
    authorize @skill = Skill.find(params[:id])

    @skill_users = @skill.skill_users.kept
    @skill_tasks = @skill.skill_tasks.kept
  end

  def new
    authorize @skill = Skill.new
  end

  def create
    modified_params = parse_datetimes(skill_params.except(:archive))
    authorize @skill = Skill.new(modified_params)

    if @skill.save
      redirect_to @return_path, notice: 'Skill created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @skill = Skill.find(params[:id])
  end

  def update
    authorize @skill = Skill.find(params[:id])
    @skill.discard if skill_params[:archive] == '1'
    @skill.undiscard if skill_params[:archive] == '0' && @skill.discarded?

    modified_params = parse_datetimes(skill_params.except(:archive))
    if @skill.update(modified_params)
      redirect_to @return_path, notice: 'Update successful'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def destroy
    authorize @skill = Skill.find(params[:id])
    @skill.discard
    redirect_to @return_path, notice: 'Skill discarded'
  end

  def discarded
    authorize @skills = Skill.discarded
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
    if add.nil? && remove.nil?
      flash[:alert] = 'Nothing changed'
    else
      flash[:alert] = 'Skills updated!'
    end
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
    if add.nil? && remove.nil?
      flash[:alert] = 'Nothing changed'
    else
      flash[:alert] = 'Skills updated!'
    end
  end

  private

  def skill_params
    params.require(:skill).permit(:name, :license_required, :volunteerable, :archive)
  end

  def skill_users_params
    params.require(:skill).permit(:add_users, :remove_users)
  end

  def skill_tasks_params
    params.require(:skill).permit(:add_tasks, :remove_tasks)
  end
end
