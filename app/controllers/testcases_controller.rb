require 'csv'

class TestcasesController < ApplicationController
  accept_api_auth :index, :show

  before_action :find_issue
  before_action :find_testcase, only: [:show, :edit, :update, :destroy]
  before_action :authorize_view, only: [:index, :show, :export_csv, :print_view]
  before_action :authorize_manage, only: [:new, :create, :edit, :update, :destroy]
  before_action :check_tracker_configured

  helper :issues
  helper :testcases
  helper :attachments

  def index
    @testcases = @issue.testcases.includes(:attachments, :issue).order(:position)
    @summary = Testcase.summary(@issue.testcases)

    respond_to do |format|
      format.html
      format.json { render json: @testcases }
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to issue_path(@issue, tab: 'testcases') }
      format.json { render json: @testcase }
    end
  end

  def new
    @testcase = @issue.testcases.build
    @testcase.status = 'not_executed'
  end

  def create
    @testcase = @issue.testcases.build
    
    # Safe attributes mapping for plugins usually involves direct assignment in Redmine 
    # but we'll manually handle attachments to ensure they bind correctly before save.
    @testcase.safe_attributes = testcase_params if @testcase.respond_to?(:safe_attributes=)
    @testcase.attributes = testcase_params unless @testcase.respond_to?(:safe_attributes=)
    
    @testcase.save_attachments(params[:attachments] || (params[:testcase] && params[:testcase][:uploads]))

    if @testcase.save
      render_attachment_warning_if_needed(@testcase)
      flash[:notice] = l(:notice_test_case_created)
      redirect_to issue_path(@issue, tab: 'testcases')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @testcase.safe_attributes = testcase_params if @testcase.respond_to?(:safe_attributes=)
    @testcase.attributes = testcase_params unless @testcase.respond_to?(:safe_attributes=)
    
    @testcase.save_attachments(params[:attachments] || (params[:testcase] && params[:testcase][:uploads]))

    if @testcase.save
      render_attachment_warning_if_needed(@testcase)
      flash[:notice] = l(:notice_test_case_updated)
      redirect_to issue_path(@issue, tab: 'testcases')
    else
      render :edit, status: :unprocessable_entity
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
    @testcases = @issue.testcases.includes(:attachments, :issue).order(:position)
    @summary = Testcase.summary(@issue.testcases)

    render layout: 'base'
  end

  private

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
    render_404 unless @issue.visible?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_testcase
    @testcase = @issue.testcases.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_view
    render_403 unless User.current.allowed_to?(:view_test_cases, @project)
  end

  def authorize_manage
    render_403 unless User.current.allowed_to?(:manage_test_cases, @project)
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

  def generate_csv(testcases)
    Redmine::Export::CSV.generate(
      encoding: params[:encoding],
      field_separator: params[:field_separator]
    ) do |csv|
      # CSV headers
      csv << [
        l(:field_issue),
        l(:field_subject),
        l(:label_test_case_id),
        l(:label_test_case_title),
        l(:label_test_case_preconditions),
        l(:label_test_case_steps),
        l(:label_test_case_expected),
        l(:label_test_case_actual),
        l(:label_test_case_status),
        l(:label_test_case_comments),
        l(:label_last_updated)
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
        ].map { |value| csv_safe(value) }
      end
    end
  end

  # Prevent spreadsheet formula injection when a cell starts with =, +, - or @.
  def csv_safe(value)
    return value unless value.is_a?(String)

    value.match?(/\A[=+\-@]/) ? "'#{value}" : value
  end

end
