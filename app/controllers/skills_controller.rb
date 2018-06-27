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
    authorize @skill = Skill.find(params[:id])
  end

  def edit
    authorize @skill = Skill.find(params[:id])
  end

  def update
    authorize @skill = Skill.find(params[:id])
  end

  def destroy
    authorize @skill = Skill.find(params[:id])
    @skill.discard
    redirect_to skills_url, notice: 'Skill discarded'
  end

  def discarded
    authorize @skills = Skill.discarded
  end
end
