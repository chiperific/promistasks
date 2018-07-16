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

  private

  def skill_params
    params.require(:skill).permit(:name, :license_required, :volunteerable, :archive)
  end
end
