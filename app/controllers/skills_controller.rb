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
    add = skill_users_params[:add_users].split(',').map(&:to_i)
    existing = current & add
    add -= existing

    remove = skill_users_params[:remove_users].split(',').map(&:to_i)
    remove = current & remove

    @skill.users << User.find(add)
    @skill.users.delete(User.find(remove))

    redirect_to @return_path
    flash[:alert] = 'Skills updated!'
  end

  def tasks
    authorize @skill = Skill.find(params[:id])

    @tasks = Task.unscoped.not_primary.in_process.joins(:property).order('properties.name', :title).select(:id, :title, :property_id)
  end

  def update_tasks
    authorize @skill = Skill.find(params[:id])

    current = @skill.tasks.map(&:id)
    add = skill_tasks_params[:add_tasks].split(',').map(&:to_i)
    existing = current & add
    add -= existing

    remove = skill_tasks_params[:remove_tasks].split(',').map(&:to_i)
    remove = current & remove

    @skill.tasks << Task.find(add)
    @skill.tasks.delete(Task.find(remove))

    redirect_to @return_path
    flash[:alert] = 'Skills updated!'
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
