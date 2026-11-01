require 'csv'

class TestcasesController < ApplicationController
  accept_api_auth :index, :show, :create, :update, :destroy, :reorder, :bulk_update

  before_action :find_issue
  before_action :find_testcase, only: [:show, :edit, :update, :destroy]
  before_action :authorize_view, only: [:index, :show, :export_csv, :print_view]
  before_action :authorize_manage, only: [:new, :create, :edit, :update, :destroy, :reorder, :bulk_update]
  before_action :check_tracker_configured

  helper :issues
  helper :testcases
  helper :attachments

  def index
    @testcases = @issue.testcases.includes(:attachments, :issue, :testcase_steps).order(:position)
    @summary = Testcase.summary(@issue.testcases)

    respond_to do |format|
      format.html
      format.json { render json: @testcases.map { |testcase| testcase_json(testcase) } }
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to issue_path(@issue, tab: 'testcases') }
      format.json { render json: testcase_json(@testcase) }
    end
  end

  def new
    @testcase = @issue.testcases.build
    @testcase.status = 'not_executed'
    @testcase.testcase_steps.build if @testcase.testcase_steps.empty?
  end

  def create
    @testcase = @issue.testcases.build
    attrs = testcase_params

    # Safe attributes mapping for plugins usually involves direct assignment in Redmine
    # but we'll manually handle attachments to ensure they bind correctly before save.
    @testcase.safe_attributes = attrs if @testcase.respond_to?(:safe_attributes=)
    @testcase.attributes = attrs unless @testcase.respond_to?(:safe_attributes=)

    @testcase.save_attachments(params[:attachments] || (params[:testcase] && params[:testcase][:uploads]))

    if @testcase.save
      respond_to do |format|
        format.html do
          render_attachment_warning_if_needed(@testcase)
          flash[:notice] = l(:notice_test_case_created)
          redirect_to issue_path(@issue, tab: 'testcases')
        end
        format.json do
          @testcase.attachments.reload
          render json: testcase_json(@testcase), status: :created
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          render json: {errors: @testcase.errors.full_messages}, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
  end

  def update
    attrs = testcase_params
    @testcase.safe_attributes = attrs if @testcase.respond_to?(:safe_attributes=)
    @testcase.attributes = attrs unless @testcase.respond_to?(:safe_attributes=)

    @testcase.save_attachments(params[:attachments] || (params[:testcase] && params[:testcase][:uploads]))

    if @testcase.save
      respond_to do |format|
        format.html do
          render_attachment_warning_if_needed(@testcase)
          flash[:notice] = l(:notice_test_case_updated)
          redirect_to issue_path(@issue, tab: 'testcases')
        end
        format.json do
          @testcase.attachments.reload
          render json: testcase_json(@testcase)
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          render json: {errors: @testcase.errors.full_messages}, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @testcase.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_test_case_deleted)
        redirect_to issue_path(@issue, tab: 'testcases')
      end
      format.json { head :no_content }
    end
  end

  def reorder
    ordered_ids = Array(params[:ordered_ids]).map(&:to_i).reject(&:zero?)
    issue_ids = @issue.testcases.pluck(:id)

    if ordered_ids.empty? ||
       ordered_ids.uniq.size != ordered_ids.size ||
       ordered_ids.sort != issue_ids.sort
      render json: {error: l(:error_invalid_testcase_order)}, status: :unprocessable_entity
      return
    end

    Testcase.transaction do
      ordered_ids.each_with_index do |id, index|
        @issue.testcases.where(id: id).update_all(position: index + 1, updated_at: Time.current)
      end
    end

    respond_to do |format|
      format.html { redirect_to issue_path(@issue, tab: 'testcases') }
      format.any { head :ok }
    end
  end

  def bulk_update
    ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
    status = params[:status].to_s

    unless Testcase.status_values.include?(status)
      respond_to do |format|
        format.html do
          flash[:error] = l(:error_invalid_testcase_status)
          redirect_to issue_path(@issue, tab: 'testcases')
        end
        format.json do
          render json: {error: l(:error_invalid_testcase_status)}, status: :unprocessable_entity
        end
      end
      return
    end

    scope = @issue.testcases.where(id: ids)
    changed = scope.where.not(status: status).to_a
    updated = scope.update_all(status: status, updated_at: Time.current)

    if changed.any?
      note = I18n.t(
        :text_testcases_bulk_status_note,
        test_cases: changed.map(&:test_case_id).join(', '),
        status: I18n.t("testcase_status_#{status}")
      )
      RedmineTestcase.add_note_to_issue(@issue.id, note)
    end

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_test_cases_bulk_updated, count: updated)
        redirect_to issue_path(@issue, tab: 'testcases')
      end
      format.json { render json: {updated: updated} }
    end
  end

  def export_csv
    @testcases = @issue.testcases.includes(:testcase_steps).order(:position)

    csv_data = generate_csv(@testcases)

    send_data csv_data,
              type: 'text/csv; charset=utf-8',
              filename: l(:label_export_filename, issue_id: @issue.id)
  end

  def print_view
    @testcases = @issue.testcases.includes(:attachments, :issue, :testcase_steps).order(:position)
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
    return if RedmineTestcase.enabled_for_issue?(@issue)

    if RedmineTestcase.tracker_configured?
      render_403
    else
      respond_to do |format|
        format.html do
          flash[:error] = l(:text_no_tracker_selected)
          redirect_to issue_path(@issue)
        end
        format.json do
          render json: {error: l(:text_no_tracker_selected)}, status: :forbidden
        end
        format.any { head :forbidden }
      end
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
      :position,
      testcase_steps_attributes: [
        :id,
        :position,
        :action,
        :test_data,
        :expected_result,
        :actual_result,
        :status,
        :_destroy
      ]
    )
  end

  def testcase_json(testcase)
    {
      id: testcase.id,
      issue_id: testcase.issue_id,
      test_case_id: testcase.test_case_id,
      title: testcase.title,
      preconditions: testcase.preconditions,
      steps: testcase.steps,
      expected_result: testcase.expected_result,
      actual_result: testcase.actual_result,
      status: testcase.status,
      comments: testcase.comments,
      position: testcase.position,
      created_on: testcase.created_at,
      updated_on: testcase.updated_at,
      attachments: testcase.attachments.map do |attachment|
        {
          id: attachment.id,
          filename: attachment.filename,
          content_url: download_named_attachment_path(attachment, attachment.filename)
        }
      end,
      testcase_steps: testcase.testcase_steps.map do |step|
        {
          id: step.id,
          position: step.position,
          action: step.action,
          test_data: step.test_data,
          expected_result: step.expected_result,
          actual_result: step.actual_result,
          status: step.status
        }
      end
    }
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
          csv_steps(tc),
          tc.expected_result,
          tc.actual_result,
          tc.status_label,
          tc.comments,
          tc.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        ].map { |value| csv_safe(value) }
      end
    end
  end

  # Free-text steps followed by structured steps, one "1. action | data | expected" line each.
  def csv_steps(testcase)
    structured = testcase.testcase_steps.map.with_index do |step, index|
      values = [step.action, step.test_data, step.expected_result]
               .map { |value| value.to_s.strip }.reject(&:blank?)
      next if values.empty?

      "#{index + 1}. #{values.join(' | ')}"
    end.compact.join("\n")

    [testcase.steps, structured].reject(&:blank?).join("\n")
  end

  # Prevent spreadsheet formula injection when a cell starts with =, +, - or @.
  def csv_safe(value)
    return value unless value.is_a?(String)

    value.match?(/\A[=+\-@]/) ? "'#{value}" : value
  end

end
