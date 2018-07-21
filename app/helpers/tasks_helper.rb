module TasksHelper
  def parse_completed_at(params)
    params[:completed_at] = Time.parse(params[:completed_at]) if params[:completed_at].present?
    params
  end
end
