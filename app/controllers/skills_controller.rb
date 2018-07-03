# frozen_string_literal: true

class SkillsController < ApplicationController
  def index
    authorize @skills = Skill.all
  end

  def show
    authorize @skill = Skill.find(params[:id])
  end

  def new
    authorize @skill = Skill.new
  end

  def create
    authorize @skill = Skill.new(new_skill_params)

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
    @skill.discarded_at = skill_params[:archive] == '1' ? Time.now : nil

    if @skill.update(new_skill_params)
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

  def new_skill_params
    params.require(:skill).permit(:name, :license_required, :volunteerable)
  end
end
