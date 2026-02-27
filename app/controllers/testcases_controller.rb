require 'csv'

class TestcasesController < ApplicationController
  before_action :find_issue
  before_action :find_testcase, only: [:show, :edit, :update, :destroy]
  before_action :authorize_view, only: [:index, :show, :export_csv, :print_view]
  before_action :authorize_manage, only: [:new, :create, :edit, :update, :destroy]
  before_action :check_tracker_configured

  helper :issues
  helper :testcases

  def index
    @testcases = @issue.testcases.order(:position)
    @summary = calculate_summary(@testcases)

    respond_to do |format|
      format.html
      format.json { render json: @testcases }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @testcase }
    end
  end

  def new
    @testcase = @issue.testcases.build
    @testcase.status = 'not_executed'
  end

  def create
    @testcase = @issue.testcases.build(testcase_params)

    if @testcase.save
      flash[:notice] = l(:notice_test_case_created)
      redirect_to issue_path(@issue, tab: 'testcases')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @testcase.update(testcase_params)
      flash[:notice] = l(:notice_test_case_updated)
      redirect_to issue_path(@issue, tab: 'testcases')
    else
      render :edit
    end
  end

  def destroy
    @testcase.destroy
    flash[:notice] = l(:notice_test_case_deleted)
    redirect_to issue_path(@issue, tab: 'testcases')
  end

  def export_csv
    @testcases = @issue.testcases.order(:position)

    csv_data = generate_csv(@testcases)

    send_data csv_data,
              type: 'text/csv; charset=utf-8',
              filename: l(:label_export_filename, issue_id: @issue.id)
  end

  def print_view
    @testcases = @issue.testcases.order(:position)
    @summary = calculate_summary(@testcases)

    render layout: 'base'
  end

  private

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_testcase
    @testcase = @issue.testcases.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_view
    # Global permission check - no project context needed
    unless User.current.allowed_to_globally?(:view_test_cases)
      render_403
    end
  end

  def authorize_manage
    # Global permission check - no project context needed
    unless User.current.allowed_to_globally?(:manage_test_cases)
      render_403
    end
  end

  def check_tracker_configured
    testcase_tracker_id = Setting.plugin_redmine_testcase['testcase_tracker_id']

    if testcase_tracker_id.blank?
      flash[:error] = l(:text_no_tracker_selected)
      redirect_to issue_path(@issue)
      return false
    end

    unless @issue.tracker_id.to_s == testcase_tracker_id.to_s
      render_403
    end
  end

  def testcase_params
    params.require(:testcase).permit(
      :test_case_id,
      :title,
      :preconditions,
      :steps,
      :expected_result,
      :actual_result,
      :status,
      :comments,
      :position
    )
  end

  def calculate_summary(testcases)
    summary = {
      total: testcases.count,
      by_status: {}
    }

    Testcase.status_values.each do |status|
      count = testcases.where(status: status).count
      summary[:by_status][status] = count
    end

    passed_count = summary[:by_status]['passed'] || 0
    total = summary[:total]
    summary[:pass_rate] = total > 0 ? (passed_count.to_f / total * 100).round(1) : 0

    summary
  end

  def generate_csv(testcases)
    CSV.generate(headers: true) do |csv|
      # CSV headers
      csv << [
        'Issue ID',
        'Issue Subject',
        'Test Case ID',
        'Title',
        'Preconditions',
        'Test Steps',
        'Expected Result',
        'Actual Result',
        'Status',
        'Comments',
        'Updated At'
      ]

      # CSV rows
      testcases.each do |tc|
        csv << [
          @issue.id,
          @issue.subject,
          tc.test_case_id,
          tc.title,
          tc.preconditions,
          tc.steps,
          tc.expected_result,
          tc.actual_result,
          tc.status_label,
          tc.comments,
          tc.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    end
  end

end
